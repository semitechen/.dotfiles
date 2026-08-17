"""
DJ Playlists Plugin for Beets
=============================
Handles intelligent merging of custom playlist tags during imports, 
even when duplicate tracks are encountered and skipped. 
Optionally generates M3U playlists automatically or manually.
"""

import os
from beets.plugins import BeetsPlugin
from beets import config
from beets.dbcore import query
from beets.ui import Subcommand

class DJPlaylistsPlugin(BeetsPlugin):
    def __init__(self):
        super().__init__()
        # Listeners
        self.register_listener('import_task_choice', self.on_import_task_choice)
        self.register_listener('cli_exit', self._on_cli_exit)
        
        # Professional, sane defaults
        self.config.add({
            'playlist_dir': '~/Music/dj/playlists',
            'relative_to': '~/Music/dj/playlists',
            'extm3u': True,
            'auto': False,  # Default to NOT running generation on every exit
            'playlists': []
        })

    def commands(self):
        """Registers the custom 'beet djplaylists' CLI command."""
        cmd = Subcommand('djplaylists', help='Manually generate configured DJ playlists (M3U)')
        
        def func(lib, opts, args):
            self.generate_playlists(lib)
            
        cmd.func = func
        return [cmd]

    def _on_cli_exit(self, lib):
        """Hook for cli_exit. Only generates playlists if auto is true."""
        if self.config['auto'].get(bool):
            self.generate_playlists(lib)

    def on_import_task_choice(self, session, task):
        """
        Intercepts the import choice phase to ensure that if a user passed 
        a `--set playlist=...` flag, it gets merged into the existing database 
        item before Beets drops the duplicate track.
        """
        # 1. Safely extract the `--set` tag from the global Beets config
        new_tag = None
        try:
            set_fields = config['import']['set_fields'].get(dict)
            new_tag = set_fields.get('playlist')
        except Exception as e:
            self._log.debug("No global set_fields found: {0}", e)

        # Fallback to the item itself (e.g., if set by another plugin)
        if not new_tag and getattr(task, 'item', None):
            new_tag = task.item.get('playlist')

        if not new_tag:
            return

        # 2. Extract the exact metadata Beets used for the match
        target_tracks = self._extract_target_tracks(task)
        if not target_tracks:
            return

        # 3. Search DB for duplicates and merge tags
        for t_artist, t_title in target_tracks:
            if not t_title:
                continue
            
            # Query the database by title
            q = query.SubstringQuery('title', t_title)
            
            for db_item in session.lib.items(q):
                # Verify artist match (case-insensitive, partial match safe)
                if t_artist.lower() in db_item.artist.lower() or db_item.artist.lower() in t_artist.lower():
                    self._merge_and_save_tags(db_item, new_tag)

    def _extract_target_tracks(self, task):
        """Safely extracts target (Artist, Title) tuples from the import task."""
        tracks = []
        if getattr(task, 'match', None):
            if hasattr(task.match.info, 'tracks'):
                for t_info in task.match.info.tracks:
                    artist = getattr(t_info, 'artist', None) or getattr(task.match.info, 'artist', '')
                    tracks.append((artist, t_info.title))
            else:
                tracks.append((task.match.info.artist, task.match.info.title))
        else:
            if getattr(task, 'item', None):
                tracks.append((task.item.artist, task.item.title))
        return tracks

    def _merge_and_save_tags(self, db_item, new_tag):
        """Merges a semicolon-separated tag into the database item safely."""
        existing_tags = db_item.get('playlist', '')
        
        old_list = [p.strip() for p in existing_tags.split(';') if p.strip()]
        new_list = [p.strip() for p in new_tag.split(';') if p.strip()]
        
        # Deduplicate while preserving order
        merged = list(dict.fromkeys(old_list + new_list))
        merged_str = ';'.join(merged)

        # Only touch the DB and files if the tags actually changed
        if existing_tags != merged_str:
            db_item['playlist'] = merged_str
            db_item.store()
            
            try:
                db_item.try_write()
                self._log.info("Merged playlist tag for '{0}': [{1}]", db_item.title, merged_str)
            except Exception as e:
                self._log.warning("Updated DB but failed to write ID3 tag for '{0}': {1}", db_item.title, e)

    def generate_playlists(self, lib):
        """Reads config and generates M3U files."""
        playlist_dir = self.config['playlist_dir'].as_filename()
        relative_to = self.config['relative_to'].as_filename() if self.config['relative_to'].get() else playlist_dir
        extm3u = self.config['extm3u'].get(bool)
        playlists_config = self.config['playlists'].get(list)

        if not os.path.exists(playlist_dir):
            try:
                os.makedirs(playlist_dir)
            except OSError as e:
                self._log.error("Failed to create playlist directory: {0}", e)
                return

        self._log.info("Generating DJ playlists...")

        for pl_def in playlists_config:
            name_template = pl_def.get('name')
            q_str = pl_def.get('query', '')
            items = lib.items(q_str)

            if '$playlist' in name_template:
                self._generate_dynamic_playlists(items, name_template, playlist_dir, relative_to, extm3u)
            else:
                self._write_m3u(name_template, items, playlist_dir, relative_to, extm3u)
                
        self._log.info("DJ playlists successfully updated.")

    def _generate_dynamic_playlists(self, items, name_template, playlist_dir, relative_to, extm3u):
        """Generates multiple playlists dynamically based on the $playlist tag."""
        playlist_map = {}
        for item in items:
            tags = item.get('playlist', '')
            if not tags:
                continue
            
            for tag in [t.strip() for t in tags.split(';') if t.strip()]:
                if tag not in playlist_map:
                    playlist_map[tag] = []
                playlist_map[tag].append(item)
        
        for tag, tag_items in playlist_map.items():
            # Sanitize tag to prevent path injection
            safe_tag = tag.replace('/', '_').replace('\\', '_')
            filename = name_template.replace('$playlist', safe_tag)
            self._write_m3u(filename, tag_items, playlist_dir, relative_to, extm3u)

    def _write_m3u(self, filename, items, playlist_dir, relative_to, extm3u):
        """Helper function to safely write an M3U file."""
        if not items:
            return
            
        m3u_path = os.path.join(playlist_dir, filename)
        try:
            with open(m3u_path, 'w', encoding='utf-8') as f:
                if extm3u:
                    f.write("#EXTM3U\n")
                for item in items:
                    try:
                        rel_path = os.path.relpath(item.path.decode('utf-8'), relative_to)
                    except ValueError:
                        rel_path = item.path.decode('utf-8')
                    f.write(f"{rel_path}\n")
        except OSError as e:
            self._log.error("Could not write playlist {0}: {1}", filename, e)
import discogs_client
import re
import time
from beets.plugins import BeetsPlugin
from beets import ui

class DiscogsGenrePlugin(BeetsPlugin):
    """A professional Discogs Style enrichment plugin for Beets 2.x.
    Designed for DJ workflows, merging Last.fm fallbacks with Discogs Styles.
    """

    def __init__(self):
        super(DiscogsGenrePlugin, self).__init__()

        # Professional Defaults: Write is DISABLED by default.
        self.config.add({
            'auto': True,
            'token': '',
            'count': 0,           # 0 = Fetch all available styles
            'delay': 1.2,
            'write': False,       # Default: Do not modify physical files
            'separator': ', ',    # Separator for DJ-friendly strings
            'user_agent': 'beets-discogsgenre/1.2',
        })

        if self.config['auto']:
            self.register_listener('item_imported', self.on_item_imported)
            self.register_listener('album_imported', self.on_album_imported)

    def commands(self):
        """Register the 'beet discogsgenre' CLI command."""
        cmd = ui.Subcommand('discogsgenre', help='Enrich metadata with Discogs Styles')
        cmd.func = self._manual_command
        return [cmd]

    def _manual_command(self, lib, opts, args):
        for item in lib.items(ui.decargs(args)):
            self.process_item(item)

    def on_item_imported(self, lib, item):
        self.process_item(item)

    def on_album_imported(self, lib, album):
        for item in album.items():
            self.process_item(item)

    def process_item(self, item):
        """Enriches a single item's genre by merging existing tags with Discogs Styles."""
        token = self.config['token'].get()
        if not token:
            self._log.error('Discogs token missing. Please add it to your config.yaml.')
            return

        client = discogs_client.Client(self.config['user_agent'].as_str(), user_token=token)

        # 1. Clean Search Query
        # Strips secondary artists and DJ-specific suffixes to maximize hit rate.
        artist = re.split(r'[,/]', (item.get('artist') or ''))[0].strip()
        title = re.sub(
            r'(- )?(original mix|mix cut|extended mix|remix|edit|feat.*| - .*)', 
            '', (item.get('title') or ''), flags=re.IGNORECASE
        ).strip()

        try:
            # Throttle requests to respect Discogs rate limits
            time.sleep(self.config['delay'].get(float))
            
            results = client.search(artist=artist, track=title, type='release')
            
            if results and results.count > 0:
                release = results[0]
                styles = getattr(release, 'styles', None) or getattr(release, 'genres', None) or []
                
                if styles:
                    max_count = self.config['count'].get(int)
                    new_styles = styles if max_count == 0 else styles[:max_count]
                    
                    # 2. Deduplicated Merge
                    # Preserves existing genre (e.g., from Last.fm) and appends unique Discogs styles.
                    sep = self.config['separator'].as_str()
                    existing_genre_str = item.get('genre') or ''
                    merged_list = [g.strip() for g in existing_genre_str.split(sep.strip()) if g.strip()]
                    
                    for s in new_styles:
                        if s.lower() not in [m.lower() for m in merged_list]:
                            merged_list.append(s)

                    final_genre = sep.join(merged_list)

                    # 3. Apply to Beets 2.x
                    # We store as a list containing one single string to bypass array-tagging issues.
                    item.genre = final_genre
                    item.genres = [final_genre]
                    
                    item.store()

                    # 4. Conditional Write
                    if self.config['write'].get(bool):
                        item.write()
                        self._log.info('{0} - {1} -> {2} (Written to file)', item.artist, item.title, final_genre)
                    else:
                        self._log.info('{0} - {1} -> {2} (Library only)', item.artist, item.title, final_genre)
                else:
                    self._log.debug('No styles found for {0}.', item.title)
            else:
                self._log.debug('No match found for {0} - {1}.', artist, title)

        except Exception as e:
            self._log.error('API Error for {0}: {1}', item.title, e)

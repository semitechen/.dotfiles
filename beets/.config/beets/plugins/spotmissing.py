from beets.plugins import BeetsPlugin
from beets.ui import Subcommand, UserError, decargs
from beets.dbcore.query import SubstringQuery, AndQuery
from beets import config
import spotipy
from spotipy.oauth2 import SpotifyOAuth
import os
import re

class SpotMissingPlugin(BeetsPlugin):
    def __init__(self):
        super().__init__()

    def commands(self):
        cmd = Subcommand('spotmissing', help='Find tracks missing from a Spotify playlist')
        cmd.parser.usage += " <playlist_url>"
        cmd.func = self.run
        return [cmd]

    def clean_spotify_title(self, title):
        # Strip common Spotify suffixes like " - Original Mix", " (Radio Edit)", " - Remastered"
        # Case insensitive regex
        clean = re.sub(r'(?i)\s*[-]\s*(original|radio|extended|club|vip|remix|remaster|remastered|edit|mix).*$', '', title)
        clean = re.sub(r'(?i)\s*\((original|radio|extended|club|vip|remix|remaster|remastered|edit|mix).*?\)', '', clean)
        return clean.strip()

    def run(self, lib, opts, args):
        args = decargs(args)
        
        if not args:
            raise UserError('Please provide a Spotify playlist URL or URI.')

        playlist_url = args[0]

        try:
            client_id = config['spotify']['client_id'].get()
            client_secret = config['spotify']['client_secret'].get()
        except config.NotFoundError:
            raise UserError("Spotify 'client_id' and 'client_secret' not found in config.")

        self._log.info("Connecting to Spotify...")
        cache_path = os.path.expanduser('~/.config/beets/.spotmissing-token')

        sp = spotipy.Spotify(auth_manager=SpotifyOAuth(
            client_id=client_id,
            client_secret=client_secret,
            redirect_uri="http://127.0.0.1:8000/callback",
            scope="playlist-read-private playlist-read-collaborative",
            cache_path=cache_path
        ))

        try:
            results = sp.playlist_tracks(playlist_url)
        except Exception as e:
            raise UserError(f"Error fetching playlist: {e}")

        tracks = results['items']
        while results['next']:
            results = sp.next(results)
            tracks.extend(results['items'])

        self._log.info(f"Checking {len(tracks)} tracks against local database...")
        
        missing_tracks = []
        found_count = 0

        for i, pl_item in enumerate(tracks):
            track_obj = None
            
            if 'track' in pl_item and pl_item['track'] is not None:
                track_obj = pl_item['track']
            elif 'item' in pl_item and pl_item['item'] is not None:
                track_obj = pl_item['item']
            elif 'name' in pl_item and 'artists' in pl_item:
                track_obj = pl_item
                
            if not track_obj:
                continue
                
            raw_title = track_obj.get('name')
            artists = track_obj.get('artists')
            
            if not raw_title or not artists:
                continue
                
            primary_artist = artists[0].get('name', 'Unknown Artist')
            
            # Clean the title using the new function
            search_title = self.clean_spotify_title(raw_title)
            
            query = AndQuery([
                SubstringQuery('artist', primary_artist),
                SubstringQuery('title', search_title)
            ])
            
            matches = list(lib.items(query))
            
            if matches:
                found_count += 1
            else:
                missing_tracks.append(f"{primary_artist} - {raw_title}")

        print("\n" + "="*50)
        print(f"RESULTS: {found_count} tracks found locally, {len(missing_tracks)} missing.")
        print("="*50)
        
        if missing_tracks:
            print("\nMissing Tracks:")
            for t in missing_tracks:
                print(f" ❌ {t}")
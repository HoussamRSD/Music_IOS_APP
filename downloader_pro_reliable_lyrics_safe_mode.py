#!/usr/bin/env python3
import subprocess
import os
import glob
import sys
import time
import json
import urllib.request
import urllib.parse
import re
import requests
import shutil
from mutagen.mp4 import MP4, MP4Cover
from mutagen.id3 import ID3, TIT2, TPE1, TPE2, TALB, APIC, USLT, ID3NoHeaderError
from mutagen.mp3 import MP3
from ytmusicapi import YTMusic

# --- CONFIGURATION ---
SOURCE_DIR = os.path.expanduser("~/Documents/Music/Downloads")
UNKNOWN_FOLDER = os.path.join(SOURCE_DIR, "Unknown")
ARCHIVE_FILE = os.path.join(SOURCE_DIR, "yt-dlp-archive.txt")

os.makedirs(SOURCE_DIR, exist_ok=True)
if not os.path.exists(ARCHIVE_FILE):
    open(ARCHIVE_FILE, "w").close()

# Initialize YTMusic
try:
    yt = YTMusic()
except:
    yt = None
    # print("⚠️ Warning: ytmusicapi not installed.")

# ==============================================================================
# 1. HELPERS
# ==============================================================================

def clean_query_for_search(filename):
    name = re.sub(r'\.(mp3|m4a)$', '', filename, flags=re.IGNORECASE)
    parts = name.split(" - ")
    if len(parts) >= 2 and parts[0].lower() == parts[1].lower():
        name = " - ".join(parts[1:]) 
    name = re.sub(r'\b202[0-9]\b', '', name)
    garbage = [
        r'\(?official\s*(video|audio|music\s*video|lyric\s*video)?\)?',
        r'\[?official\s*(video|audio|music\s*video|lyric\s*video)?\]?',
        r'\(?lyrics?\)?', r'\[?lyrics?\]?',
        r'\(?hq\)?', r'\[?hq\]?',
        r'remix', 
    ]
    for g in garbage:
        name = re.sub(g, '', name, flags=re.IGNORECASE)
    name = name.replace("_", " ").strip()
    return re.sub(r'\s+', ' ', name)

def fix_high_res_url(url):
    if not url: return None
    if "googleusercontent" in url or "ggpht" in url:
        return re.sub(r'=w\d+-h\d+.*', '=w1200-h1200', url)
    return url

# ==============================================================================
# 2. LYRICS
# ==============================================================================

def fetch_lyrics_lrclib(artist, title, duration_file=None):
    try:
        params = {"artist_name": artist, "track_name": title}
        url = "https://lrclib.net/api/search?" + urllib.parse.urlencode(params)
        data = requests.get(url, timeout=5).json()
        if data and isinstance(data, list) and len(data) > 0:
            for song in data:
                if duration_file:
                    duration_lyric = song.get("duration", 0)
                    if abs(duration_lyric - duration_file) > 20: continue 
                return song.get("syncedLyrics") or song.get("plainLyrics")
    except: pass
    return None

def fetch_lyrics_ytmusic(clean_query):
    if not yt: return None
    try:
        results = yt.search(clean_query, filter="songs")
        if not results: return None
        video_id = results[0]['videoId']
        watch = yt.get_watch_playlist(videoId=video_id)
        lyrics_id = watch.get('lyrics')
        if not lyrics_id: return None
        lyrics_data = yt.get_lyrics(browseId=lyrics_id)
        return lyrics_data.get('lyrics')
    except: pass
    return None

def get_best_lyrics(artist, title, duration_file):
    lyrics = fetch_lyrics_lrclib(artist, title, duration_file)
    if lyrics: return lyrics
    query = f"{artist} {title}"
    lyrics = fetch_lyrics_ytmusic(query)
    if lyrics: return lyrics
    return None

# ==============================================================================
# 3. IDENTIFICATION
# ==============================================================================

def search_itunes(clean_query):
    try:
        params = {"term": clean_query, "media": "music", "entity": "song", "limit": 1}
        data = requests.get("https://itunes.apple.com/search?" + urllib.parse.urlencode(params), timeout=5).json()
        if data["resultCount"] > 0:
            track = data["results"][0]
            return {
                "source": "iTunes",
                "title": track["trackName"],
                "artist": track["artistName"],
                "album": track["collectionName"],
                "artwork_url": track["artworkUrl100"].replace("100x100", "1400x1400"),
                "genre": track.get("primaryGenreName", "Unknown")
            }
    except: pass
    return None

def search_deezer(clean_query):
    try:
        params = {"q": clean_query, "limit": 1}
        data = requests.get("https://api.deezer.com/search?" + urllib.parse.urlencode(params), timeout=5).json()
        if "data" in data and len(data["data"]) > 0:
            track = data["data"][0]
            return {
                "source": "Deezer",
                "title": track["title"],
                "artist": track["artist"]["name"],
                "album": track["album"]["title"],
                "artwork_url": track["album"].get("cover_xl", ""),
                "genre": "Unknown" 
            }
    except: pass
    return None

def search_ytmusic(clean_query):
    if not yt: return None
    try:
        results = yt.search(clean_query, filter="songs")
        if results:
            track = results[0]
            cover_url = fix_high_res_url(track['thumbnails'][-1]['url']) if track['thumbnails'] else None
            return {
                "source": "YTMusic",
                "title": track['title'],
                "artist": track['artists'][0]['name'],
                "album": track.get('album', {}).get('name', 'Single'),
                "artwork_url": cover_url,
                "genre": "Raï/World"
            }
    except: pass
    return None

def identify_song(filename):
    query = clean_query_for_search(filename)
    
    # Priority: YTMusic -> Deezer -> iTunes
    meta = search_ytmusic(query)
    if meta: return meta
    
    meta = search_deezer(query)
    if meta: return meta
    
    meta = search_itunes(query)
    if meta: return meta
    
    return None

def update_file_tags(filepath, metadata):
    title = metadata['title']
    artist = metadata['artist']
    album = metadata['album']
    
    ext = os.path.splitext(filepath)[1].lower()
    duration = 0
    if ext == ".m4a":
        try: duration = MP4(filepath).info.length
        except: pass
    elif ext == ".mp3":
        try: duration = MP3(filepath).info.length
        except: pass

    lyrics = get_best_lyrics(artist, title, duration)
    
    cover_data = None
    if metadata['artwork_url']:
        try:
            r = requests.get(metadata['artwork_url'], timeout=10)
            if r.status_code == 200: cover_data = r.content
        except: pass
    
    if ext == ".m4a":
        try: audio = MP4(filepath)
        except: audio = MP4(filepath)
        audio["\xa9nam"] = title
        audio["\xa9ART"] = artist
        audio["aART"] = artist
        audio["\xa9alb"] = album
        audio["\xa9gen"] = metadata['genre']
        if lyrics: audio["\xa9lyr"] = lyrics
        if cover_data: audio["covr"] = [MP4Cover(cover_data, imageformat=MP4Cover.FORMAT_JPEG)]
        audio.save()
    elif ext == ".mp3":
        try: audio = MP3(filepath, ID3=ID3)
        except ID3NoHeaderError: audio = MP3(filepath); audio.add_tags()
        audio.tags.add(TIT2(encoding=3, text=title))
        audio.tags.add(TPE1(encoding=3, text=artist))
        audio.tags.add(TALB(encoding=3, text=album))
        if lyrics: audio.tags.add(USLT(encoding=3, lang='eng', desc='desc', text=lyrics))
        if cover_data: audio.tags.add(APIC(encoding=3, mime='image/jpeg', type=3, desc='Cover', data=cover_data))
        audio.save()
    
    return title, artist

# ==============================================================================
# 4. PROCESSING LOGIC
# ==============================================================================

def generate_filename(title, artist_str):
    clean = lambda s: "".join(c for c in s if c not in "/\\:*?\"<>|").strip()
    raw_artists = re.split(r'\s*[,&]\s*|\s+feat\.?\s+', artist_str, flags=re.IGNORECASE)
    artists = [a.strip() for a in raw_artists if a.strip()]
    main_artist = artists[0]
    feats = artists[1:3]
    base_name = f"{main_artist} - {title}"
    if feats: base_name += f" (feat. {' - '.join(feats)})"
    return clean(base_name)

def process_smart_organization(files, skip_identify=False):
    print("\n" + "="*60)
    print("🧠 Starting Organization...")
    
    for filepath in files:
        if not os.path.exists(filepath): continue
        filename = os.path.basename(filepath)
        print(f"\n🎵 Processing: {filename}")
        
        # --- SAFE MODE CHECK ---
        if skip_identify:
            print("   🛡️  Safe Mode: Skipping identification (preserving original).")
            # In Safe Mode, we assume the file already has the basic tags from yt-dlp
            # We just leave it alone or maybe move it out of Downloads if needed.
            continue 

        metadata = identify_song(filename)
        if not metadata:
            print("   ❌ Unrecognized. Moving to Unknown.")
            os.makedirs(UNKNOWN_FOLDER, exist_ok=True)
            if UNKNOWN_FOLDER not in filepath:
                try: shutil.move(filepath, os.path.join(UNKNOWN_FOLDER, filename))
                except: pass
            continue
            
        print(f"   💡 Identified via {metadata['source']}: {metadata['artist']} - {metadata['title']}")
        try:
            clean_title, clean_artist = update_file_tags(filepath, metadata)
            new_name = generate_filename(clean_title, clean_artist)
            ext = os.path.splitext(filepath)[1]
            new_filename = f"{new_name}{ext}"
            new_path = os.path.join(SOURCE_DIR, new_filename)
            if filepath != new_path:
                os.rename(filepath, new_path)
                print(f"   ✏️  Renamed to: {new_filename}")
            else:
                print("   ✅ Name is correct.")
        except Exception as e:
            print(f"   ⚠️ Error: {e}")

# ==============================================================================
# 5. DOWNLOADER
# ==============================================================================

def parse_progress(line):
    m = re.search(r'(\d+\.\d+)%\s+of\s+([0-9.]+[KMGiB]+)\s+at\s+([0-9.]+[KMGiB]+/s)', line)
    if not m: return None
    return float(m.group(1)), m.group(2), m.group(3)

def download_songs(url):
    print("="*60)
    print(f"🔗 URL: {url}")
    print("⏳ Starting download...\n")
    before = set(glob.glob(os.path.join(SOURCE_DIR, "*.m4a")))
    
    ydl_cmd = [
        "yt-dlp", "-f", "bestaudio[ext=m4a]/bestaudio", "--extract-audio", "--audio-format", "m4a",
        "--audio-quality", "0", "--embed-thumbnail", "--embed-metadata",
        "--download-archive", ARCHIVE_FILE, "-o", f"{SOURCE_DIR}/%(title)s.%(ext)s",
        "--newline", url
    ]
    
    process = subprocess.Popen(ydl_cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
    for line in process.stdout:
        line = line.strip()
        if "[download]" in line and "%" in line:
            prog = parse_progress(line)
            if prog: print(f"\r⬇️ {prog[0]:4.1f}% • {prog[1]} • {prog[2]}   ", end="")
        elif "Destination:" in line:
            print(f"\n📥 {os.path.basename(line.split('Destination:',1)[1].strip())}")
    
    process.wait()
    print()
    
    if process.returncode != 0: return False, []
    after = set(glob.glob(os.path.join(SOURCE_DIR, "*.m4a")))
    new_files = sorted(list(after - before))
    print(f"\n✅ Downloaded {len(new_files)} new files.")
    return True, new_files

# ==============================================================================
# MAIN
# ==============================================================================
if len(sys.argv) < 2:
    print("Usage: python3 script.py <url> [--no-identify] | --lyrics-only")
    sys.exit(1)

arg1 = sys.argv[1]

# Check for Safe Mode flag
skip_identify = False
if len(sys.argv) > 2 and sys.argv[2] == "--no-identify":
    skip_identify = True

if arg1 == "--lyrics-only":
    files = glob.glob(os.path.join(SOURCE_DIR, "*.m4a"))
    process_smart_organization(files, skip_identify=False)
else:
    url = arg1
    success, new_files = download_songs(url)
    if success and new_files:
        # Pass the flag to the organizer
        process_smart_organization(new_files, skip_identify=skip_identify)

print("\n🎉 ALL DONE!")

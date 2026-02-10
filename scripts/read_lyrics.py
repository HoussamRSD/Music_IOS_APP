import sys
import os
try:
    from mutagen.mp4 import MP4
    from mutagen.id3 import ID3
    from mutagen.mp3 import MP3
except ImportError:
    print("Error: mutagen not installed")
    sys.exit(1)

def read_lyrics(filepath):
    if not os.path.exists(filepath):
        return None
    
    ext = os.path.splitext(filepath)[1].lower()
    lyrics = None
    
    try:
        if ext == ".m4a":
            audio = MP4(filepath)
            # Try standard lyrics tag
            if "\xa9lyr" in audio:
                lyrics = audio["\xa9lyr"][0]
            elif "lyr" in audio: # specialized tag
                lyrics = audio["lyr"][0]
                
        elif ext == ".mp3":
            audio = MP3(filepath, ID3=ID3)
            # 1. Try USLT (Unsynchronized lyrics)
            for key in audio.tags.keys():
                if key.startswith("USLT"):
                    lyrics = audio.tags[key].text
                    # Prefer non-empty lyrics
                    if lyrics and len(lyrics.strip()) > 0:
                         break
            
            # 2. If no USLT, try SYLT (Synchronized lyrics)
            if not lyrics:
                for key in audio.tags.keys():
                    if key.startswith("SYLT"):
                        # SYLT text is a list of tuples (text, time)
                        # We extract just the text for now or raw representation
                        # But typically for display we might want raw LRC if possible
                        # mutagen SYLT is complex, let's just see if we can get text
                        try:
                           parts = [x.text for x in audio.tags[key].text]
                           lyrics = "\n".join(parts)
                        except: pass
                        if lyrics: break

            # 3. If still nothing, try TXXX:Lyrics
            if not lyrics:
                for key in audio.tags.keys():
                    if key.startswith("TXXX") and "lyric" in key.lower():
                         lyrics = audio.tags[key].text[0]
                         if lyrics: break

    except Exception as e:
        print(f"Error reading {filepath}: {e}", file=sys.stderr)
        pass
        
    return lyrics

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
        
    filepath = sys.argv[1]
    lyrics = read_lyrics(filepath)
    
    if lyrics:
        # Print lyrics to stdout (UTF-8)
        sys.stdout.buffer.write(lyrics.encode('utf-8'))
    else:
        pass

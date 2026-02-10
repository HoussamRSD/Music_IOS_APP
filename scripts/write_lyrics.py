import sys
import os
try:
    from mutagen.mp4 import MP4, MP4Cover
    from mutagen.id3 import ID3, USLT, SYLT, ID3NoHeaderError, Encoding
    from mutagen.mp3 import MP3
except ImportError:
    print("Error: mutagen not installed", file=sys.stderr)
    sys.exit(1)

def write_lyrics(filepath, lyrics, is_synced=False):
    if not os.path.exists(filepath):
        print(f"Error: File not found: {filepath}", file=sys.stderr)
        return False
    
    ext = os.path.splitext(filepath)[1].lower()
    
    try:
        if ext == ".m4a":
            try:
                audio = MP4(filepath)
            except:
                audio = MP4(filepath) # Retry
            
            # Write to standard lyrics tag
            audio["\xa9lyr"] = lyrics
            audio.save()
            return True
            
        elif ext == ".mp3":
            try:
                audio = MP3(filepath, ID3=ID3)
            except ID3NoHeaderError:
                audio = MP3(filepath)
                audio.add_tags()
            
            # Remove existing USLT tags to avoid duplicates
            to_remove = [key for key in audio.tags.keys() if key.startswith("USLT")]
            for key in to_remove:
                del audio.tags[key]
            
            # Write new USLT tag
            audio.tags.add(USLT(encoding=Encoding.UTF8, lang='eng', desc='desc', text=lyrics))
            audio.save()
            return True
            
    except Exception as e:
        print(f"Error writing to {filepath}: {e}", file=sys.stderr)
        return False
        
    return False

if __name__ == "__main__":
    # Usage: python write_lyrics.py <filepath> <lyrics_text>
    if len(sys.argv) < 3:
        print("Usage: python write_lyrics.py <filepath> <lyrics_text>", file=sys.stderr)
        sys.exit(1)
        
    filepath = sys.argv[1]
    # Lyrics can be multi-line, passed as a single argument
    lyrics = sys.argv[2]
    
    success = write_lyrics(filepath, lyrics)
    
    if success:
        print("Success")
        sys.exit(0)
    else:
        sys.exit(1)

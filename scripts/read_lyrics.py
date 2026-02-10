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
        elif ext == ".mp3":
            audio = MP3(filepath, ID3=ID3)
            # Try all USLT tags
            for key in audio.tags.keys():
                if key.startswith("USLT"):
                    lyrics = audio.tags[key].text
                    break
    except Exception as e:
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

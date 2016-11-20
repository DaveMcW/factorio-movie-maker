# Factorio Movie Maker

This project encodes a 178x100 3-bit color movie in a [Factorio](http://www.factorio.com) map.

1. Install [FFmpeg](http://www.ffmpeg.org/download.html) and [Lua](http://lua-users.org/wiki/LuaBinaries) if you don't already have them.

2. Obtain a source picture or video.  It must have a 16:9 aspect ratio or it will be stretched.  In this example it is called source.mp4.

3.
        cd factorio-movie-maker
        ffmpeg -i source.mp4 -i palette.bmp -filter_complex "fps=20,scale=178:100:flags=lanczos,paletteuse" -pix_fmt bgr24 images/%04d.bmp
        lua build.lua

5. Start Factorio and load movie.zip.

6. Open each file in the scripts directory, select all, and copy/paste it into the Factorio console.

7. Open the constant combinator at position {-183,-1}.  Change the red signal to the frame count of your movie.


:: Запись в avi c Xvid/mp3 (lame -v6)

ffmpeg -hide_banner -f gdigrab -offset_x %1 -offset_y %2 -video_size %3 -i desktop %~5%6 -vf scale=%4:flags=lanczos -c:v mpeg4 -vtag xvid -q:v 4 -pix_fmt yuv420p -c:a libmp3lame -q:a 6 %7[%4]%9.avi

:: Качественное сжатие для сравнительно мощного компа

ffmpeg  -hide_banner -f gdigrab -offset_x %1 -offset_y %2 -video_size %3 -i desktop %~5%6 -vf scale=%4:flags=bicublin -c:v libx264 -crf 20 -preset slower -pix_fmt yuv420p -c:a aac -ac 2 -b:a 160k 	%7[%4]%9.mp4
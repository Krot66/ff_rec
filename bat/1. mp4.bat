:: «апись рабочего стола дл€ обычных нужд с низкой нагрузкой на процессор

ffmpeg -hide_banner -f gdigrab -offset_x %1 -offset_y %2 -video_size %3 -i desktop %~5%6 -vf scale=%4:flags=lanczos -c:v libx264 -crf 23 -pix_fmt yuv420p -preset ultrafast %7[%4]%9.mp4

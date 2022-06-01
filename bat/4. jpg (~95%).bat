:: Скриншот в jpg-файл примерно 95% качества

ffmpeg -hide_banner -f gdigrab -draw_mouse 0 -offset_x %1 -offset_y %2 -video_size %3 -i desktop -vf scale=%4:flags=sinc -frames:v 1 -q:v 1 %7[%4]%9.jpg
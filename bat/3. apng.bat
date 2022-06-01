:: Захват в apng-анимацию

ffmpeg -hide_banner -f gdigrab -framerate 15 -offset_x %1 -offset_y %2 -video_size %3 -i desktop -vf scale=%4:flags=sinc -pix_fmt rgba -f apng %7[%4]%9.apng


:: Плотная, качественная запись в VP9/opus со сравнительно высокой нагрузкой на процессор

ffmpeg -hide_banner -f gdigrab -offset_x %1 -offset_y %2 -video_size %3 -i desktop %~5%6 -vf scale=%4:flags=lanczos -c:v libvpx-vp9 -crf 30 -b:v 0 -pix_fmt yuv420p %7[%4]%9.webm

:: Захват в webp-анимацию. При большом разрешении значительная нагрузка на компьютер

ffmpeg -hide_banner -f gdigrab -framerate 20 -offset_x %1 -offset_y %2 -video_size %3 -i desktop -vf scale=%4:flags=lanczos -pix_fmt yuv420p -q:v 100 -compression_level 6 -loop 0 %7[%4]%9.webp

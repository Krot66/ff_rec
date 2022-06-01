:: Скриншот в беспотерьный webp

ffmpeg -hide_banner -f gdigrab -draw_mouse 0 -offset_x %1 -offset_y %2 -video_size %3 -i desktop -vf scale=%4:flags=sinc -frames:v 1 -c:v libwebp  -lossless 1 %7[%4]%9.webp

; Статический gif, качественный и компактный, без характерной ряби на однотонных местах, не попадающих в 256-цветную палитру

ffmpeg -hide_banner -f gdigrab -draw_mouse 0 -offset_x %1 -offset_y %2 -video_size %3 -i desktop -vf scale=%4:flags=lanczos -frames:v 1 %7.bmp

ffmpeg -hide_banner -i %7.bmp -filter_complex "split [a][b];[a] palettegen [p];[b][p] paletteuse" %7[%4]%9.png

:: Скриншот в компактный png с палитрой цветов (как в FastStone Capture и некоторых других) и сравнительно большим временем обработки. Размер меньше от 2-3 раз в случае обычных картинок до 10 и более в случае изображений с ограниченной палитрой цветов

ffmpeg -hide_banner -f gdigrab -draw_mouse 0 -offset_x %1 -offset_y %2 -video_size %3 -i desktop -vf scale=%4:flags=sinc -frames:v 1 %7.bmp

ffmpeg -hide_banner -i %7.bmp -filter_complex "split [a][b];[a] palettegen [p];[b][p] paletteuse" %7[%4]%9.png


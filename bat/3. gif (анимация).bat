:: «ахват в видео с последующим преобразованием в качественный и компактный gif с общей цветовой палитрой дл€ всех кадров. –азмер выходного файла может быть уменьшен сокращением числа цветов палитры (например, palettegen=16), если это позвол€ет изображение

ffmpeg -hide_banner -f gdigrab -framerate 15 -offset_x %1 -offset_y %2 -video_size %3 -i desktop -vf scale=%4:flags=lanczos -c:v libx264 -crf 23 -preset ultrafast %7.mp4

ffmpeg -hide_banner -i %7.mp4 -filter_complex "[0:v] split [a][b];[a] palettegen=256 [p];[b][p] paletteuse" %7[%4]%9.gif


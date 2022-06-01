:: Захват в видео с последующим преобразованием в gif с цветовой палитрой для каждого кадра. Размер примерно в два раза больше основного варианта - оправдано для захвата сложных в цветовом отношении случаев. Файлы могут некорректно отображаться в некоторых вьюверах, но без проблем - на веб-страницах

ffmpeg -hide_banner -f gdigrab -framerate 15 -offset_x %1 -offset_y %2 -video_size %3 -i desktop -vf scale=%4:flags=sinc -c:v libx264 -crf 23 -preset ultrafast %7.mp4

ffmpeg -hide_banner -i %7.mp4 -filter_complex "[0:v] split [a][b];[a] palettegen=stats_mode=single [p];[b][p] paletteuse=new=1:dither=floyd_steinberg" %7[%4]%9.gif




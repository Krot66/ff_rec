:: Двухпроходное высококачественное сжатие. Первыый проход lossless и требует сравнительно много места

ffmpeg -hide_banner -rtbufsize 100M -f gdigrab -offset_x %1 -offset_y %2 -video_size %3 -i desktop %~5%6 -vf scale=%4:flags=sinc -c:v libx264 -qp 0 -pix_fmt yuv420p -preset ultrafast -c:a aac -ac 2 -b:a 192k _%7.mp4

ffmpeg -hide_banner -i _%7.mp4 -c:v libx264 -crf 18 -preset slower -c:a copy %7[%4]%9.mp4

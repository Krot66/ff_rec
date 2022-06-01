:: Запись аудио в m4a

ffmpeg -hide_banner %~5%6 -c:a aac -ac 2 -b:a 160k %7.m4a

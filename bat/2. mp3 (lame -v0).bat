:: Запись аудио в mp3 (lame - пресет -v0)

ffmpeg -hide_banner %~5%6 -c:a libmp3lame -q:a 0 %7.mp3

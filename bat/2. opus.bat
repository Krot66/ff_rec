:: Запись аудио в opus

ffmpeg -hide_banner %~5%6 -c:a libopus -vbr on %7.opus

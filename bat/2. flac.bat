:: Запись аудио в flac максимального сжатия

ffmpeg -hide_banner %~5%6 -c:a flac -compression_level 12 %7.flac

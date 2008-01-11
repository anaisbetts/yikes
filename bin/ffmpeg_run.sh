#1/bin/bash


export LD_LIBRARY_PATH="/usr/local/lib"

/usr/local/bin/ffmpeg -y -i "$1" -an -v 1 -threads auto -vcodec libx264 -b 500000 -bt 175000 -refs 1 -loop 1 -deblockalpha 0 -deblockbeta 0 -parti4x4 1 -partp8x8 1 -me full -subq 1 -me_range 21 -chroma 1 -slice 2 -bf 0 -level 30 -g 300 -keyint_min 30 -sc_threshold 40 -rc_eq 'blurCplx^(1-qComp)' -qcomp 0.7 -qmax 51 -qdiff 4 -i_qfactor 0.71428572 -maxrate 768000 -bufsize 2M -cmp 1 -s 480x320 -f mp4 -pass 1 /dev/null 

/usr/local/bin/ffmpeg -y -i "$1" -v 1 -threads auto -vcodec libx264 -b 500000 -bt 175000 -refs 1 -loop 1 -deblockalpha 0 -deblockbeta 0 -parti4x4 1 -partp8x8 1 -me full -subq 6 -me_range 21 -chroma 1 -slice 2 -bf 0 -level 30 -g 300 -keyint_min 30 -sc_threshold 40 -rc_eq 'blurCplx^(1-qComp)' -qcomp 0.7 -qmax 51 -qdiff 4 -i_qfactor 0.71428572 -maxrate 768000 -bufsize 2M -cmp 1 -s 480x320 -acodec libfaac -ab 96 -ar 48000 -ac 2 -f mp4 -pass 2 "$2"
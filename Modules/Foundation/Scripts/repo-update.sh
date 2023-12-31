for i in `ls ~/.cocoapods/repos`; do echo "*** $i ***" && cd ~/.cocoapods/repos/$i && git pull; done

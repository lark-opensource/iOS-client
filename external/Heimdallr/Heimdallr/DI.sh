#!/bin/bash
cd $SOURCE_ROOT
export commit=`git rev-parse HEAD`
cd Heimdallr/Heimdallr/Assets/Core

length=32 
i=1

seq=(0 1 2 3 4 5 6 7 8 9 a b c d e f)
num_seq=${#seq[@]}
uuidstr=''
  
while [ "$i" -le "$length" ]
do
    uuidstr=$uuidstr${seq[$((RANDOM%num_seq))]}  
    let "i=i+1"  
done  
echo "
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
	<key>commit</key>
	<string>$commit</string>
	<key>emuuid</key>
	<string>$uuidstr</string>
</dict>
</plist>

    " > Heimdallr.plist

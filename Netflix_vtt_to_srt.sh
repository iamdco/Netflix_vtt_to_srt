#!/bin/bash

#搜尋打包好的字幕 zip 檔，並解壓縮到 vtt 這個目錄
find ./*.zip -exec sh -c 'echo "Unzip the file {}" ; /usr/bin/7z e -ovtt "{}" ; echo "Unzip the file {} is OK"' \;

#切換到目錄 vtt 底下，並將 vtt 字幕檔複製到 ../srt 目錄裡，複製完畢後切換到 ../srt 目錄
cd vtt ; echo "Rsync vtt to srt" ; rsync -a *.vtt ../srt ; cd ../srt ; echo "Rename vtt to srt"

#將 srt 目錄底下的 .vtt 更名為 .srt
for f in *.vtt; do
  base=`basename $f .vtt`
  mv $f $base.srt
done

echo "Change vtt format to srt"

#搜尋每個 srt 檔，取得需移除的行數，從第一行到取得的行數全刪除，並將 vtt 的參數全部刪除
find ./*.srt -exec sh -c 'del=`head -n 30 "{}" | grep -n "NOTE /SegmentIndex" | cut -d":" -f 1` ; del+="d" ; sed -i "1,$del;s/<c.[a-z]*>//g;s/<\/c.[a-z]*>//g;s/<c.[a-z_]*>//g;s/<\/c.[a-z_]*>//g;s/^&[a-z]*;//g;s/position:.*//g" "{}"' \;

cd ..

#取的 mp4 檔案名稱並排序，將 .mp4 取代成 .srt 匯入 newname.txt
find ./ -type f | grep -E "\.mp4" | grep -v "@eaDir" | sort -k1,1 -k2n | awk -v awk_newname="newname.txt" 'BEGIN {FS="/"}
{
  if ( ("" != $2) && ("" == $3) )
    {
     delext=$2
     gsub(/.mp4/,".srt",delext)
     print delext >> awk_newname
    }
}
'

#取的 mp4 檔案名稱並排序包含下一層目錄，將 .mp4 取代成 .srt 匯入 newname.txt
find ./ -type f | grep -E "\.mp4" | grep -v "@eaDir" | sort -k2,2 -k3n | awk -v awk_newname="newname.txt" 'BEGIN {FS="/"}
{
  if ( ("" != $2) && ("" != $3) && ("" == $4) )
    {
     delext=$3
     gsub(/.mp4/,".srt",delext)
     print $1"/"$2"/"delext >> awk_newname
    }
}
'

#取的繁體中文的字幕檔案名稱，並排序後匯入 oldname.txt
find ./ -type f | grep -E "\zh-Hant.srt" | sort >> oldname.txt

#檢查 newname.txt 與 oldname.txt 行數是否相同，不相同的話中斷程式
line1=`cat ./newname.txt | wc -l`
line2=`cat ./oldname.txt | wc -l`
if [ $line1 -ne $line2 ] ; then
echo "Rename txt Inconsistent"
exit
fi

#先宣告
loopTimes=1

echo "Copy zh-Hant.srt to Movie Dir"

#逐行讀取將繁體中文的字幕檔案名稱，修改成影片檔名稱並放置到對應的目錄裡
while read fileName
do
lineNum=`echo $loopTimes"p"`
newFileName=`sed -n $lineNum newname.txt`
echo "cp $fileName $newFileName"
cp "$fileName" "$newFileName"
loopTimes=`expr $loopTimes + 1`
done < oldname.txt

#移除暫用的 txt 檔案
rm newname.txt
rm oldname.txt
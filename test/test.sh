#!/bin/zsh 

TARGET_DIR_COPY=/bin

rm -rf /tmp/test
rm -rf /tmp/test2
rm -rf /tmp/nb1
rm -rf /tmp/nb2
rm -rf /tmp/out

mkdir /tmp/test
mkdir /tmp/test2

cp $TARGET_DIR_COPY/* /tmp/test

../famine

cd /tmp/test

for file in $(find)
do
strings $file 2>/dev/null | grep araout >> /tmp/out
done

echo Checking signature in all elf file
cat /tmp/out | wc -l > /tmp/nb1
readelf -h $TARGET_DIR_COPY/* 2> /dev/null | grep "OS/ABI:" | wc -l > /tmp/nb2


echo check the amount of  diff

diff /tmp/nb1 /tmp/nb2


echo END OF diff

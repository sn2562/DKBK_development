#!/bin/sh

recentFile=

#最新のOrder.javaを探す
for file in `ls`
do
	targetFile=${file}/Order.java
	if [ -d ${file} -a -e ${targetFile} ]; then
		if [ ! ${recentFile} ]; then
			recentFile=${targetFile}
		elif [ ${recentFile} -ot ${targetFile} ]; then
			recentFile=${targetFile}
		fi
	fi
done

echo -n "\"${recentFile}\"を最新の物として更新を行いますか？ y/n:"
read ans

#全てのOrder.javaを最新のものに更新する。
if [ $ans == y ]; then
	for file in `ls`
	do
		targetFile=${file}/Order.java
		if [ -d ${file} -a -e ${targetFile} -a ${targetFile} != ${recentFile} ]; then
			cp ${recentFile} ${targetFile}
		fi
	done

	echo "更新が完了しました。"
fi
#!/bin/sh
#############################################################################################
###  $1 : private key
###  $2 : public key
###  $3 : AES key
###  $4 : folder Path(file-base mode update) /file Path(partition-base mode update)
###  $5 : output name
###  $6 : enable separate RSA/AES
###  $7 : separate size (Must be a multiple of 16)
#############################################################################################

BRK=0
SECURE_SYSTEM=0
PARTITION_UPDATE=0
temp="Y"
while [ "$BRK" != "1"  ]
do
  
  #read -p "Is this image used in partition update? (Y/n)" temp
   if [ "$temp" == "Y" ] || [ "$temp" == "y" ]; then
   		PARTITION_UPDATE=1
		BRK=1
   else
		#read -p "Is this for secure boot? (Y/n)" temp
		if [ "$temp" == "Y" ] || [ "$temp" == "y" ]; then
			SECURE_SYSTEM=1
			BRK=1
		else
			BRK=1
		fi	
	fi
	
done



## If this image is used in secure system, we need to do segment rsa encode for ever files in input folder($4)
if [ "$SECURE_SYSTEM" == "1"  ];then
./folderRsa.sh $1 $2 $4 $6 $7
fi


if [ "$PARTITION_UPDATE" == "1"  ];then
cp -f $4 $5
OUTPUT_FILE_NAME=$5
else
tar -zcv -f $5.tar.gz $4
OUTPUT_FILE_NAME=$5.tar.gz
fi

#./cryptest.exe na_sign $1 $2 $5.tar.gz $5.signature
./RSAEncode.exe $1 $2 ${OUTPUT_FILE_NAME} $6 $7

./GenChunk.exe $7 ${OUTPUT_FILE_NAME} ${OUTPUT_FILE_NAME}.hash ${OUTPUT_FILE_NAME}.hash.signature

cat ${OUTPUT_FILE_NAME}.hash >>${OUTPUT_FILE_NAME} 
cat ${OUTPUT_FILE_NAME}.hash.signature >>${OUTPUT_FILE_NAME} 
./alignment.exe ${OUTPUT_FILE_NAME} 
cat ./chunk	>>${OUTPUT_FILE_NAME} 

./aescrypt2.exe  0 ${OUTPUT_FILE_NAME} ${OUTPUT_FILE_NAME}.aes $3 

rm ./chunk
rm ${OUTPUT_FILE_NAME}.hash
rm ${OUTPUT_FILE_NAME}.hash.signature



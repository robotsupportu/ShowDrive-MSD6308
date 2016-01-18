#!/bin/sh
#############################################################################################
###  $1 : private key
###  $2 : public key
###  $3 : folder Path
###  $4 : enable separate RSA/AES
###  $5 : separate size (Must be a multiple of 16)
#############################################################################################
FOLDER_LIST=Folderlist.sh
FILELIST=Filelist.sh
FILELISTINI=filelist.ini

printf '#!/bin/sh\n' >${FILELIST}
printf '#!/bin/sh\n' >${FOLDER_LIST}
chmod 777 ./${FOLDER_LIST}
chmod 777 ./${FILELIST}
chmod 777 ./GenFilelist.exe

ls $3 -R |grep ':'| sed s/:/' >>Filelist.sh'/| sed s/./'.\/GenFilelist.exe $1 $2 .'/   >> ${FOLDER_LIST}
#ls $3 -R |grep ':'| sed s/://| sed s/./'.\/GenFilelist.exe $1 $2 .'/   >> ${FOLDER_LIST}


./${FOLDER_LIST} $1 $2 


#sed s/'a'/'##filelist.ini'/
export length $3

cat ./Filelist.sh |grep 'filelist.ini'|sed 's/##filelist.ini //' >$3/${FILELISTINI}
#cat ./Filelist.sh |grep 'filelist.ini' >$3/abc.ini
#cat ./Filelist.sh |grep './RSAEncode.exe'>${FILELIST}
./${FILELIST} $4 $5

#rm temp.sh
#rm ${FOLDER_LIST}
#rm ${FILELIST}


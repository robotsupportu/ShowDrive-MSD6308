#!/bin/bash

if [ "$PROJ_MODE" == "atsc" ] ; then
	source ../projects/env_atsc.cfg 1>/dev/null
else
	source ../projects/env.cfg 1>/dev/null
fi
source ../projects/sw_cfg/${PROJ_MODE}/config.mk 1>/dev/null

ENABLE_COMPRESS=1 # default enable compression
#read -p "ENABLE_COMPRESS? (tee secureboot choose N) (y/N)" temp
temp="n"
echo "ENABLE_COMPRESS? (tee secureboot choose N) (y/N)$temp"

if [ "$temp" == "Y" ] || [ "$temp" == "y" ]; then
	ENABLE_COMPRESS=1
else
	ENABLE_COMPRESS=0
fi

if [ "$1" == "-c" ] ; then
    ENABLE_COMPRESS=1
fi
if [ "$1" == "-C" ] ; then
    ENABLE_COMPRESS=0
fi
SQUSHFS=0 # default don't use spi
if [ "$1" == "-spi" ] ; then
    SQUSHFS="true"
fi
printf "CHIP: $CHIP\n"
printf "TARGET_CPU: $TARGET_CPU\n"
# update soruce "usb" or "network" or "rescue"
UPDAT_METHOD="usb"
READBACK_VERIFY=1
DONT_OVERWRITE=1
FORCE_OVERWRITE=0

if [ "$PROJ_MODE" = "china" ] || [ "$PROJ_MODE" = "europe_dtv" ] || [ "$PROJ_MODE" == "isdb"  ] || [ "$PROJ_MODE" == "atsc"  ] ; then
    if [ "$CHIP" = "nugget" ] || [ "$CHIP" = "nikon.lite" ] ; then
        FORCE_OVERWRITE=1
    fi
fi
#DFUITD: Download Full upgrade Image to DRMM 
#DFUITD=1: UBoot donwload full upgrade image to dram during software upgrade
#DFUITD=0: UBoot donwload partial upgrade image to dram during software upgrade
DFUITD=0


MAX_FILE_SIZE=64
MIN_FILE_SIZE=1 
MAX_FILE_SIZE_HEX=$(($MAX_FILE_SIZE*0x100000))
MIN_FILE_SIZE_HEX=$(($MIN_FILE_SIZE*0x100000))

# check file system
#read -p "Please input your storage type(nand, emmc, spi, k2sqfs): " STORAGE_TYPE
STORAGE_TYPE="nand"
echo "Please input your storage type(nand, emmc, spi, k2sqfs): $STORAGE_TYPE"

echo -e "\nStorage Type: $STORAGE_TYPE"
SN_FS="UBIFS"
if [ "$STORAGE_TYPE" == "nand" ] || [ "$STORAGE_TYPE" == "NAND" ] ; then
    SN_FS="UBIFS"
elif [ "$STORAGE_TYPE" == "emmc" ] || [ "$STORAGE_TYPE" == "EMMC" ] ;then
    SN_FS="EXT4"
elif [ "$STORAGE_TYPE" == "spi" ] || [ "$STORAGE_TYPE" == "SPI" ] ;then
    SN_FS="SQUSHFS"
elif [ "$STORAGE_TYPE" == "k2sqfs" ];then
    SN_FS="K2SQFS"
    MAX_FILE_SIZE=64
    MAX_FILE_SIZE_HEX=$(($MAX_FILE_SIZE*0x100000))
else
    printf "Error: Please input correct storage type!!!! Exit\n"
    exit 0
fi

printf "SN_FS: $SN_FS\n"

function func_init_common_env(){
    #==============Set Image Directory====================================
    if [ ! -d "$MSCRIPT_DIR" ]; then
        MSCRIPT_DIR=../target/$PROJ_MODE.$CHIP/mscript/
        if [ "$SN_FS" == "EXT4" ] ; then
            IMAGE_DIR=../target/$PROJ_MODE.$CHIP/images/ext4/
        elif [ "$SN_FS" == "SQUSHFS" ] ; then
            IMAGE_DIR=../target/$PROJ_MODE.$CHIP/images/sqfs_spi/
        else
            IMAGE_DIR=../target/$PROJ_MODE.$CHIP/images/ubifs/
        fi
    fi
    if [ "$SN_FS" == "EXT4" ] ; then
        IMAGE_EXT=".ext4"
    elif [ "$SN_FS" == "SQUSHFS" ] ; then
        IMAGE_EXT=".sqfs"
    else
        IMAGE_EXT=".ubifs"
    fi
	
	
	FILE_PART_READ_CMD="filepartload"	
    USB_IMG=$IMAGE_DIR/$OUTPUT_IMG
    SCRIPT_FILE=$IMAGE_DIR/usb_upgrade.txt
	PRE_SCRIPT_FILE=$IMAGE_DIR/pre_usb_upgrade.txt
	TEMP_SCRIPT_FILE=$IMAGE_DIR/tempScript
if [ "$STORAGE_TYPE" == "k2sqfs" ];then
	SCRIPT_BUF_SIZE=0x2000
	SPILT_SIZE=8192 #depand on SCRIPT_BUF_SIZE
else
	SCRIPT_BUF_SIZE=0x4000
	SPILT_SIZE=16384 #depand on SCRIPT_BUF_SIZE
fi
    PAD_DUMMY_SIZE=10240
    if [ "$TARGET_CPU" == "arm" ] ; then
                if [ "$CHIP" = "eiffel" ] ; then
                        DRAM_BUF_ADDR=0x20200000
                else
                        DRAM_BUF_ADDR=0x40200000
                fi
    else
		if [ "$DFUITD" == "1" ] ; then
			DRAM_BUF_ADDR=0x80004000
		else
			DRAM_BUF_ADDR=0x82000000
		fi
    fi
	
	if [ "$TARGET_CPU" == "arm" ] ; then
                if [ "$CHIP" = "eiffel" ] ; then
		        DRAM_DECOMPRESS_BUF_ADDR=0x20300000
                else
                        DRAM_DECOMPRESS_BUF_ADDR=0x40300000
                fi
	else
		if [ "$DFUITD" == "1" ] ; then
			DRAM_DECOMPRESS_BUF_ADDR=0x89800000
		else
			DRAM_DECOMPRESS_BUF_ADDR=0x80300000
		fi
	fi
	DRAM_FATLOAD_BUF_ADDR=$(($DRAM_DECOMPRESS_BUF_ADDR+$MAX_FILE_SIZE_HEX))
	
	
	DRAM_BUF_ADDR_START=$DRAM_BUF_ADDR
	DRAM_BUF_ADDR=$(($DRAM_BUF_ADDR+$SCRIPT_BUF_SIZE))
	
    TEMP_IMG=$IMAGE_DIR/usb_temp.bin
    PADDED_BIN=$IMAGE_DIR/padded.bin
    PAD_DUMMY_BIN=$IMAGE_DIR/dummy_pad.
    	# set path	
		SEC_KEY_DIR=./tools/BuildUpdateImage/Key
		SEC_TOOL_DIR=./tools/BuildUpdateImage
    
    CRC_BIN=$(find -name crc | sed '2,$d')
    if [ "$CRC_BIN" == "" ] ; then
        echo "Error! no crc binary could be found!"
        exit
    fi
	echo "DRAM_DECOMPRESS_BUF_ADDR=$DRAM_DECOMPRESS_BUF_ADDR"
	echo "DRAM_BUF_ADDR=$DRAM_BUF_ADDR"
}
	
function func_set_dont_overwrite_partition(){
	printf "dont_overwrite_init\n"  >$PRE_SCRIPT_FILE
	
    # If you want to keep KL partition, you have to un-mark the following two lines.
	#printf "dont_overwrite KL\n" >>$PRE_SCRIPT_FILE
	#printf "dont_overwrite kernelSign\n" >>$PRE_SCRIPT_FILE

    # If you want to keep RFS partition, you have to un-mark the following two lines.
	#printf "dont_overwrite RFS\n" >>$PRE_SCRIPT_FILE
	#printf "dont_overwrite ROOTFSSign\n" >>$PRE_SCRIPT_FILE
	
	# If you want to keep MSLIB partition, you have to un-mark the following two lines.
	#printf "dont_overwrite MSLIB\n" >>$PRE_SCRIPT_FILE
	#printf "dont_overwrite mslibSign\n" >>$PRE_SCRIPT_FILE

	# If you want to keep CONFIG partition, you have to un-mark the following two lines.
	#printf "dont_overwrite CONFIG\n" >>$PRE_SCRIPT_FILE
	#printf "dont_overwrite CONFIG_SIGNATURE_BIN\n" >>$PRE_SCRIPT_FILE
	
	# If you want to keep APP partition, you have to un-mark the following two lines.
	#printf "dont_overwrite APP\n" >>$PRE_SCRIPT_FILE
	#printf "dont_overwrite APP_SIGNATURE_BIN\n" >>$PRE_SCRIPT_FILE
	
	# If you want to keep customer partition, you have to un-mark the following line.
	#printf "dont_overwrite customer\n" >>$PRE_SCRIPT_FILE
	
	# If you want to keep customerbackup partition, you have to un-mark the following line.
	if [ "$CHIP" = "nikon.lite" ] || [ "$CHIP" = "nugget" ] ; then
		printf "dont_overwrite customerbackup\n" >>$PRE_SCRIPT_FILE
	fi
	# If you want to keep certificate partition, you have to un-mark the following line.
    printf "dont_overwrite certificate\n" >>$PRE_SCRIPT_FILE
	
	# If you want to keep oad partition, you have to un-mark the following line.
	if [ "$CHIP" != "nikon.lite" ] && [ "$CHIP" != "nugget" ] ; then
		printf "dont_overwrite oad\n" >>$PRE_SCRIPT_FILE
	fi
}

function func_set_force_overwrite_partition(){
	printf "force_overwrite_init\n"  >>$PRE_SCRIPT_FILE
	
	# If you want to overwrite and re-create KL partition, you have to un-mark the following two lines.
	printf "force_overwrite KL\n" >>$PRE_SCRIPT_FILE
	printf "force_overwrite kernelSign\n" >>$PRE_SCRIPT_FILE

	# If you want to overwrite and re-create RFS partition, you have to un-mark the following two lines.
	printf "force_overwrite RFS\n" >>$PRE_SCRIPT_FILE
	printf "force_overwrite ROOTFSSign\n" >>$PRE_SCRIPT_FILE
	
	# If you want to overwrite and re-create MSLIB partition, you have to un-mark the following two lines.
	printf "force_overwrite MSLIB\n" >>$PRE_SCRIPT_FILE
	printf "force_overwrite mslibSign\n" >>$PRE_SCRIPT_FILE

	# If you want to overwrite and re-create CONFIG partition, you have to un-mark the following two lines.
	printf "force_overwrite CONFIG\n" >>$PRE_SCRIPT_FILE
	printf "force_overwrite CONFIG_SIGNATURE_BIN\n" >>$PRE_SCRIPT_FILE
	
	# If you want to overwrite and re-create APP partition, you have to un-mark the following two lines.
	printf "force_overwrite APP\n" >>$PRE_SCRIPT_FILE
	printf "force_overwrite APP_SIGNATURE_BIN\n" >>$PRE_SCRIPT_FILE
	
	# If you want to overwrite and re-create customer partition, you have to un-mark the following line.
	if [ "$CHIP" = "nikon.lite" ] || [ "$CHIP" = "nugget" ] ; then
		printf "force_overwrite customer\n" >>$PRE_SCRIPT_FILE
	fi
	# If you want to overwrite and re-create customerbackup partition, you have to un-mark the following line.
	#printf "force_overwrite customerbackup\n" >>$PRE_SCRIPT_FILE
	
	# If you want to overwrite and re-create certificate partition, you have to un-mark the following line.
	#printf "force_overwrite certificate\n" >>$PRE_SCRIPT_FILE
	
	# If you want to overwrite and re-create oad partition, you have to un-mark the following line.
	if [ "$CHIP" = "nikon.lite" ] || [ "$CHIP" = "nugget" ] ; then
		printf "force_overwrite oad\n" >>$PRE_SCRIPT_FILE
	fi
	
	printf "force_overwrite GINGA\n" >>$PRE_SCRIPT_FILE
	printf "force_overwrite RTPM\n" >>$PRE_SCRIPT_FILE
	
	printf "force_overwrite tee\n" >>$PRE_SCRIPT_FILE
	printf "force_overwrite teeSign\n" >>$PRE_SCRIPT_FILE
}

function func_init_env_for_mboot(){
    #==============init env for mboot================================
    MBOOT_IMG_SIZE=$(stat -c%s $MBOOT_IMG )
    MBOOT_PARTITION_SIZE=0x800000
    #==============init env for mboot done===========================
}

function func_pre_process(){
    #==============Pre-Process===========================================
    #echo "Please put the following 3 materials in the same folder"
    #echo "1. usb_image_build.sh"
    #echo "2. updated partitions"
    #echo "3. crc"

    if [ -f "$TEMP_IMG" ]; then
        rm $TEMP_IMG
    fi
    
    if [ -f "$USB_IMG" ]; then
        rm $USB_IMG
    fi
    
    if [ -f "$SCRIPT_FILE" ]; then
        rm $SCRIPT_FILE
    fi
	
	
	#==============Create PAD_DUMMY_BIN==================================
    printf "\xff" >$PAD_DUMMY_BIN
    for ((i=1; i<$PAD_DUMMY_SIZE; i++))
    do
     printf "\xff" >>$PAD_DUMMY_BIN
    done
    #==============Create PAD_DUMMY_BIN done=============================

    
}

function func_post_process(){
    #================Post-process=====================================
	
    cat $SCRIPT_FILE >>$USB_IMG
    cat $TEMP_IMG >>$USB_IMG
    
    rm $TEMP_IMG
    rm $PAD_DUMMY_BIN

	CRC_BIN=$(find -name crc | sed '2,$d')
    if [ "$READBACK_VERIFY" = "1" ] ; then 
	cp $SCRIPT_FILE $SCRIPT_FILE.temp
	CRC_VALUE=`$CRC_BIN -a $SCRIPT_FILE.temp | grep "CRC32" | awk '{print $3;}'`
	split -d -a 2 -b $SPILT_SIZE $SCRIPT_FILE.temp $SCRIPT_FILE.temp.
	printf "script file crc %s\n" $CRC_VALUE
	cat $SCRIPT_FILE.temp.01 >> $USB_IMG
	rm $SCRIPT_FILE.temp
	rm $SCRIPT_FILE.temp.00
	rm $SCRIPT_FILE.temp.01
	fi #if [ "$READBACK_VERIFY" = "1" ] ; then 
	
    CRC_BIN=$(find -name crc | sed '2,$d')
    $CRC_BIN -a $USB_IMG

    # Add dummy 4 bytes to keep 8-byte alignment
    if [ "$CHIP" == "u4" ] || [ "$CHIP" == "k1" ] ; then
        $CRC_BIN -a $USB_IMG
    fi
    printf "\033[0;31m$USB_IMG\033[0m done\n"
    #================Post-process done================================
}

function func_pad_script(){
	cat $SCRIPT_FILE >>$PRE_SCRIPT_FILE
	rm $SCRIPT_FILE
	mv $PRE_SCRIPT_FILE $SCRIPT_FILE
    #==============pad script===============================
    SCRIPT_FILE_SIZE=$(stat -c%s $SCRIPT_FILE)
    PADDED_SIZE=$(($SCRIPT_BUF_SIZE-$SCRIPT_FILE_SIZE))
    
    while [ $PADDED_SIZE -gt $PAD_DUMMY_SIZE ]
    do
        cat $PAD_DUMMY_BIN >>$SCRIPT_FILE
        PADDED_SIZE=$(($PADDED_SIZE-$PAD_DUMMY_SIZE))
    done
    
    if [ $PADDED_SIZE != 0 ]; then
        printf "\xff" >$PADDED_BIN
        for ((i=1; i<$PADDED_SIZE; i++))
        do
            printf "\xff" >>$PADDED_BIN
        done
    cat $PADDED_BIN >>$SCRIPT_FILE
    rm $PADDED_BIN
    fi
    #==============pad script done==========================
}

function func_finish_script(){
    #==============Complete USB upgrade===============================
	if [ "$UPDAT_METHOD" == "network" ] ; then
    printf "setenv netUpdate_complete 1\n" >>$SCRIPT_FILE
	elif [ "$UPDAT_METHOD" == "usb" ] ; then
	printf "setenv MstarUpgrade_complete 1\n" >>$SCRIPT_FILE
	fi

	printf "saveenv\n" >>$SCRIPT_FILE
    if [ "BRICK_TERMINATOR_ENABLE" == "1" ] && [ "$UPDAT_METHOD" != "rescue" ] ; then
        #backup env
        printf "BrickTerminator backup_env\n" >>$SCRIPT_FILE
    fi
    printf "printenv\n" >>$SCRIPT_FILE
    if [ "$UPDAT_METHOD" != "rescue" ] ; then
    printf "reset\n" >>$SCRIPT_FILE
    fi
    echo "% <- this is end of script symbol" >>$SCRIPT_FILE	
    #=================================================================
}

function func_update_mboot(){
    #==============update mboot===============================
	func_init_common_env;
	func_init_env_for_mboot;
    func_pre_process;
    cat $MBOOT_IMG >>$TEMP_IMG
	#==============Mboot padding =======================
    TEMP_IMG_SIZE=$(stat -c%s $TEMP_IMG ) 
	NOT_ALAIN_TEMP_IMG_SIZE=$(($TEMP_IMG_SIZE & 0x3))
	if [ $NOT_ALAIN_TEMP_IMG_SIZE != 0 ]; then
		PADDED_SIZE=$((0x4-$NOT_ALAIN_TEMP_IMG_SIZE))
		for ((i=0; i<$PADDED_SIZE; i++))
			do
				printf "\xff" >>$PADDED_BIN
			done
		if [ $PADDED_SIZE != 0 ]; then
			cat $PADDED_BIN >>$TEMP_IMG
			rm $PADDED_BIN
		fi
	fi
	#==============cretae script file =======================
	if [ "IS_UBOOT_2011" == "1" ] ; then
		printf "spi wp 0\n" >>$SCRIPT_FILE
		printf "spi ea \n" >>$SCRIPT_FILE
		printf "spi wp 1\n" >>$SCRIPT_FILE
		printf "spi wrc %x 0 %x\n" $DRAM_BUF_ADDR $MBOOT_IMG_SIZE>>$SCRIPT_FILE	
	else
    printf "spi_wp 0\n" >>$SCRIPT_FILE
	printf "spi_ea \n" >>$SCRIPT_FILE
	printf "spi_wp 1\n" >>$SCRIPT_FILE
	printf "spi_wrc %x 0 %x\n" $DRAM_BUF_ADDR $MBOOT_IMG_SIZE>>$SCRIPT_FILE
	fi
    #func_finish_script;
	printf "reset\n" >>$SCRIPT_FILE
	func_pad_script;
	func_post_process;
    #==============copy the first 16 bytes to last =================================
    dd if=$IMAGE_DIR/$OUTPUT_IMG of=$IMAGE_DIR/out.bin bs=16 count=1;
    cat $IMAGE_DIR/out.bin >>$IMAGE_DIR/$OUTPUT_IMG
    rm -rf out.bin
    #==============copy the first 16 bytes to last end=================================
    #==============update mboot done==========================
}

OUTPUT_IMG="MstarUpgrade.bin"
if [ "$1" == "-m" ] ; then
    if [ "$2" != "" ] && test -f "$2" ; then
        echo "Build image for update MBoot..."
        echo
		OUTPUT_IMG="MstarUpgrade_MBoot.bin"
        MBOOT_IMG=$2
        func_update_mboot;
    else
        if [ "$2" == "" ] ; then
            echo
            echo "Error! Please specify MBoot binary path!"
            echo
        else
            echo
            echo "Error! File '$2' not found!"
            echo
        fi
    fi
    exit 0
fi

func_init_common_env;

#----------------------------------------
# Get Partition Offset             
#----------------------------------------
if [ "$SN_FS" == "EXT4" ] ; then
    OFFSET=`cat ../target/$PROJ_MODE.$CHIP/mscript/[[kernel | grep -v "^ *#" | grep "mmc" | grep "write" | awk '{print $5;}'`
    KERNEL_PARTITION_SIZE=$OFFSET
elif [ "$SN_FS" == "SQUSHFS" ] ; then
    OFFSET=`cat ../target/$PROJ_MODE.$CHIP/mscript/[[kernel | grep -v "^ *#" | grep "wrc." | awk '{print $6;}'`
    KERNEL_PARTITION_SIZE=$OFFSET
else
    OFFSET=`cat ../target/$PROJ_MODE.$CHIP/mscript/[[kernel | grep -v "^ *#" | grep "write." | awk '{print $5;}'`
	KERNEL_PARTITION_SIZE=$OFFSET
fi #if [ "$SN_FS" == "EXT4" ] ; then
if [ "$KERNEL_PARTITION_SIZE" == "" ] ; then
    echo
    echo "Failed to get kernel partition settings!"
    echo "Please check if the config file exists!"
    echo
    exit 1
fi


#----------------------------------------
# User config what they want?
#----------------------------------------
SECURE_UPGRADE=0
MBOOT_UPGRADE=0
NAND_MLC_MODE=0

printf "\033[0;31mIs Secure Booting? (y/N)\033[0m"
#read temp
temp="n"
printf "n\n"
if [ "$temp" == "Y" ] || [ "$temp" == "y" ]; then
	SECURE_BOOT=1
fi

if [ "$SECURE_BOOT" == "1" ] ; then
	printf "\033[0;31mDo you want to encrypt your upgrade image? (y/N)\033[0m"
	read temp
	if [ "$temp" == "Y" ] || [ "$temp" == "y" ]; then
		SECURE_UPGRADE=1
	fi 
fi

IS_UBOOT_2011=1
if [ "$SN_FS" == "UBIFS" ] || [ "$SN_FS" == "K2SQFS" ]; then
	printf "Is UBOOT 2011.06? (Y/n)"
#	read temp
	temp="n"
	printf "$temp\n"
	if [ "$temp" == "N" ] || [ "$temp" == "n" ]; then
		IS_UBOOT_2011=0
	fi 	
	if [ "$IS_UBOOT_2011" == "1" ] ; then
		CMD_FLASH_ERASE_WHOLE="nand erase.chip"
		CMD_NAND_ERASE_PART="nand erase.part"
	else
		CMD_FLASH_ERASE_WHOLE="nand erase"
		CMD_NAND_ERASE_PART="nand erase"
	fi
	
	printf "Is NAND MLC MODE? (y/N)"
#	read temp
	temp="n"
	printf "$temp\n"
	if [ "$temp" == "Y" ] || [ "$temp" == "y" ]; then
	    # In mlc mode, kenerl needs lowpage read/write to simulate slc mode.
		CMD_FLASH_WRITE="nand write.slc"
		CMD_FLASH_READ="nand read.slc"
	else
		CMD_FLASH_WRITE="nand write.e"
		CMD_FLASH_READ="nand read.e"
	fi
elif [ "$SN_FS" == "SQUSHFS" ] ; then
        CMD_FLASH_ERASE_WHOLE="spi rmgpt"
	CMD_FLASH_WRITE="spi wrc.p"
	CMD_FLASH_READ="spi rdc.p"
else
	CMD_FLASH_ERASE_WHOLE="mmc rmgpt"
	CMD_FLASH_WRITE="mmc write.p.continue"
	CMD_FLASH_READ="mmc read.p.continue"
fi
NAND_SQFS_CMD_FLASH_WRITE="nand write.e"
NAND_SQFS_CMD_FLASH_READ="nand read.e"

FULL_UPGRADE=1
UPGRADE_FOR_USB=1
#read -p "Upgrade for usb? (OAD choose N) (Y/n)" temp
temp=n
echo "Upgrade for usb? (OAD choose N) (Y/n)$temp"
if [ "$temp" == "N" ] || [ "$temp" == "n" ]; then
    UPGRADE_FOR_USB=0
    FULL_UPGRADE=0
#    read -p "Upgrade for rescue (BrickTerminator)? (y/N)" temp
    temp=n
    echo "Upgrade for rescue (BrickTerminator)? (y/N) $temp"
    if [ "$temp" == "Y" ] || [ "$temp" == "y" ]; then
        UPDAT_METHOD="rescue"
    fi
else
    read -p "Upgrade all? (Y/n)" temp
    if [ "$temp" == "N" ] || [ "$temp" == "n" ]; then
        FULL_UPGRADE=0
    fi
fi

printf "Add Mboot.bin in MstarUpgrade.bin? (y/N)"  
#read temp
temp="n"
printf "$temp\n"
if [ "$temp" == "Y" ] || [ "$temp" == "y" ]; then
    MBOOT_IMG=$IMAGE_DIR/mboot.bin
    test -f $MBOOT_IMG  
    if [ $? != 0 ];then
        MBOOT_IMG=$IMAGE_DIR/RomBoot.bin
        test -f $MBOOT_IMG
        if [ $? != 0 ];then
            printf "\033[0;31mError : no mboot.bin(RomBoot.bin) in $IMAGE_DIR\n\033[0m" 
            exit 0
        fi
    fi
        MBOOT_UPGRADE=1
fi

#----------------------------------------
# Setup images's path and name
#----------------------------------------
if [ "$CHIP" == "u4" ] ; then
    KL_IMG=$IMAGE_DIR/uImage.lzo
else
	if [ "$SECURE_BOOT" == "1" ] ; then
		KL_IMG=$IMAGE_DIR/uImage.aes
	else
		KL_IMG=$IMAGE_DIR/uImage
	fi
fi

#convert script file from dos to unix
dos2unix $MSCRIPT_DIR*

CUT_CHARACTER_COUNT=0
GREP_KEYWORD=^tftp

#count "/" mark 
CUT_CHARACTER_COUNT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[tee -m 1 2>/dev/null | grep -o "/" | wc -l | xargs expr 1 +`
#get image extend name in tftp script line
TEE_IMG_EXT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[tee -m 1 2>/dev/null | cut -d '/' -f $CUT_CHARACTER_COUNT | cut -d '.' -f 2`

CUT_CHARACTER_COUNT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[ROOTFS -m 1 2>/dev/null | grep -o "/" | wc -l | xargs expr 1 +`
RFS_IMG_EXT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[ROOTFS -m 1 2>/dev/null | cut -d '/' -f $CUT_CHARACTER_COUNT | cut -d '.' -f 2`

CUT_CHARACTER_COUNT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[applications -m 1 2>/dev/null | grep -o "/" | wc -l | xargs expr 1 +`
APP_IMG_EXT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[applications -m 1 2>/dev/null | cut -d '/' -f $CUT_CHARACTER_COUNT | cut -d '.' -f 2`

CUT_CHARACTER_COUNT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[mslib -m 1 2>/dev/null | grep -o "/" | wc -l | xargs expr 1 +`
MSLIB_IMG_EXT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[mslib -m 1 2>/dev/null | cut -d '/' -f $CUT_CHARACTER_COUNT | cut -d '.' -f 2`

CUT_CHARACTER_COUNT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[config -m 1 2>/dev/null | grep -o "/" | wc -l | xargs expr 1 +`
CONFIG_IMG_EXT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[config -m 1 2>/dev/null | cut -d '/' -f $CUT_CHARACTER_COUNT | cut -d '.' -f 2`

CUT_CHARACTER_COUNT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[customer -m 1 2>/dev/null | grep -o "/" | wc -l | xargs expr 1 +`
CUSTOMER_IMG_EXT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[customer -m 1 2>/dev/null | cut -d '/' -f $CUT_CHARACTER_COUNT | cut -d '.' -f 2`

CUT_CHARACTER_COUNT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[customerbackup -m 1 2>/dev/null | grep -o "/" | wc -l | xargs expr 1 +`
CUSTOMERBACKUP_IMG_EXT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[customerbackup -m 1 2>/dev/null | cut -d '/' -f $CUT_CHARACTER_COUNT | cut -d '.' -f 2`

if [ "$CUSTOMERBACKUP_IMG_EXT" == "" ] ; then
    CUT_CHARACTER_COUNT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[customer -m 2 2>/dev/null | grep customerbackup | grep -o "/" | wc -l | xargs expr 1 +`
    CUSTOMERBACKUP_IMG_EXT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[customer -m 2 2>/dev/null | grep customerbackup | cut -d '/' -f $CUT_CHARACTER_COUNT | cut -d '.' -f 2`
fi

CUT_CHARACTER_COUNT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[oad -m 1 2>/dev/null | grep -o "/" | wc -l | xargs expr 1 +`
OAD_IMG_EXT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[oad -m 1 2>/dev/null | cut -d '/' -f $CUT_CHARACTER_COUNT | cut -d '.' -f 2`

CUT_CHARACTER_COUNT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[certificate -m 1 2>/dev/null | grep -o "/" | wc -l | xargs expr 1 +`
CERTIFICATE_IMG_EXT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[certificate -m 1 2>/dev/null | cut -d '/' -f $CUT_CHARACTER_COUNT | cut -d '.' -f 2`

CUT_CHARACTER_COUNT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[brickreserve -m 1 2>/dev/null | grep -o "/" | wc -l | xargs expr 1 +`
BRICKRESERVE_IMG_EXT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[brickreserve -m 1 2>/dev/null | cut -d '/' -f $CUT_CHARACTER_COUNT | cut -d '.' -f 2`

CUT_CHARACTER_COUNT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[brickbackup -m 1 2>/dev/null | grep -o "/" | wc -l | xargs expr 1 +`
BRICKBACKUP_IMG_EXT=`grep "$GREP_KEYWORD" $MSCRIPT_DIR/\[\[brickbackup -m 1 2>/dev/null | cut -d '/' -f $CUT_CHARACTER_COUNT | cut -d '.' -f 2`

RTPM_IMG=$IMAGE_DIR/RT_51.bin
TEE_IMG=$IMAGE_DIR/tee.aes
MSLIB_IMG=$IMAGE_DIR/mslib.$MSLIB_IMG_EXT
CONFIG_IMG=$IMAGE_DIR/config.$CONFIG_IMG_EXT
CUSTOMER_IMG=$IMAGE_DIR/customer.$CUSTOMER_IMG_EXT
CUSTOMERBACKUP_IMG=$IMAGE_DIR/customerbackup.$CUSTOMERBACKUP_IMG_EXT
OAD_IMG=$IMAGE_DIR/OAD.$OAD_IMG_EXT
CERTIFICATE_IMG=$IMAGE_DIR/certificate.$CERTIFICATE_IMG_EXT

BRICKRESERVE_IMG=$IMAGE_DIR/brickreserve.$BRICKRESERVE_IMG_EXT
BRICKBACKUP_IMG=$IMAGE_DIR/brickbackup.$BRICKBACKUP_IMG_EXT

if [ "$SN_FS" == "EXT4" ] ; then
    RFS_IMG=$IMAGE_DIR/rootfs.squashfs
    APP_IMG=$IMAGE_DIR/app$IMAGE_EXT
elif [ "$SN_FS" == "SQUSHFS" ] ; then
    RFS_IMG=$IMAGE_DIR/rootfs$IMAGE_EXT
    CUSTOMER_IMG=$IMAGE_DIR/customer.jffs2
else
    RFS_IMG=$IMAGE_DIR/rootfs.$RFS_IMG_EXT
    APP_IMG=$IMAGE_DIR/applications.$APP_IMG_EXT
fi
if [ "$PROJ_MODE" == "isdb"  ] ; then
GINGA_IMG=$IMAGE_DIR/ginga$IMAGE_EXT
fi

KL_SIGNATURE_BIN=$IMAGE_DIR/secure_info_kernel.bin
TEE_SIGNATURE_BIN=$IMAGE_DIR/secure_info_tee.bin
RFS_SIGNATURE_BIN=$IMAGE_DIR/secure_info_rootfs.bin
MSLIB_SIGNATURE_BIN=$IMAGE_DIR/secure_info_mslib.bin
CONFIG_SIGNATURE_BIN=$IMAGE_DIR/secure_info_config.bin
APP_SIGNATURE_BIN=$IMAGE_DIR/secure_info_app.bin
KEYSET_SIGNATURE_BIN=$IMAGE_DIR/secure_info_keySet.bin
KEYSET_BIN=$IMAGE_DIR/keySet.bin
USB_IMG=$IMAGE_DIR/$OUTPUT_IMG
func_pre_process;


if [ "$SN_FS" == "UBIFS" ] ; then
	if [ "$PROJ_MODE" == "isdb"  ] ; then
		PARTION_NAME="KL tee RTPM RFS MSLIB CONFIG APP GINGA customer customerbackup certificate"
		PARTION_IMAGE="$KL_IMG $TEE_IMG $RTPM_IMG $RFS_IMG $MSLIB_IMG $CONFIG_IMG $APP_IMG $GINGA_IMG $CUSTOMER_IMG $CUSTOMERBACKUP_IMG $CERTIFICATE_IMG"
		PARTION_FS="none none none $RFS_IMG_EXT $MSLIB_IMG_EXT $CONFIG_IMG_EXT $APP_IMG_EXT $GINGA_IMG_EXT $CUSTOMER_IMG_EXT $CUSTOMERBACKUP_IMG_EXT $CERTIFICATE_IMG_EXT"
	elif [ "$PROJ_MODE" == "atsc"  ] ; then
		PARTION_NAME="KL tee RTPM RFS MSLIB CONFIG APP customer customerbackup oad brickreserve brickbackup certificate"
		PARTION_IMAGE="$KL_IMG $TEE_IMG $RTPM_IMG $RFS_IMG $MSLIB_IMG $CONFIG_IMG $APP_IMG $CUSTOMER_IMG $CUSTOMERBACKUP_IMG $OAD_IMG $BRICKRESERVE_IMG $BRICKBACKUP_IMG $CERTIFICATE_IMG"
		PARTION_FS="none none none $RFS_IMG_EXT $MSLIB_IMG_EXT $CONFIG_IMG_EXT $APP_IMG_EXT $CUSTOMER_IMG_EXT $CUSTOMERBACKUP_IMG_EXT $OAD_IMG_EXT $BRICKRESERVE_IMG_EXT $BRICKBACKUP_IMG_EXT $CERTIFICATE_IMG_EXT"
	elif [ "$PROJ_MODE" == "europe_dtv"  ] ; then
		PARTION_NAME="KL tee RTPM RFS MSLIB CONFIG APP customer customerbackup oad brickreserve brickbackup certificate"
		PARTION_IMAGE="$KL_IMG $TEE_IMG $RTPM_IMG $RFS_IMG $MSLIB_IMG $CONFIG_IMG $APP_IMG $CUSTOMER_IMG $CUSTOMERBACKUP_IMG $OAD_IMG $BRICKRESERVE_IMG $BRICKBACKUP_IMG $CERTIFICATE_IMG"
		PARTION_FS="none none none $RFS_IMG_EXT $MSLIB_IMG_EXT $CONFIG_IMG_EXT $APP_IMG_EXT $CUSTOMER_IMG_EXT $CUSTOMERBACKUP_IMG_EXT $OAD_IMG_EXT $BRICKRESERVE_IMG_EXT $BRICKBACKUP_IMG_EXT $CERTIFICATE_IMG_EXT"
	else
		PARTION_NAME="KL tee RFS MSLIB CONFIG APP customer customerbackup oad brickreserve brickbackup certificate"
		PARTION_IMAGE="$KL_IMG $TEE_IMG $RFS_IMG $MSLIB_IMG $CONFIG_IMG $APP_IMG $CUSTOMER_IMG $CUSTOMERBACKUP_IMG $OAD_IMG $BRICKRESERVE_IMG $BRICKBACKUP_IMG $CERTIFICATE_IMG"
		PARTION_FS="none none $RFS_IMG_EXT $MSLIB_IMG_EXT $CONFIG_IMG_EXT $APP_IMG_EXT $CUSTOMER_IMG_EXT $CUSTOMERBACKUP_IMG_EXT $OAD_IMG_EXT $BRICKRESERVE_IMG_EXT $BRICKBACKUP_IMG_EXT $CERTIFICATE_IMG_EXT"
	fi
elif [ "$SN_FS" == "SQUSHFS" ] ; then
        PARTION_NAME="KL tee RFS CUS"
        PARTION_IMAGE="$KL_IMG $TEE_IMG $RFS_IMG $CUSTOMER_IMG"
        PARTION_FS="$IMAGE_EXT none $IMAGE_EXT $IMAGE_EXT"
elif [ "$SN_FS" == "K2SQFS" ] ; then
        PARTION_NAME="KL tee RFS MSLIB CONFIG APP customer"
        PARTION_IMAGE="$KL_IMG $TEE_IMG $RFS_IMG $MSLIB_IMG $CONFIG_IMG $APP_IMG $CUSTOMER_IMG"
        PARTION_FS="none none $RFS_IMG_EXT $MSLIB_IMG_EXT $CONFIG_IMG_EXT $APP_IMG_EXT $CUSTOMER_IMG_EXT"
else
	PARTION_NAME="KL tee RFS MSLIB CONFIG APP customer certificate"
	PARTION_IMAGE="$KL_IMG $TEE_IMG $RFS_IMG $MSLIB_IMG $CONFIG_IMG $APP_IMG $CUSTOMER_IMG $CERTIFICATE_IMG"
	PARTION_FS="none none $RFS_IMG_EXT $MSLIB_IMG_EXT $CONFIG_IMG_EXT $APP_IMG_EXT $CUSTOMER_IMG_EXT $CERTIFICATE_IMG_EXT"
	#PARTION_OFFSET="$KERNEL_PARTITION_OFFSET $RFS_PARTITION_OFFSET $MSLIB_PARTITION_OFFSET $CONFIG_PARTITION_OFFSET $APP_PARTITION_OFFSET $CUSTOMER_PARTITION_OFFSET $CERTIFICATE_PARTITION_OFFSET"
fi #if [ "$SN_FS" == "UBIFS" ] ; then
PARTION_SIGN_NAME="kernelSign teeSign none ROOTFSSign mslibSign configSign applicationsSign none none none none none none"
PARTION_SIGN_IMAGE="$KL_SIGNATURE_BIN $TEE_SIGNATURE_BIN none $RFS_SIGNATURE_BIN $MSLIB_SIGNATURE_BIN $CONFIG_SIGNATURE_BIN $APP_SIGNATURE_BIN none none none none none none"

#----------------------------------------
# Init "dont over write" process
#----------------------------------------
#if [ "$DONT_OVERWRITE" == "1" ] &&  [ "$TARGET_CPU" != "arm" ]; then
if [ "$DONT_OVERWRITE" == "1" ] ; then
	if [ "$FULL_UPGRADE" == "1"  ] ; then
		func_set_dont_overwrite_partition;
		if [ "$FORCE_OVERWRITE" == "1" ] ; then
			func_set_force_overwrite_partition;
		fi
	fi
fi

#----------------------------------------
# Copy content of set_partition.sh to  $SCRIPT_FILE
#----------------------------------------
if [ "$FULL_UPGRADE" == "1"  ] ; then
	printf "$CMD_FLASH_ERASE_WHOLE\n" >>$SCRIPT_FILE
	dos2unix $MSCRIPT_DIR/set_partition 2>/dev/null
	exec 6<&0 # Link file descriptor #6 with stdin. Saves stdin.
	exec<"$MSCRIPT_DIR/set_partition"

	while read line
	do
		output=`echo $line | grep -v \# | grep -v \%`
		if [ "$output" != "" ] ; then
			printf "$output\n" >> $SCRIPT_FILE
		fi
	done
	exec 0<&6 6<&- #Now restore stdin from fd #6, where it had been saved and close fd #6 ( 6<&- ) to free it for other processes to use.
else
if [ "$SN_FS" == "UBIFS" ] || [ "$SN_FS" == "K2SQFS" ]; then
    if [ "$UPGRADE_FOR_USB" != "1"  ] ; then
        printf "ubi part UBI\n" >>$SCRIPT_FILE
        if [ "$UPDAT_METHOD" != "rescue" ] ; then
        printf "ubifsmount oad\n" >>$SCRIPT_FILE
        else
            printf "ubifsmount brickbackup\n" >>$SCRIPT_FILE
        fi
    fi
fi
fi
#if [ "$FULL_UPGRADE" == "1"  ] ; then
#----------------------------------------
# Process kernel image
#----------------------------------------
count=1
_TEMP_PARTITION_NAME=`printf "%s " $PARTION_NAME | awk '{print $'$count';}'`
_TEMP_IMAGE=`printf "%s " $PARTION_IMAGE | awk '{print $'$count';}'`
_TEMP_IMAGE_SIZE=$(stat -c%s $_TEMP_IMAGE )
_TEMP_IMAGE_FILE_NAME=$(echo $_TEMP_IMAGE | sed 's\.*/\\g')
if [ "$FULL_UPGRADE" == "1"  ] ; then
	temp="Y"
else
#	read -p "Update kernel? (y/N)" temp
	temp="n"
	echo "Update kernel? (y/N)$temp"
fi
if [ "$temp" == "Y" ] || [ "$temp" == "y" ]; then
	printf "\033[0;36mProcess $_TEMP_PARTITION_NAME ...\033[0m\n"
	if [ "$ENABLE_COMPRESS" = "1" ] ; then
		_TEMP_IMAGE_COMPRESSED=$_TEMP_IMAGE.com
		 ./tools/mscompress7 e 0 $_TEMP_IMAGE $_TEMP_IMAGE_COMPRESSED
		_TEMP_IMAGE_COMPRESSED_SIZE=$(stat -c%s $_TEMP_IMAGE_COMPRESSED )
		PADDED_SIZE=$(($_TEMP_IMAGE_COMPRESSED_SIZE-($_TEMP_IMAGE_COMPRESSED_SIZE&0xFFF0000)))
		if [ $PADDED_SIZE != 0 ]; then
			PADDED_SIZE=$((0x10000-$PADDED_SIZE))
		fi
		PARTITION_SIZE=$(($_TEMP_IMAGE_COMPRESSED_SIZE+$PADDED_SIZE))
		cat $_TEMP_IMAGE_COMPRESSED >>$TEMP_IMG
	else
		_TEMP_IMAGE_COMPRESSED_SIZE=$(stat -c%s $_TEMP_IMAGE)
		PADDED_SIZE=$(($_TEMP_IMAGE_COMPRESSED_SIZE-($_TEMP_IMAGE_COMPRESSED_SIZE&0xFFF0000)))
		if [ $PADDED_SIZE != 0 ]; then
			PADDED_SIZE=$((0x10000-$PADDED_SIZE))
		fi
		PARTITION_SIZE=$(($_TEMP_IMAGE_COMPRESSED_SIZE+$PADDED_SIZE))
		cat $_TEMP_IMAGE >>$TEMP_IMG
	fi #if [ "$ENABLE_COMPRESS" = "1" ] ; then

	#echo "($_TEMP_PARTITION_NAME) padding size : $PADDED_SIZE"

	while [ $PADDED_SIZE -gt $PAD_DUMMY_SIZE ]
	do
		cat $PAD_DUMMY_BIN >>$TEMP_IMG
		PADDED_SIZE=$(($PADDED_SIZE-$PAD_DUMMY_SIZE))
	done

	if [ $PADDED_SIZE != 0 ]; then
		printf "\xff" >$PADDED_BIN
		for ((i=1; i<$PADDED_SIZE; i++))
		do
			printf "\xff" >>$PADDED_BIN
		done
		cat $PADDED_BIN >>$TEMP_IMG
		rm $PADDED_BIN
	fi #if [ $PADDED_SIZE != 0 ]; then

	if [ "$ENABLE_COMPRESS" == "1" ] ; then
		
		if [ "$DFUITD" == "0" ] ; then
			printf "$FILE_PART_READ_CMD %x \$(UpgradeImage) %x %x\n" $DRAM_FATLOAD_BUF_ADDR $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $_TEMP_IMAGE_COMPRESSED_SIZE>>$SCRIPT_FILE
			printf "mscompress7 d 0 %x %x %x\n" $DRAM_FATLOAD_BUF_ADDR $_TEMP_IMAGE_COMPRESSED_SIZE $DRAM_DECOMPRESS_BUF_ADDR>>$SCRIPT_FILE
		else
			printf "mscompress7 d 0 %x %x %x\n" $DRAM_BUF_ADDR $_TEMP_IMAGE_COMPRESSED_SIZE $DRAM_DECOMPRESS_BUF_ADDR>>$SCRIPT_FILE
		fi
		
		if [ "$SN_FS" == "UBIFS" ] || [ "$SN_FS" == "K2SQFS" ]; then
		        printf "$CMD_NAND_ERASE_PART $_TEMP_PARTITION_NAME\n" >>$SCRIPT_FILE
		 	printf "$CMD_FLASH_WRITE %x $_TEMP_PARTITION_NAME %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE
		else
	                printf "$CMD_FLASH_WRITE %x $_TEMP_PARTITION_NAME 0 %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE				        
		fi
		
		if [ "$READBACK_VERIFY" = "1" ] ; then
			if [ "$SN_FS" == "UBIFS" ] || [ "$SN_FS" == "K2SQFS" ]; then
				printf "$CMD_FLASH_READ %x $_TEMP_PARTITION_NAME %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE	                               
			else
                                printf "$CMD_FLASH_READ %x $_TEMP_PARTITION_NAME 0 %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE
			fi
			printf "crc32 %x %x %x #$_TEMP_PARTITION_NAME \n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_SIZE $(($DRAM_DECOMPRESS_BUF_ADDR+$_TEMP_IMAGE_SIZE)) >>$SCRIPT_FILE
			CRC_BIN=$(find -name crc | sed '2,$d')
			cp $_TEMP_IMAGE $_TEMP_IMAGE.tmp
			CRC_VALUE=`$CRC_BIN -a $_TEMP_IMAGE.tmp | grep "CRC32" | awk '{print $3;}'`
			rm $_TEMP_IMAGE.tmp
			#printf "CRC_VALUE=%s \n" $CRC_VALUE
			printf "mw %x %x 4 #$_TEMP_PARTITION_NAME\n" $(($DRAM_DECOMPRESS_BUF_ADDR+$_TEMP_IMAGE_SIZE+4)) $CRC_VALUE >>$SCRIPT_FILE
			printf "cmp.b %x %x 4 #$_TEMP_PARTITION_NAME\n" $(($DRAM_DECOMPRESS_BUF_ADDR+$_TEMP_IMAGE_SIZE)) $(($DRAM_DECOMPRESS_BUF_ADDR+$_TEMP_IMAGE_SIZE+4)) >>$SCRIPT_FILE
		fi

		DRAM_BUF_ADDR=$(($DRAM_BUF_ADDR+$PARTITION_SIZE))
		
	else #if [ "$ENABLE_COMPRESS" = "1" ] ; then
		if [ "$DFUITD" == "0" ] ; then
			printf "$FILE_PART_READ_CMD %x \$(UpgradeImage) %x %x\n" $DRAM_FATLOAD_BUF_ADDR $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE
			printf "$CMD_NAND_ERASE_PART $_TEMP_PARTITION_NAME\n" >>$SCRIPT_FILE
		fi
		printf "$CMD_FLASH_WRITE %x $_TEMP_PARTITION_NAME %x\n" $DRAM_FATLOAD_BUF_ADDR $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE
		DRAM_BUF_ADDR=$(($DRAM_BUF_ADDR+$PARTITION_SIZE))
	fi #if [ "$ENABLE_COMPRESS" = "1" ] ; then

	if [ "$SECURE_BOOT" == "1"  ] ; then
		_TEMP_SIGN_NAME=`printf "%s " $PARTION_SIGN_NAME | awk '{print $'$count';}'`
		_TEMP_SIGN_IMAGE=`printf "%s " $PARTION_SIGN_IMAGE | awk '{print $'$count';}'`
		#printf "_TEMP_SIGN_NAME=$_TEMP_SIGN_NAME\n"
		#printf "_TEMP_SIGN_IMAGE=$_TEMP_SIGN_IMAGE\n"
		cat $_TEMP_SIGN_IMAGE >>$TEMP_IMG
		SIGNATURE_IMG_SIZE=$(stat -c%s $_TEMP_SIGN_IMAGE ) 
		NOT_ALAIN_IMAGE_SIZE=$(($SIGNATURE_IMG_SIZE & 0xfff))
		if [ $NOT_ALAIN_IMAGE_SIZE != 0 ]; then
			PADDED_SIZE=$((0x1000-$NOT_ALAIN_IMAGE_SIZE))
			for ((i=0; i<$PADDED_SIZE; i++))
				do
					printf "\xff" >>$PADDED_BIN
				done
			if [ $PADDED_SIZE != 0 ]; then
				cat $PADDED_BIN >>$TEMP_IMG
				rm $PADDED_BIN
			fi
		fi
		
		if [ "$DFUITD" == "0" ] ; then
			printf "$FILE_PART_READ_CMD %x \$(UpgradeImage) %x %x\n" $DRAM_FATLOAD_BUF_ADDR $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $SIGNATURE_IMG_SIZE>>$SCRIPT_FILE
			printf "store_secure_info $_TEMP_SIGN_NAME %x \n" $DRAM_FATLOAD_BUF_ADDR >> $SCRIPT_FILE
		else
			printf "store_secure_info $_TEMP_SIGN_NAME %x \n" $DRAM_BUF_ADDR >> $SCRIPT_FILE		
		fi
		
		DRAM_BUF_ADDR=$(($DRAM_BUF_ADDR+$SIGNATURE_IMG_SIZE+$PADDED_SIZE))
	fi #if [ "$SECURE_BOOT" == "1"  ] ; then
fi #if [ "$temp" == "Y" ] || [ "$temp" == "y" ]; then

count=$(($count+1))
if [ "$SN_FS" == "UBIFS" ] || [ "$SN_FS" == "K2SQFS" ]; then
    if [ "$UPGRADE_FOR_USB" != "1"  ] ; then
        printf "ubi part UBI\n" >>$SCRIPT_FILE
        if [ "$UPDAT_METHOD" != "rescue" ] ; then
            printf "ubifsmount oad\n" >>$SCRIPT_FILE
        else
            printf "ubifsmount brickbackup\n" >>$SCRIPT_FILE
        fi
    fi
fi
#----------------------------------------
# Process Tee image
#----------------------------------------

#read -p "Update TEE? (y/N)" temp
temp="n"
echo "Update TEE? (y/N)$temp"
if [ "$temp" == "Y" ] || [ "$temp" == "y" ]; then
    count=2

    _TEMP_PARTITION_NAME=`printf "%s " $PARTION_NAME | awk '{print $'$count';}'`
    _TEMP_IMAGE=`printf "%s " $PARTION_IMAGE | awk '{print $'$count';}'`
    _TEMP_IMAGE_SIZE=$(stat -c%s $_TEMP_IMAGE )
    _TEMP_IMAGE_FILE_NAME=$(echo $_TEMP_IMAGE | sed 's\.*/\\g')
    printf "\033[0;36mProcess $_TEMP_PARTITION_NAME ...\033[0m\n"
	if [ "$ENABLE_COMPRESS" = "1" ] ; then
		_TEMP_IMAGE_COMPRESSED=$_TEMP_IMAGE.com
		 ./tools/mscompress7 e 0 $_TEMP_IMAGE $_TEMP_IMAGE_COMPRESSED
		_TEMP_IMAGE_COMPRESSED_SIZE=$(stat -c%s $_TEMP_IMAGE_COMPRESSED )
		PADDED_SIZE=$(($_TEMP_IMAGE_COMPRESSED_SIZE-($_TEMP_IMAGE_COMPRESSED_SIZE&0xFFF0000)))
		if [ $PADDED_SIZE != 0 ]; then
			PADDED_SIZE=$((0x10000-$PADDED_SIZE))
		fi
		PARTITION_SIZE=$(($_TEMP_IMAGE_COMPRESSED_SIZE+$PADDED_SIZE))
		cat $_TEMP_IMAGE_COMPRESSED >>$TEMP_IMG
	else
		_TEMP_IMAGE_COMPRESSED_SIZE=$(stat -c%s $_TEMP_IMAGE)
		PADDED_SIZE=$(($_TEMP_IMAGE_COMPRESSED_SIZE-($_TEMP_IMAGE_COMPRESSED_SIZE&0xFFF0000)))
		if [ $PADDED_SIZE != 0 ]; then
			PADDED_SIZE=$((0x10000-$PADDED_SIZE))
		fi
		PARTITION_SIZE=$(($_TEMP_IMAGE_COMPRESSED_SIZE+$PADDED_SIZE))
		cat $_TEMP_IMAGE >>$TEMP_IMG
	fi #if [ "$ENABLE_COMPRESS" = "1" ] ; then

	#echo "($_TEMP_PARTITION_NAME) padding size : $PADDED_SIZE"

	while [ $PADDED_SIZE -gt $PAD_DUMMY_SIZE ]
	do
		cat $PAD_DUMMY_BIN >>$TEMP_IMG
		PADDED_SIZE=$(($PADDED_SIZE-$PAD_DUMMY_SIZE))
	done

	if [ $PADDED_SIZE != 0 ]; then
		printf "\xff" >$PADDED_BIN
		for ((i=1; i<$PADDED_SIZE; i++))
		do
			printf "\xff" >>$PADDED_BIN
		done
		cat $PADDED_BIN >>$TEMP_IMG
		rm $PADDED_BIN
	fi #if [ $PADDED_SIZE != 0 ]; then

	if [ "$ENABLE_COMPRESS" == "1" ] ; then
		printf "$CMD_NAND_ERASE_PART $_TEMP_PARTITION_NAME\n" >>$SCRIPT_FILE
		if [ "$DFUITD" == "0" ] ; then
			printf "$FILE_PART_READ_CMD %x \$(UpgradeImage) %x %x\n" $DRAM_FATLOAD_BUF_ADDR $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $_TEMP_IMAGE_COMPRESSED_SIZE>>$SCRIPT_FILE
			printf "mscompress7 d 0 %x %x %x\n" $DRAM_FATLOAD_BUF_ADDR $_TEMP_IMAGE_COMPRESSED_SIZE $DRAM_DECOMPRESS_BUF_ADDR>>$SCRIPT_FILE
		else
			printf "mscompress7 d 0 %x %x %x\n" $DRAM_BUF_ADDR $_TEMP_IMAGE_COMPRESSED_SIZE $DRAM_DECOMPRESS_BUF_ADDR>>$SCRIPT_FILE
		fi
		
		
		if [ "$READBACK_VERIFY" = "1" ] ; then
			CRC_BIN=$(find -name crc | sed '2,$d')
			cp $_TEMP_IMAGE $_TEMP_IMAGE.tmp
			CRC_VALUE=`$CRC_BIN -a $_TEMP_IMAGE.tmp | grep "CRC32" | awk '{print $3;}'`
			rm $_TEMP_IMAGE.tmp
		fi
		
		printf "UpdateNuttx %x $_TEMP_PARTITION_NAME %x %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_SIZE $CRC_VALUE >>$SCRIPT_FILE 
		DRAM_BUF_ADDR=$(($DRAM_BUF_ADDR+$PARTITION_SIZE))
		
	else #if [ "$ENABLE_COMPRESS" = "1" ] ; then
		if [ "$DFUITD" == "0" ] ; then
			printf "$FILE_PART_READ_CMD %x \$(UpgradeImage) %x %x\n" $DRAM_FATLOAD_BUF_ADDR $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE
			printf "$CMD_NAND_ERASE_PART $_TEMP_PARTITION_NAME\n" >>$SCRIPT_FILE
		fi
		printf "$CMD_FLASH_WRITE %x $_TEMP_PARTITION_NAME %x\n" $DRAM_FATLOAD_BUF_ADDR $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE
		DRAM_BUF_ADDR=$(($DRAM_BUF_ADDR+$PARTITION_SIZE))
	fi #if [ "$ENABLE_COMPRESS" = "1" ] ; then

	if [ "$SECURE_BOOT" == "1"  ] ; then
		_TEMP_SIGN_NAME=`printf "%s " $PARTION_SIGN_NAME | awk '{print $'$count';}'`
		_TEMP_SIGN_IMAGE=`printf "%s " $PARTION_SIGN_IMAGE | awk '{print $'$count';}'`
		#printf "_TEMP_SIGN_NAME=$_TEMP_SIGN_NAME\n"
		#printf "_TEMP_SIGN_IMAGE=$_TEMP_SIGN_IMAGE\n"
		cat $_TEMP_SIGN_IMAGE >>$TEMP_IMG
		SIGNATURE_IMG_SIZE=$(stat -c%s $_TEMP_SIGN_IMAGE ) 
		NOT_ALAIN_IMAGE_SIZE=$(($SIGNATURE_IMG_SIZE & 0xfff))
		if [ $NOT_ALAIN_IMAGE_SIZE != 0 ]; then
			PADDED_SIZE=$((0x1000-$NOT_ALAIN_IMAGE_SIZE))
			for ((i=0; i<$PADDED_SIZE; i++))
				do
					printf "\xff" >>$PADDED_BIN
				done
			if [ $PADDED_SIZE != 0 ]; then
				cat $PADDED_BIN >>$TEMP_IMG
				rm $PADDED_BIN
			fi
		fi
		
		if [ "$DFUITD" == "0" ] ; then
			printf "$FILE_PART_READ_CMD %x \$(UpgradeImage) %x %x\n" $DRAM_FATLOAD_BUF_ADDR $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $SIGNATURE_IMG_SIZE>>$SCRIPT_FILE
			printf "store_secure_info $_TEMP_SIGN_NAME %x \n" $DRAM_FATLOAD_BUF_ADDR >> $SCRIPT_FILE
		else
			printf "store_secure_info $_TEMP_SIGN_NAME %x \n" $DRAM_BUF_ADDR >> $SCRIPT_FILE		
		fi
		
		DRAM_BUF_ADDR=$(($DRAM_BUF_ADDR+$SIGNATURE_IMG_SIZE+$PADDED_SIZE))
	fi #if [ "$SECURE_BOOT" == "1"  ] ; then

    if [ "$SN_FS" == "UBIFS" ] || [ "$SN_FS" == "K2SQFS" ]; then

        if [ "$UPGRADE_FOR_USB" != "1"  ] ; then
            printf "ubi part UBI\n" >>$SCRIPT_FILE
            if [ "$UPDAT_METHOD" != "rescue" ] ; then
                printf "ubifsmount oad\n" >>$SCRIPT_FILE
            else
                printf "ubifsmount brickbackup\n" >>$SCRIPT_FILE
            fi
        fi
    fi
#-----------------------------------------------------------------
# Add nuttx_config.bin to upgrade image
#-----------------------------------------------------------------
NUTTX_CONFIG=$IMAGE_DIR/nuttx_config.bin
printf "\033[0;36mnuttx_config.bin ...\033[0m\n"
cat $NUTTX_CONFIG >>$TEMP_IMG
NUTTX_CONFIG_SIZE=$(stat -c%s $NUTTX_CONFIG ) 	
NOT_ALAIN_IMAGE_SIZE=$(($NUTTX_CONFIG_SIZE & 0xfff))
if [ $NOT_ALAIN_IMAGE_SIZE != 0 ]; then
	PADDED_SIZE=$((0x1000-$NOT_ALAIN_IMAGE_SIZE))
	for ((i=0; i<$PADDED_SIZE; i++))
		do
			printf "\xff" >>$PADDED_BIN
		done
	if [ $PADDED_SIZE != 0 ]; then
		cat $PADDED_BIN >>$TEMP_IMG
		rm $PADDED_BIN
	fi
fi

if [ "$DFUITD" == "0" ] ; then
	printf "$FILE_PART_READ_CMD %x \$(UpgradeImage) %x %x\n" $DRAM_FATLOAD_BUF_ADDR $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $NUTTX_CONFIG_SIZE>>$SCRIPT_FILE
	printf "store_nuttx_config NuttxConfig 0x%x\n" $DRAM_FATLOAD_BUF_ADDR>> $SCRIPT_FILE
else
	printf "store_nuttx_config NuttxConfig 0x%x\n" $DRAM_BUF_ADDR>> $SCRIPT_FILE
fi
DRAM_BUF_ADDR=$(($DRAM_BUF_ADDR+$NUTTX_CONFIG_SIZE+$PADDED_SIZE))
	
fi #if [ "$temp" == "Y" ] || [ "$temp" == "y" ]; then
count=$(($count+1))

if [ "$FORCE_OVERWRITE" == "1" ] ; then
    outline=`cat $SCRIPT_FILE | grep -v "^ *#" | grep "ubi" | grep "create" | grep "RFS" `
    if [ "$outline" != "" ]; then
        sed -i '/ubi create RFS/ i ubi remove RFS' $SCRIPT_FILE
    fi

    outline=`cat $SCRIPT_FILE | grep -v "^ *#" | grep "ubi" | grep "create" | grep "MSLIB" `
    if [ "$outline" != "" ]; then
        sed -i 'ubi create RFS/ i ubi remove MSLIB' $SCRIPT_FILE
    fi

    outline=`cat $SCRIPT_FILE | grep -v "^ *#" | grep "ubi" | grep "create" | grep "CONFIG" `
    if [ "$outline" != "" ]; then
        sed -i '/ubi create RFS/ i ubi remove CONFIG' $SCRIPT_FILE
    fi

    outline=`cat $SCRIPT_FILE | grep -v "^ *#" | grep "ubi" | grep "create" | grep "APP" `
    if [ "$outline" != "" ]; then
        sed -i '/ubi create RFS/ i ubi remove APP' $SCRIPT_FILE
    fi

    outline=`cat $SCRIPT_FILE | grep -v "^ *#" | grep "ubi" | grep "create" | grep "customer" `
    if [ "$outline" != "" ]; then
        sed -i '/ubi create RFS/ i ubi remove customer' $SCRIPT_FILE
    fi

    outline=`cat $SCRIPT_FILE | grep -v "^ *#" | grep "ubi" | grep "create" | grep "GINGA" `
    if [ "$outline" != "" ]; then
        sed -i '/ubi create RFS/ i ubi remove GINGA' $SCRIPT_FILE
    fi

    if [ "$CHIP" != "nikon.lite" ] && [ "$CHIP" != "nugget" ] ; then
        outline=`cat $SCRIPT_FILE | grep -v "^ *#" | grep "ubi" | grep "create" | grep "customerbackup" `
        if [ "$outline" != "" ]; then
            sed -i '/ubi create RFS/ i ubi remove customerbackup' $SCRIPT_FILE
        fi

        outline=`cat $SCRIPT_FILE | grep -v "^ *#" | grep "ubi" | grep "create" | grep "certificate" `
        if [ "$outline" != "" ]; then
            sed -i '/ubi create certificate*/ i ubi remove certificate' $SCRIPT_FILE
        fi
    fi

    outline=`cat $SCRIPT_FILE | grep -v "^ *#" | grep "ubi" | grep "create" | grep "oad" `
    if [ "$outline" != "" ]; then
        sed -i '/ubi create RFS/ i ubi remove oad' $SCRIPT_FILE
    fi

fi

#----------------------------------------
# Process other images
# ex:rootfs.ubifs, mslib.ubifs...etc
#----------------------------------------
count=3
PARTION_NUM=`echo $PARTION_NAME | wc -w`
until [ "$count" == "$(($PARTION_NUM+1))" ]
do
	_TEMP_PARTITION_NAME=`printf "%s " $PARTION_NAME | awk '{print $'$count';}'`
	_TEMP_IMAGE=`printf "%s " $PARTION_IMAGE | awk '{print $'$count';}'`
	_TEMP_FS=`printf "%s " $PARTION_FS | awk '{print $'$count';}'`
	_TEMP_IMAGE_SIZE=$(stat -c%s $_TEMP_IMAGE )
	_TEMP_IMAGE_FILE_NAME=$(echo $_TEMP_IMAGE | sed 's\.*/\\g')
	
	#printf "_TEMP_PARTITION_NAME=$_TEMP_PARTITION_NAME\n"
	#if [ "$SN_FS" == "EXT4" ] ; then
	#	printf "_TEMP_PARTITION_OFFSET=$_TEMP_PARTITION_OFFSET\n"
	#fi
	#printf "_TEMP_IMAGE=$_TEMP_IMAGE\n"
	#printf "_TEMP_IMAGE_SIZE=$_TEMP_IMAGE_SIZE\n"
	#printf "_TEMP_IMAGE_FILE_NAME=$_TEMP_IMAGE_FILE_NAME\n"
	if [ "$FULL_UPGRADE" == "1"  ] ; then
		temp="Y"
	else
#		printf "Update1 $_TEMP_PARTITION_NAME? (y/N)"  
#		read temp
		temp="Y"
		echo "Update1 $_TEMP_PARTITION_NAME? (y/N)$temp"  
	fi
	
    if [ "$_TEMP_PARTITION_NAME" == "RTPM" ] ; then
#		printf "Update2 $_TEMP_PARTITION_NAME? (y/N)"  
#		read temp
		temp="Y"
		echo "Update1 $_TEMP_PARTITION_NAME? (y/N)$temp"  
	fi
	if [ "$temp" == "Y" ] || [ "$temp" == "y" ]; then
		printf "\033[0;36mProcess $_TEMP_PARTITION_NAME ...\033[0m\n"

		if [ "$SN_FS" == "UBIFS" ] && [ "$_TEMP_FS" == "sqfs" ] ; then
			SQUSHFS_ENABLE=1
		elif [ "$_TEMP_PARTITION_NAME" == "KL" ] || [ "$_TEMP_PARTITION_NAME" == "RTPM" ] ; then
			SQUSHFS_ENABLE=1
		else
			SQUSHFS_ENABLE=0
		fi
		
		if [ "$SQUSHFS_ENABLE" == "1" ] ; then
			if [ "$ENABLE_COMPRESS" = "1" ] ; then
				_TEMP_IMAGE_COMPRESSED=$_TEMP_IMAGE.com
				./tools/mscompress7 e 0 $_TEMP_IMAGE $_TEMP_IMAGE_COMPRESSED
				_TEMP_IMAGE_COMPRESSED_SIZE=$(stat -c%s $_TEMP_IMAGE_COMPRESSED )
				PADDED_SIZE=$(($_TEMP_IMAGE_COMPRESSED_SIZE-($_TEMP_IMAGE_COMPRESSED_SIZE&0xFFF0000)))
				if [ $PADDED_SIZE != 0 ]; then
					PADDED_SIZE=$((0x10000-$PADDED_SIZE))
				fi
				PARTITION_SIZE=$(($_TEMP_IMAGE_COMPRESSED_SIZE+$PADDED_SIZE))
				cat $_TEMP_IMAGE_COMPRESSED >>$TEMP_IMG
			else
				_TEMP_IMAGE_COMPRESSED_SIZE=$(stat -c%s $_TEMP_IMAGE)
				PADDED_SIZE=$(($_TEMP_IMAGE_COMPRESSED_SIZE-($_TEMP_IMAGE_COMPRESSED_SIZE&0xFFF0000)))
				if [ $PADDED_SIZE != 0 ]; then
					PADDED_SIZE=$((0x10000-$PADDED_SIZE))
				fi
				PARTITION_SIZE=$(($_TEMP_IMAGE_COMPRESSED_SIZE+$PADDED_SIZE))
				cat $_TEMP_IMAGE >>$TEMP_IMG
			fi #if [ "$ENABLE_COMPRESS" = "1" ] ; then

			#echo "($_TEMP_PARTITION_NAME) padding size : $PADDED_SIZE"

			while [ $PADDED_SIZE -gt $PAD_DUMMY_SIZE ]
			do
				cat $PAD_DUMMY_BIN >>$TEMP_IMG
				PADDED_SIZE=$(($PADDED_SIZE-$PAD_DUMMY_SIZE))
			done

			if [ $PADDED_SIZE != 0 ]; then
				printf "\xff" >$PADDED_BIN
				for ((i=1; i<$PADDED_SIZE; i++))
				do
					printf "\xff" >>$PADDED_BIN
				done
				cat $PADDED_BIN >>$TEMP_IMG
				rm $PADDED_BIN
			fi #if [ $PADDED_SIZE != 0 ]; then
			if [ "$CHIP" = "nugget" ] || [ "$CHIP" = "nikon.lite" ] ; then
				if [ "$_TEMP_PARTITION_NAME" != "certificate" ]; then
					if [ "$UPDAT_METHOD" != "rescue" ] ; then
						printf "ubi part UBI\n" >>$SCRIPT_FILE
							if [ "$UPGRADE_FOR_USB" == "0" ] ; then
								printf "ubifsmount oad\n" >>$SCRIPT_FILE
							fi
					fi
				fi
			fi
			if [ "$ENABLE_COMPRESS" == "1" ] ; then
		
				if [ "$DFUITD" == "0" ] ; then
					printf "$FILE_PART_READ_CMD %x \$(UpgradeImage) %x %x\n" $DRAM_FATLOAD_BUF_ADDR $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $_TEMP_IMAGE_COMPRESSED_SIZE>>$SCRIPT_FILE
					printf "mscompress7 d 0 %x %x %x\n" $DRAM_FATLOAD_BUF_ADDR $_TEMP_IMAGE_COMPRESSED_SIZE $DRAM_DECOMPRESS_BUF_ADDR>>$SCRIPT_FILE
				else
					printf "mscompress7 d 0 %x %x %x\n" $DRAM_BUF_ADDR $_TEMP_IMAGE_COMPRESSED_SIZE $DRAM_DECOMPRESS_BUF_ADDR>>$SCRIPT_FILE
				fi
		
				if [ "$SN_FS" == "UBIFS" ] || [ "$SN_FS" == "K2SQFS" ]; then
					printf "$CMD_NAND_ERASE_PART $_TEMP_PARTITION_NAME\n" >>$SCRIPT_FILE
					printf "$CMD_FLASH_WRITE %x $_TEMP_PARTITION_NAME %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE
				else
						printf "$CMD_FLASH_WRITE %x $_TEMP_PARTITION_NAME 0 %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE				        
				fi
		
				if [ "$READBACK_VERIFY" = "1" ] ; then
					if [ "$SN_FS" == "UBIFS" ] || [ "$SN_FS" == "K2SQFS" ]; then
						printf "$CMD_FLASH_READ %x $_TEMP_PARTITION_NAME %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE	                               
					else
						printf "$CMD_FLASH_READ %x $_TEMP_PARTITION_NAME 0 %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE
					fi
					printf "crc32 %x %x %x #$_TEMP_PARTITION_NAME \n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_SIZE $(($DRAM_DECOMPRESS_BUF_ADDR+$_TEMP_IMAGE_SIZE)) >>$SCRIPT_FILE
					CRC_BIN=$(find -name crc | sed '2,$d')
					cp $_TEMP_IMAGE $_TEMP_IMAGE.tmp
					CRC_VALUE=`$CRC_BIN -a $_TEMP_IMAGE.tmp | grep "CRC32" | awk '{print $3;}'`
					rm $_TEMP_IMAGE.tmp
					#printf "CRC_VALUE=%s \n" $CRC_VALUE
					printf "mw %x %x 4 #$_TEMP_PARTITION_NAME\n" $(($DRAM_DECOMPRESS_BUF_ADDR+$_TEMP_IMAGE_SIZE+4)) $CRC_VALUE >>$SCRIPT_FILE
					printf "cmp.b %x %x 4 #$_TEMP_PARTITION_NAME\n" $(($DRAM_DECOMPRESS_BUF_ADDR+$_TEMP_IMAGE_SIZE)) $(($DRAM_DECOMPRESS_BUF_ADDR+$_TEMP_IMAGE_SIZE+4)) >>$SCRIPT_FILE
				fi

				DRAM_BUF_ADDR=$(($DRAM_BUF_ADDR+$PARTITION_SIZE))
		
			else #if [ "$ENABLE_COMPRESS" = "1" ] ; then
				if [ "$DFUITD" == "0" ] ; then
					printf "$FILE_PART_READ_CMD 80400000 \$(UpgradeImage) %x %x\n" $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE
					printf "$CMD_NAND_ERASE_PART $_TEMP_PARTITION_NAME\n" >>$SCRIPT_FILE
				fi
				printf "$CMD_FLASH_WRITE 80400000 $_TEMP_PARTITION_NAME %x\n" $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE
				DRAM_BUF_ADDR=$(($DRAM_BUF_ADDR+$PARTITION_SIZE))
			fi #if [ "$ENABLE_COMPRESS" = "1" ] ; then

			if [ "$SECURE_BOOT" == "1"  ] ; then
				if [ "$_TEMP_PARTITION_NAME" != "RTPM" ] ; then
					_TEMP_SIGN_NAME=`printf "%s " $PARTION_SIGN_NAME | awk '{print $'$count';}'`
					_TEMP_SIGN_IMAGE=`printf "%s " $PARTION_SIGN_IMAGE | awk '{print $'$count';}'`
					#printf "_TEMP_SIGN_NAME=$_TEMP_SIGN_NAME\n"
					#printf "_TEMP_SIGN_IMAGE=$_TEMP_SIGN_IMAGE\n"
					cat $_TEMP_SIGN_IMAGE >>$TEMP_IMG
					SIGNATURE_IMG_SIZE=$(stat -c%s $_TEMP_SIGN_IMAGE ) 
					NOT_ALAIN_IMAGE_SIZE=$(($SIGNATURE_IMG_SIZE & 0xfff))
					if [ $NOT_ALAIN_IMAGE_SIZE != 0 ]; then
						PADDED_SIZE=$((0x1000-$NOT_ALAIN_IMAGE_SIZE))
						for ((i=0; i<$PADDED_SIZE; i++))
							do
								printf "\xff" >>$PADDED_BIN
							done
						if [ $PADDED_SIZE != 0 ]; then
							cat $PADDED_BIN >>$TEMP_IMG
							rm $PADDED_BIN
						fi
					fi
		
					if [ "$DFUITD" == "0" ] ; then
						printf "$FILE_PART_READ_CMD %x \$(UpgradeImage) %x %x\n" $DRAM_FATLOAD_BUF_ADDR $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $SIGNATURE_IMG_SIZE>>$SCRIPT_FILE
						printf "store_secure_info $_TEMP_SIGN_NAME %x \n" $DRAM_FATLOAD_BUF_ADDR >> $SCRIPT_FILE
					else
						printf "store_secure_info $_TEMP_SIGN_NAME %x \n" $DRAM_BUF_ADDR >> $SCRIPT_FILE		
					fi
		
					DRAM_BUF_ADDR=$(($DRAM_BUF_ADDR+$SIGNATURE_IMG_SIZE+$PADDED_SIZE))
				fi
			fi #if [ "$SECURE_BOOT" == "1"  ] ; then
		else #if [ "$SQUSHFS_ENABLE" == "1" ] ; then
			if [ "$_TEMP_PARTITION_NAME" = "MSLIB" ] || [ "$_TEMP_PARTITION_NAME" = "RFS" ] || [ "$_TEMP_PARTITION_NAME" = "APP" ] || [ "$_TEMP_PARTITION_NAME" = "CONFIG" ];then 
				split -d -a 2 -b "$MAX_FILE_SIZE"m $_TEMP_IMAGE $_TEMP_IMAGE."SW".
			
				SEGMENT_NUM=`ls -l $_TEMP_IMAGE."SW".*|wc -l`
				_LAST_IMAGE_PART_SIZE=$(stat -c%s $_TEMP_IMAGE."SW".0$(($SEGMENT_NUM-1)) );

				if [ "$(($_LAST_IMAGE_PART_SIZE <= $MIN_FILE_SIZE_HEX))" == "1" ] ; then
					cat $_TEMP_IMAGE."SW".0$(($SEGMENT_NUM-1)) >> $_TEMP_IMAGE."SW".0$(($SEGMENT_NUM-2)) 
					temp=$(($MAX_FILE_SIZE-1))
					split -a 2 -b "$temp"m $_TEMP_IMAGE."SW".0$(($SEGMENT_NUM-2)) $_TEMP_IMAGE."SW".
					rm $_TEMP_IMAGE."SW".0$(($SEGMENT_NUM-1)) 
					rm $_TEMP_IMAGE."SW".0$(($SEGMENT_NUM-2)) 
					mv $_TEMP_IMAGE."SW".aa $_TEMP_IMAGE."SW".0$(($SEGMENT_NUM-2))
					mv $_TEMP_IMAGE."SW".ab $_TEMP_IMAGE."SW".0$(($SEGMENT_NUM-1))
				fi
			
			else
				cp -f $_TEMP_IMAGE $_TEMP_IMAGE."SW".00
			fi
		
			BRK=0
			SUFFIX="0"
			PARTIAL_READ_OFFSET=0;
		
			_TEMP_IMAGE_PART_SIZE=$(stat -c%s $_TEMP_IMAGE."SW".00 );
			if test "$_TEMP_IMAGE_PART_SIZE" -gt "$MAX_FILE_SIZE_HEX" 
			then  #"$_TEMP_IMAGE_PART_SIZE" > "$MAX_FILE_SIZE_HEX"
				printf "[Error][Error][Error][Error]\n"
				exit
			fi
			_TEMP_PARTITION_OFFSET=0;
			_TEMP_PARTITION_BLK_OFFSET=$(($_TEMP_PARTITION_OFFSET/512))
			while [ "$BRK" == "0" ]
			do
				SUFFIX_LENGTH=`expr length "$SUFFIX"`
				if [ "$SUFFIX_LENGTH" = "1" ] ; then
					_TEMP_IMAGE_PART="$_TEMP_IMAGE"."SW".0"$SUFFIX"
				else
					_TEMP_IMAGE_PART="$_TEMP_IMAGE"."SW"."$SUFFIX"
				fi
				
				if [ -e "$_TEMP_IMAGE_PART" ] ; then
					_TEMP_IMAGE_PART_SIZE=$(stat -c%s "$_TEMP_IMAGE_PART" )
					if [ "$ENABLE_COMPRESS" = "1" ] ; then
						
						_TEMP_IMAGE_PART_COMPRESSED=$_TEMP_IMAGE_PART.com
						 ./tools/mscompress7 e 0 $_TEMP_IMAGE_PART $_TEMP_IMAGE_PART_COMPRESSED
						_TEMP_IMAGE_PART_COMPRESSED_SIZE=$(stat -c%s $_TEMP_IMAGE_PART_COMPRESSED )
						PADDED_SIZE=$(($_TEMP_IMAGE_PART_COMPRESSED_SIZE-($_TEMP_IMAGE_PART_COMPRESSED_SIZE&0xFFF0000)))
						if [ $PADDED_SIZE != 0 ]; then
							PADDED_SIZE=$((0x10000-$PADDED_SIZE))
						fi
						PARTITION_SIZE=$(($_TEMP_IMAGE_PART_COMPRESSED_SIZE+$PADDED_SIZE))
						cat $_TEMP_IMAGE_PART_COMPRESSED >>$TEMP_IMG
					else
						PADDED_SIZE=$(($_TEMP_IMAGE_PART_SIZE-($_TEMP_IMAGE_PART_SIZE&0xFFF0000)))
						if [ $PADDED_SIZE != 0 ]; then
							PADDED_SIZE=$((0x10000-$PADDED_SIZE))
						fi
						PARTITION_SIZE=$(($PADDED_SIZE+$_TEMP_IMAGE_PART_SIZE))
						cat "$_TEMP_IMAGE_PART" >>$TEMP_IMG
					fi #if [ "$ENABLE_COMPRESS" = "1" ] ; then
					
					#printf " \033[0;31m($_TEMP_PARTITION_NAME) \033[0m padding size : $PADDED_SIZE"
				   
					while [ $PADDED_SIZE -gt $PAD_DUMMY_SIZE ]
					do
						cat $PAD_DUMMY_BIN >>$TEMP_IMG
						PADDED_SIZE=$(($PADDED_SIZE-$PAD_DUMMY_SIZE))
					done
				
					if [ $PADDED_SIZE != 0 ]; then
						printf "\xff" >$PADDED_BIN
						for ((i=1; i<$PADDED_SIZE; i++))
						do
							printf "\xff" >>$PADDED_BIN
						done
						cat $PADDED_BIN >>$TEMP_IMG
						rm $PADDED_BIN
					fi
					if [ "$SUFFIX" = "0" ] ; then
						printf "ubi part UBI\n">>$SCRIPT_FILE 
						if [ "$UPGRADE_FOR_USB" != "1"  ] ; then
							if [ "$UPDAT_METHOD" = "rescue" ] ; then
								printf "ubifsmount brickbackup\n" >>$SCRIPT_FILE
							else
								printf "ubifsmount oad\n" >>$SCRIPT_FILE
							fi
						fi
					fi
					if [ "$ENABLE_COMPRESS" = "1" ] ; then
						if [ "$DFUITD" == "0" ] ; then
							printf "$FILE_PART_READ_CMD %x \$(UpgradeImage) %x %x\n" $DRAM_FATLOAD_BUF_ADDR $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $_TEMP_IMAGE_PART_COMPRESSED_SIZE>>$SCRIPT_FILE
							printf "mscompress7 d 0 %x %x %x\n" $DRAM_FATLOAD_BUF_ADDR $_TEMP_IMAGE_PART_COMPRESSED_SIZE $DRAM_DECOMPRESS_BUF_ADDR>>$SCRIPT_FILE
						else
							printf "mscompress7 d 0 %x %x %x\n" $DRAM_BUF_ADDR $_TEMP_IMAGE_PART_COMPRESSED_SIZE $DRAM_DECOMPRESS_BUF_ADDR>>$SCRIPT_FILE
						fi

						if [ "$_TEMP_PARTITION_NAME" = "certificate" ] ; then ## This part is temp. When we finish SN refine partition, we will remove this section.
							if [ "$PROJ_MODE" = "europe_dtv" ] ; then
								if [ "$CHIP" = "a5" ] || [ "$CHIP" = "t12" ] || [ "$CHIP" = "a1" ]  || [ "$CHIP" = "a7" ] || [ "$CHIP" = "a3" ] || [ "$CHIP" = "eagle" ] || [ "$CHIP" = "eiffel" ] || [ "$CHIP" = "nugget" ]; then
									if [ "$SN_FS" != "EXT4" ] ; then
										printf "ubi part UBIRO\n" >>$SCRIPT_FILE
									fi
								fi
							fi
							if [ "$PROJ_MODE" = "isdb" ] ; then
								if [ "$CHIP" = "t12" ] || [ "$CHIP" = "nugget" ] ; then
									printf "ubi part UBIRO\n" >>$SCRIPT_FILE
								fi
							fi
							if [ "$PROJ_MODE" = "atsc" ] ; then
								printf "ubi part UBIRO\n" >>$SCRIPT_FILE
							fi
							if [ "$PROJ_MODE" = "china" ] ; then
								if [ "$CHIP" = "nikon.lite" ] ; then
									printf "ubi part UBIRO\n" >>$SCRIPT_FILE
								fi
							fi
						fi #if [ "$_TEMP_PARTITION_NAME" = "certificate" ] ; then 
			
						if [ "$SUFFIX" = "0" ] ; then
							if [ "$SN_FS" == "EXT4" ] ; then
								printf "$CMD_FLASH_WRITE %x $_TEMP_PARTITION_NAME %x %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_PARTITION_BLK_OFFSET $_TEMP_IMAGE_PART_SIZE >>$SCRIPT_FILE
								printf "$CMD_FLASH_READ %x $_TEMP_PARTITION_NAME %x %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_PARTITION_BLK_OFFSET $_TEMP_IMAGE_PART_SIZE >>$TEMP_SCRIPT_FILE
								_TEMP_PARTITION_OFFSET=$(($_TEMP_PARTITION_OFFSET+$_TEMP_IMAGE_PART_SIZE))
								_TEMP_PARTITION_BLK_OFFSET=$(($_TEMP_PARTITION_OFFSET/512))
							elif [ "$SN_FS" == "SQUSHFS" ] ; then
								printf "$CMD_FLASH_WRITE %x $_TEMP_PARTITION_NAME 0 %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE
								printf "$CMD_FLASH_READ %x $_TEMP_PARTITION_NAME 0 %x\n" $DRAM_DECOMPRESS_BUF_ADDR $PARTIAL_READ_OFFSET >$TEMP_SCRIPT_FILE
							elif [ "$SN_FS" == "K2SQFS" ] ; then
								if [ "$_TEMP_PARTITION_NAME" == "RFS" ] || [ "$_TEMP_PARTITION_NAME" == "APP" ] || [ "$_TEMP_PARTITION_NAME" == "MSLIB" ] ;then
									printf "$CMD_NAND_ERASE_PART $_TEMP_PARTITION_NAME\n" >>$SCRIPT_FILE
									printf "$NAND_SQFS_CMD_FLASH_WRITE %x $_TEMP_PARTITION_NAME %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE
								else
									printf "ubi write %x $_TEMP_PARTITION_NAME %x %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_PART_SIZE $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE
									printf "ubi partial_read %x $_TEMP_PARTITION_NAME %x %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_PART_SIZE $PARTIAL_READ_OFFSET >$TEMP_SCRIPT_FILE
								fi
							else
								if [ "$CHIP" = "nugget" ] || [ "$CHIP" = "nikon.lite" ] ; then
									if [ "$_TEMP_PARTITION_NAME" != "certificate" ]; then
										if [ "$UPDAT_METHOD" != "rescue" ] ; then
											printf "ubi part UBI\n" >>$SCRIPT_FILE
											if [ "$UPGRADE_FOR_USB" == "0" ] ; then
												printf "ubifsmount oad\n" >>$SCRIPT_FILE
											fi
										fi
									fi
								fi
								printf "ubi write %x $_TEMP_PARTITION_NAME %x %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_PART_SIZE $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE
								printf "ubi partial_read %x $_TEMP_PARTITION_NAME %x %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_PART_SIZE $PARTIAL_READ_OFFSET >$TEMP_SCRIPT_FILE
							fi
						else
							if [ "$SN_FS" == "EXT4" ] ; then
								printf "$CMD_FLASH_WRITE %x $_TEMP_PARTITION_NAME %x %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_PARTITION_BLK_OFFSET $_TEMP_IMAGE_PART_SIZE>>$SCRIPT_FILE
								printf "$CMD_FLASH_READ %x $_TEMP_PARTITION_NAME %x %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_PARTITION_BLK_OFFSET $_TEMP_IMAGE_PART_SIZE >>$TEMP_SCRIPT_FILE
								_TEMP_PARTITION_OFFSET=$(($_TEMP_PARTITION_OFFSET+$_TEMP_IMAGE_PART_SIZE))
								_TEMP_PARTITION_BLK_OFFSET=$(($_TEMP_PARTITION_OFFSET/512))
							else
								if [ "$CHIP" = "nugget" ] || [ "$CHIP" = "nikon.lite" ] ; then
									if [ "$_TEMP_PARTITION_NAME" != "certificate" ] ; then
										printf "ubi part UBI\n" >>$SCRIPT_FILE
										if [ "$UPGRADE_FOR_USB" == "0" ] ; then
											printf "ubifsmount oad\n" >>$SCRIPT_FILE
										fi
									fi
								fi
								printf "ubi write_cont %x $_TEMP_PARTITION_NAME %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_PART_SIZE>>$SCRIPT_FILE
								printf "ubi partial_read %x $_TEMP_PARTITION_NAME %x %x\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_PART_SIZE $PARTIAL_READ_OFFSET >>$TEMP_SCRIPT_FILE
							fi
						fi
						
						printf "crc32 %x %x %x #$_TEMP_PARTITION_NAME\n" $DRAM_DECOMPRESS_BUF_ADDR $_TEMP_IMAGE_PART_SIZE $(($DRAM_DECOMPRESS_BUF_ADDR+$_TEMP_IMAGE_SIZE)) >>$TEMP_SCRIPT_FILE
						CRC_BIN=$(find -name crc | sed '2,$d')
						cp $_TEMP_IMAGE_PART $_TEMP_IMAGE_PART.tmp
						CRC_VALUE=`$CRC_BIN -a $_TEMP_IMAGE_PART.tmp | grep "CRC32" | awk '{print $3;}'`
						rm $_TEMP_IMAGE_PART.tmp
						#printf "CRC_VALUE=%s \n" $CRC_VALUE
						printf "mw %x %x 4 #$_TEMP_PARTITION_NAME\n" $(($DRAM_DECOMPRESS_BUF_ADDR+$_TEMP_IMAGE_SIZE+4)) $CRC_VALUE >>$TEMP_SCRIPT_FILE
						printf "cmp.b %x %x 4 #$_TEMP_PARTITION_NAME\n" $(($DRAM_DECOMPRESS_BUF_ADDR+$_TEMP_IMAGE_SIZE)) $(($DRAM_DECOMPRESS_BUF_ADDR+$_TEMP_IMAGE_SIZE+4)) >>$TEMP_SCRIPT_FILE
						PARTIAL_READ_OFFSET=$(($PARTIAL_READ_OFFSET+$_TEMP_IMAGE_PART_SIZE))			
					else #if [ "$ENABLE_COMPRESS" = "1" ] ; then
						if [ "$_TEMP_PARTITION_NAME" = "certificate" ] ; then
							printf "ubi part UBIRO\n" >>$SCRIPT_FILE
						fi
						printf "$FILE_PART_READ_CMD 80400000 \$(UpgradeImage) %x %x\n" $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $_TEMP_IMAGE_PART_SIZE>>$SCRIPT_FILE
						printf "$FILE_PART_READ_CMD 80400000 \$(UpgradeImage) %x %x\n" $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $_TEMP_IMAGE_PART_SIZE>>$TEMP_SCRIPT_FILE
						if [ "$SUFFIX" = "0" ] ; then
							printf "ubi write 80400000 $_TEMP_PARTITION_NAME %x %x\n" $_TEMP_IMAGE_PART_SIZE $_TEMP_IMAGE_SIZE>>$SCRIPT_FILE
							printf "ubi write 80400000 $_TEMP_PARTITION_NAME %x %x\n" $_TEMP_IMAGE_PART_SIZE $_TEMP_IMAGE_SIZE>>$TEMP_SCRIPT_FILE
						else
							printf "ubi write_cont 80400000 $_TEMP_PARTITION_NAME %x\n" $_TEMP_IMAGE_PART_SIZE>>$SCRIPT_FILE
							printf "ubi write_cont 80400000 $_TEMP_PARTITION_NAME %x\n" $_TEMP_IMAGE_PART_SIZE>>$TEMP_SCRIPT_FILE
						fi
					fi #if [ "$ENABLE_COMPRESS" = "1" ] ; then
					
					DRAM_BUF_ADDR=$(($DRAM_BUF_ADDR+$PARTITION_SIZE))
					SUFFIX=$(($SUFFIX+1))
				else #if [ -e "$_TEMP_IMAGE_PART" ] ; then
					BRK=1
					rm -f $_TEMP_IMAGE."SW".[0-9][0-9]*
				fi #if [ -e "$_TEMP_IMAGE_PART" ] ; then
			done #while [ "$BRK" == "0" ]

			if [ "$READBACK_VERIFY" = "1" ] ; then
				cat $TEMP_SCRIPT_FILE >>$SCRIPT_FILE
				rm $TEMP_SCRIPT_FILE
			fi	
			
			if [ "$_TEMP_PARTITION_NAME" = "certificate" ] ; then ## This part is temp. We will remove this section after we complete "SN refine partition"
				if [ "$PROJ_MODE" = "europe_dtv" ] ; then
					if [ "$CHIP" = "t12" ] || [ "$CHIP" = "a1" ]  || [ "$CHIP" = "a7" ] || [ "$CHIP" = "a3" ] || [ "$CHIP" = "eagle" ] || [ "$CHIP" = "nugget" ]; then
						if [ "$SN_FS" != "EXT4" ] ; then
							printf "ubi part UBI\n" >>$SCRIPT_FILE
						fi
					fi
				fi
				if [ "$PROJ_MODE" = "isdb" ] ; then
					if [ "$CHIP" = "t12" ] ; then
						printf "ubi part UBI\n" >>$SCRIPT_FILE
					fi
				fi
			fi #if [ "$_TEMP_PARTITION_NAME" = "certificate" ] ; then 
			
			if [ "$SECURE_BOOT" == "1"  ] ; then
				_TEMP_SIGN_NAME=`printf "%s " $PARTION_SIGN_NAME | awk '{print $'$count';}'`
				_TEMP_SIGN_IMAGE=`printf "%s " $PARTION_SIGN_IMAGE | awk '{print $'$count';}'`
				#printf "_TEMP_SIGN_NAME=$_TEMP_SIGN_NAME\n"
				#printf "_TEMP_SIGN_IMAGE=$_TEMP_SIGN_IMAGE\n"
				
				if [ "$_TEMP_SIGN_NAME" != "none"  ] ; then
					cat $_TEMP_SIGN_IMAGE >>$TEMP_IMG
					SIGNATURE_IMG_SIZE=$(stat -c%s $_TEMP_SIGN_IMAGE ) 
					NOT_ALAIN_IMAGE_SIZE=$(($SIGNATURE_IMG_SIZE & 0xfff))
					if [ $NOT_ALAIN_IMAGE_SIZE != 0 ]; then
						PADDED_SIZE=$((0x1000-$NOT_ALAIN_IMAGE_SIZE))
						for ((i=0; i<$PADDED_SIZE; i++))
						do
							printf "\xff" >>$PADDED_BIN
						done
						
						if [ $PADDED_SIZE != 0 ]; then
							cat $PADDED_BIN >>$TEMP_IMG
							rm $PADDED_BIN
						fi
					fi #if [ $NOT_ALAIN_IMAGE_SIZE != 0 ]; then
					
					if [ "$DFUITD" == "0" ] ; then
						printf "$FILE_PART_READ_CMD %x \$(UpgradeImage) %x %x\n" $DRAM_FATLOAD_BUF_ADDR $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $SIGNATURE_IMG_SIZE>>$SCRIPT_FILE
						printf "store_secure_info $_TEMP_SIGN_NAME %x \n" $DRAM_FATLOAD_BUF_ADDR >> $SCRIPT_FILE
					else
						printf "store_secure_info $_TEMP_SIGN_NAME %x \n" $DRAM_BUF_ADDR >> $SCRIPT_FILE
					fi
					DRAM_BUF_ADDR=$(($DRAM_BUF_ADDR+$SIGNATURE_IMG_SIZE+$PADDED_SIZE))
				fi #if [ "$_TEMP_SIGN_NAME" != "none"  ] ; then
			fi #if [ "$SECURE_BOOT" == "1"  ] ; then
		fi #if [ "$SQUSHFS_ENABLE" == "1" ] ; then
	fi #if [ "$temp" == "Y" ] || [ "$temp" == "y" ]; then
	count=$(($count+1))
done #until [ "$count" == "$(($PARTION_NUM+1))" ] 

#-----------------------------------------------------------------
# Add mboot.bin to final upgrade image
#-----------------------------------------------------------------
if [ "$MBOOT_UPGRADE" = "1" ] ; then
	printf "\033[0;36mProcess Mboot.bin ...\033[0m\n"
	cat $MBOOT_IMG >>$TEMP_IMG
	MBOOT_SIZE=$(stat -c%s $MBOOT_IMG ) 	
	NOT_ALAIN_IMAGE_SIZE=$(($MBOOT_SIZE & 0xfff))
	if [ $NOT_ALAIN_IMAGE_SIZE != 0 ]; then
		PADDED_SIZE=$((0x1000-$NOT_ALAIN_IMAGE_SIZE))
		for ((i=0; i<$PADDED_SIZE; i++))
			do
				printf "\xff" >>$PADDED_BIN
			done
		if [ $PADDED_SIZE != 0 ]; then
			cat $PADDED_BIN >>$TEMP_IMG
			rm $PADDED_BIN
		fi
	fi
	
	if [ "$DFUITD" == "0" ] ; then
		printf "$FILE_PART_READ_CMD %x \$(UpgradeImage) %x %x\n" $DRAM_FATLOAD_BUF_ADDR $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $MBOOT_SIZE>>$SCRIPT_FILE
		printf "mbup 0x%x 0x%x\n" $DRAM_FATLOAD_BUF_ADDR $MBOOT_SIZE >> $SCRIPT_FILE
	else
		printf "mbup 0x%x 0x%x\n" $DRAM_BUF_ADDR $MBOOT_SIZE>> $SCRIPT_FILE
	fi
		
	DRAM_BUF_ADDR=$(($DRAM_BUF_ADDR+$MBOOT_SIZE+$PADDED_SIZE))
	
fi
#-----------------------------------------------------------------
# Add KeySet.bin and secure_info_keySet.bin to final upgrade image
#-----------------------------------------------------------------
if [ "$SECURE_BOOT" = "1" ] ; then
	cat $KEYSET_BIN >>$TEMP_IMG
	SIGNATURE_IMG_SIZE=$(stat -c%s $KEYSET_BIN ) 
	NOT_ALAIN_IMAGE_SIZE=$(($SIGNATURE_IMG_SIZE & 0xfff))
	if [ $NOT_ALAIN_IMAGE_SIZE != 0 ]; then
		PADDED_SIZE=$((0x1000-$NOT_ALAIN_IMAGE_SIZE))
		for ((i=0; i<$PADDED_SIZE; i++))
			do
				printf "\xff" >>$PADDED_BIN
			done
		if [ $PADDED_SIZE != 0 ]; then
			cat $PADDED_BIN >>$TEMP_IMG
			rm $PADDED_BIN
		fi
	fi
	if [ "$CHIP" = "nugget" ] || [ "$CHIP" = "nikon.lite" ] ; then
			if [ "$UPDAT_METHOD" != "rescue" ] ; then
						printf "ubi part UBI\n" >>$SCRIPT_FILE
					if [ "$UPGRADE_FOR_USB" == "0" ] ; then
						printf "ubifsmount oad\n" >>$SCRIPT_FILE
					fi
			fi
	fi
	if [ "$DFUITD" == "0" ] ; then
		printf "$FILE_PART_READ_CMD %x \$(UpgradeImage) %x %x\n" $DRAM_FATLOAD_BUF_ADDR $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $SIGNATURE_IMG_SIZE >>$SCRIPT_FILE
		printf "store_secure_info keySet %x \n" $DRAM_FATLOAD_BUF_ADDR >> $SCRIPT_FILE
	else
		printf "store_secure_info keySet %x \n" $DRAM_BUF_ADDR >> $SCRIPT_FILE
	fi
	DRAM_BUF_ADDR=$(($DRAM_BUF_ADDR+$SIGNATURE_IMG_SIZE+$PADDED_SIZE))
	
    cat $KEYSET_SIGNATURE_BIN >>$TEMP_IMG
	SIGNATURE_IMG_SIZE=$(stat -c%s $KEYSET_SIGNATURE_BIN ) 
	NOT_ALAIN_IMAGE_SIZE=$(($SIGNATURE_IMG_SIZE & 0xfff))
	if [ $NOT_ALAIN_IMAGE_SIZE != 0 ]; then
		PADDED_SIZE=$((0x1000-$NOT_ALAIN_IMAGE_SIZE))
		for ((i=0; i<$PADDED_SIZE; i++))
			do
				printf "\xff" >>$PADDED_BIN
			done
		if [ $PADDED_SIZE != 0 ]; then
			cat $PADDED_BIN >>$TEMP_IMG
			rm $PADDED_BIN
		fi
	fi

	if [ "$CHIP" = "nugget" ] || [ "$CHIP" = "nikon.lite" ] ; then
			if [ "$UPDAT_METHOD" != "rescue" ] ; then
						printf "ubi part UBI\n" >>$SCRIPT_FILE
					if [ "$UPGRADE_FOR_USB" == "0" ] ; then
						printf "ubifsmount oad\n" >>$SCRIPT_FILE
					fi
			fi
	fi

	if [ "$DFUITD" == "0" ] ; then
		printf "$FILE_PART_READ_CMD %x \$(UpgradeImage) %x %x\n" $DRAM_FATLOAD_BUF_ADDR $(($DRAM_BUF_ADDR-$DRAM_BUF_ADDR_START)) $SIGNATURE_IMG_SIZE >>$SCRIPT_FILE
		printf "store_secure_info keySetSign %x \n" $DRAM_FATLOAD_BUF_ADDR >> $SCRIPT_FILE
	else
		printf "store_secure_info keySetSign %x \n" $DRAM_BUF_ADDR >> $SCRIPT_FILE	
	fi
	
	DRAM_BUF_ADDR=$(($DRAM_BUF_ADDR+$SIGNATURE_IMG_SIZE+$PADDED_SIZE))
	#rm -f $FW_SIGNATURE_BIN
fi #if [ "$SECURE_BOOT" = "1" ] ; then

#if [ "$FULL_UPGRADE" == "1"  ] ; then
#----------------------------------------
# Copy content of set_config.sh to  $SCRIPT_FILE
#----------------------------------------
	dos2unix $MSCRIPT_DIR/set_config 2>/dev/null
	exec<"$MSCRIPT_DIR/set_config"
	while read line
	do
		output=`echo $line | grep -v \# | grep -v \%`
		if [ "$output" != "" ] ; then
                        output=`echo $output | sed s/';'/'\\\;'/g`
			printf "$output\n" >> $SCRIPT_FILE
		fi
	done

    dos2unix $MSCRIPT_DIR/[[tee 2>/dev/null
    exec<"$MSCRIPT_DIR/[[tee"
    while read line
    do
        output=`echo $line | grep -v \# | grep -v ^\% | grep -v \%$ | grep setenv`
        if [ "$output" != "" ]; then
            outputnew=`echo "$output" | grep ';'`
            if [ "$outputnew" != "" ]; then
                output=`echo $outputnew | sed s/';'/'\\\;'/g`
            fi
            printf "$output\n" >> $SCRIPT_FILE
            fi
    done
#----------------------------------------
# setup bootcmd
#----------------------------------------
	dos2unix $MSCRIPT_DIR/[[kernel 2>/dev/null
	exec<"$MSCRIPT_DIR/[[kernel"
	while read line
	do
		output=`echo $line | grep -v \# | grep -v \% | grep bootcmd`
		if [ "$output" != "" ] ; then
			output=`echo $output | sed s/';'/'\\\;'/g`
			KERNEL_IMG_SIZE=$(stat -c%s $KL_IMG )
			printf "setenv filesize %x\n" $KERNEL_IMG_SIZE>>$SCRIPT_FILE
			printf "$output\n" >> $SCRIPT_FILE
		fi
	done
	printf "saveenv\n" >>$SCRIPT_FILE
	
#----------------------------------------
# Copy content of miu_setting.txt to  $SCRIPT_FILE
#----------------------------------------
	dos2unix $MSCRIPT_DIR/miu_setting.txt 2>/dev/null
	exec<"$MSCRIPT_DIR/miu_setting.txt"
	while read line
	do
		output=`echo $line | grep -v \# | grep -v \%`
		output_len=`expr length "$output"`
		if [ "$output" != "" ] && [ $output_len -gt 1 ] ; then
			outputhead=`echo $output | head -c 6`
			if [ "$outputhead" == "setenv" ] ; then
				printf "$output\n" >> $SCRIPT_FILE
			elif [ "$outputhead" == "saveen" ] ; then				
				printf "skip saveenv"
			else
			printf "setenv $output\n" >> $SCRIPT_FILE
		fi
		fi
	done
	printf "saveenv\n" >>$SCRIPT_FILE
	printf "printenv\n" >>$SCRIPT_FILE	
#fi  #if [ "$FULL_UPGRADE" == "1"  ] ; then
func_finish_script;
func_pad_script;
func_post_process;

#==============copy the first 16 bytes to last (not for OAD) =================================
if [ "$UPGRADE_FOR_USB" == "1" ] ; then
dd if=$IMAGE_DIR/$OUTPUT_IMG of=$IMAGE_DIR/out.bin bs=16 count=1;
cat $IMAGE_DIR/out.bin >>$IMAGE_DIR/$OUTPUT_IMG
rm -rf out.bin
fi
#==============copy the first 16 bytes to last end=================================

if [ "$SECURE_UPGRADE" == "1" ] ; then
#==============Pack.sh=================================
cd $SEC_TOOL_DIR

./Pack.sh ./Key/RSAupgrade_priv.txt ./Key/RSAupgrade_pub.txt ./Key/AESupgrade.bin ../../$IMAGE_DIR/MstarUpgrade.bin ./abc.bin 1 655360
cp -f abc.bin.aes ../../$IMAGE_DIR/$OUTPUT_IMG
#==============Pack.sh end=================================
fi
exit 0

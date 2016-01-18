//<MStar Software>
//******************************************************************************
// MStar Software
// Copyright (c) 2010 - 2012 MStar Semiconductor, Inc. All rights reserved.
// All software, firmware and related documentation herein ("MStar Software") are
// intellectual property of MStar Semiconductor, Inc. ("MStar") and protected by
// law, including, but not limited to, copyright law and international treaties.
// Any use, modification, reproduction, retransmission, or republication of all 
// or part of MStar Software is expressly prohibited, unless prior written 
// permission has been granted by MStar. 
//
// By accessing, browsing and/or using MStar Software, you acknowledge that you
// have read, understood, and agree, to be bound by below terms ("Terms") and to
// comply with all applicable laws and regulations:
//
// 1. MStar shall retain any and all right, ownership and interest to MStar
//    Software and any modification/derivatives thereof.
//    No right, ownership, or interest to MStar Software and any
//    modification/derivatives thereof is transferred to you under Terms.
//
// 2. You understand that MStar Software might include, incorporate or be
//    supplied together with third party`s software and the use of MStar
//    Software may require additional licenses from third parties.  
//    Therefore, you hereby agree it is your sole responsibility to separately
//    obtain any and all third party right and license necessary for your use of
//    such third party`s software. 
//
// 3. MStar Software and any modification/derivatives thereof shall be deemed as
//    MStar`s confidential information and you agree to keep MStar`s 
//    confidential information in strictest confidence and not disclose to any
//    third party.  
//
// 4. MStar Software is provided on an "AS IS" basis without warranties of any
//    kind. Any warranties are hereby expressly disclaimed by MStar, including
//    without limitation, any warranties of merchantability, non-infringement of
//    intellectual property rights, fitness for a particular purpose, error free
//    and in conformity with any international standard.  You agree to waive any
//    claim against MStar for any loss, damage, cost or expense that you may
//    incur related to your use of MStar Software.
//    In no event shall MStar be liable for any direct, indirect, incidental or
//    consequential damages, including without limitation, lost of profit or
//    revenues, lost or damage of data, and unauthorized system use.
//    You agree that this Section 4 shall still apply without being affected
//    even if MStar Software has been modified by MStar in accordance with your
//    request or instruction for your use, except otherwise agreed by both
//    parties in writing.
//
// 5. If requested, MStar may from time to time provide technical supports or
//    services in relation with MStar Software to you for your use of
//    MStar Software in conjunction with your or your customer`s product
//    ("Services").
//    You understand and agree that, except otherwise agreed by both parties in
//    writing, Services are provided on an "AS IS" basis and the warranty
//    disclaimer set forth in Section 4 above shall apply.  
//
// 6. Nothing contained herein shall be construed as by implication, estoppels
//    or otherwise:
//    (a) conferring any license or right to use MStar name, trademark, service
//        mark, symbol or any other identification;
//    (b) obligating MStar or any of its affiliates to furnish any person,
//        including without limitation, you and your customers, any assistance
//        of any kind whatsoever, or any information; or 
//    (c) conferring any license or right under any intellectual property right.
//
// 7. These terms shall be governed by and construed in accordance with the laws
//    of Taiwan, R.O.C., excluding its conflict of law rules.
//    Any and all dispute arising out hereof or related hereto shall be finally
//    settled by arbitration referred to the Chinese Arbitration Association,
//    Taipei in accordance with the ROC Arbitration Law and the Arbitration
//    Rules of the Association by three (3) arbitrators appointed in accordance
//    with the said Rules.
//    The place of arbitration shall be in Taipei, Taiwan and the language shall
//    be English.  
//    The arbitration award shall be final and binding to both parties.
//
//******************************************************************************
//<MStar Software>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <memory.h>

#define CHUNK_SIZE 128
unsigned char CHUNK_ID[]={0x4D,0x53,0x54,0x41,0x52,0x2E,0x2E,0x2E}; //"MSTAR..."
unsigned char CHUNK_END[]={0x2E,0x2E,0x2E,0x6D,0x73,0x74,0x61,0x72}; //"...mstar"
#define MAX_FILE_NUM (((CHUNK_SIZE-sizeof(CHUNK_ID)-sizeof(CHUNK_END)-4)/8))

unsigned int  _atoi(char *str)
{
	
	unsigned int  value=0;

       if(*str=='\0') return  value;

	if((str[0]=='0')&&((str[1]=='x')||(str[1]=='X'))){   
	// 16Hex
		str+=2;
		while(1){

		   if(*str>=0x61)
		   	*str-=0x27;
		   else if(*str>=0x41)
		   	*str-=0x07;
		   
		   value|=(*str-'0');
		   str++;
		   //i++;
	          if(*str=='\0') break;
		   value=value<<4;	  
	      }
	}
	else{
	// 10 Dec

	       unsigned int  len,tmp=1;;	
		len=strlen(str);
		while(len){
			if(*str>'9') return 0;
			
			value+=((str[len-1]-'0')*tmp);

			len--;
			tmp=tmp*10;
	       }
	}
	return value;
	
}

int main(char argc, char *argv[])
{
	unsigned char i=0;
	unsigned int fileSize=0;
	unsigned int address=0;
	FILE *fsread=NULL;
	FILE *fswrite=NULL;
	unsigned char chunkBuf[CHUNK_SIZE];
	unsigned int *pWriteChunk=NULL;
	if(argc<3){
		printf("./GenChunk.exe [Segment Size][file1] [file2] [file3] .....\n");
		return -1;
	}
	
	if(argc>(MAX_FILE_NUM+1)){
		printf("[ERROR] Too more files, it can only support %d files\n",MAX_FILE_NUM);
		return -1;
	}
	
	memset(chunkBuf,0,CHUNK_SIZE);
	memcpy(chunkBuf,CHUNK_ID,sizeof(CHUNK_ID)); 
	pWriteChunk=(unsigned int *)chunkBuf;
	pWriteChunk+=2;
	*pWriteChunk=_atoi(argv[1]);
	pWriteChunk+=1;
	for(i=1;i<argc-1;i++){
		fsread=fopen(argv[i+1],"r");
		if(fsread==NULL){
			printf("[ERROR] open %s fail\n", argv[i+1]);
			return -1;
		}
		fseek(fsread, 0, SEEK_END);
		fileSize=ftell(fsread);
		fclose(fsread);
		*pWriteChunk=address;
		pWriteChunk++;
		*pWriteChunk=fileSize;
		pWriteChunk++;
		address+=fileSize;
	}
	memcpy(&chunkBuf[CHUNK_SIZE-sizeof(CHUNK_END)],CHUNK_END,sizeof(CHUNK_END));
	
	fswrite=fopen("chunk","w");
	if(fswrite==NULL){
		printf("[ERROR] open chunk fail\n");
			return -1;
	}
	fwrite(chunkBuf, CHUNK_SIZE,sizeof(char),fswrite);
	fclose(fswrite);
	
	return 0;
}


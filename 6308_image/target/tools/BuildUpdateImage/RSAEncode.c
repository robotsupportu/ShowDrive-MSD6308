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
#include <stdlib.h>
#include <string.h>
#include <memory.h>

#define HAST_POST_FIX ".hash"
#define SIGNATURE_POST_FIX ".hash.signature"
#define RSA_SING_BIN_POST_FIX ".sig.bin"
#define RSA_SING_POST_FIX ".sig"
unsigned int GetFileSize(char *filePath);
unsigned int GetFileName(char *filePath, char *retfileName, unsigned int  sizefileNameBuf);
unsigned int GetFilePath(char *filePath, char *retfilePath, unsigned int  sizefilePathBuf);

int main(char argc, char *argv[])
{
	char *privateKey;
	char *publicKey;
	char *targetFile;
	unsigned int enSeparate=0;
	unsigned int separateSize=0;
	unsigned int separateCycle=0;
	unsigned int targetFileSize=0;
	unsigned int len=0;
	unsigned int size=0;	
	char targetFileName[1000];
	char targetFilePath[2000];
	char finalHashName[1500];
	char signatureName[1500];
	char tempBuf1[1000];
	char tempBuf2[1000];
	char cmdBuf[1000];
	char *buf;
	FILE *fsRead;
	FILE *fsWrite;
	unsigned int i=0;
	
	if(argc<6){
		printf("./RSAEncode [private key] [public key] [target file] [en separate] [spearate size]\n");
		return -1;
	}
	privateKey=argv[1];
	publicKey=argv[2];
	targetFile=argv[3];
	enSeparate=atoi(argv[4]);
	separateSize=atoi(argv[5]);
	
	
	targetFileSize=GetFileSize(targetFile);
	if(targetFileSize==0) return -1;
	printf("targetFileSize=0x%x\n",targetFileSize);
	
	memset(targetFileName,0,sizeof(targetFileName));
	if(GetFileName(targetFile, targetFileName, sizeof(targetFileName))!=0) return -1;
	printf("FileName=%s\n",targetFileName);
	
	memset(targetFilePath,0,sizeof(targetFilePath));
	if(GetFilePath(targetFile, targetFilePath, sizeof(targetFilePath))!=0) return -1;
	printf("FilePath=%s\n",targetFilePath);
	
	memset(finalHashName,0,sizeof(finalHashName));
	strcat(strcpy(finalHashName,targetFileName),HAST_POST_FIX);
	printf("hash file name=%s\n",finalHashName);
	
	memset(signatureName,0,sizeof(signatureName));
	strcat(strcpy(signatureName,targetFileName),SIGNATURE_POST_FIX);
	printf("signature file name=%s\n",signatureName);
	
	if(enSeparate){
		separateCycle=targetFileSize/separateSize;
		if(targetFileSize%separateSize!=0)
			separateCycle++;
	}
	else{
		memset(cmdBuf,0,sizeof(cmdBuf));
		memset(tempBuf1,0,sizeof(tempBuf1));
		memset(tempBuf2,0,sizeof(tempBuf2));
		strcat(strcpy(tempBuf2, targetFile),RSA_SING_BIN_POST_FIX);
		strcat(strcpy(tempBuf1, targetFilePath),signatureName);
		sprintf(cmdBuf,  "./rsa %s %s",targetFile, privateKey);
		system(cmdBuf);
		sprintf(cmdBuf,  "mv %s %s",tempBuf2, tempBuf1);
		//sprintf(cmdBuf,  "./cryptest.exe na_sign %s %s %s %s", privateKey, publicKey, targetFile,tempBuf1);
		//printf("cmdBuf:%s\n",cmdBuf);
		//system(cmdBuf);
	}
	
	buf=malloc(separateSize);
	if(buf==NULL){
		printf("[ERROR] memory allocate fail\n");
		return -1;
	}
	memset(buf, 0, separateSize);
	
	//printf("separateCycle=%d\n",separateCycle);
	
	fsRead=fopen(targetFile,"r");
	if(fsRead==NULL){
		printf("[ERROR] open file %s fail\n",argv[3]);
		free(buf);
		return -1;
	}
	
	len=targetFileSize;
	for(i=0;i<separateCycle;i++){
		fsWrite=fopen("tempFile","w");
		if(fsWrite==NULL){
			printf("[ERROR] open file tempFile fail\n");
			fclose(fsRead);
			free(buf);
			return -1;
		}	
		
		size=(len>=separateSize)?separateSize:len;
		printf("size=0x%x\n",size);
		
		fread(buf, size, sizeof(char), fsRead);
		fwrite(buf, size, sizeof(char), fsWrite);
		fclose(fsWrite);
		
	    system("./GenHash.sh ./tempFile ./temphash.bin");
		
		memset(cmdBuf,0,sizeof(cmdBuf));
		memset(tempBuf1,0,sizeof(tempBuf1));
		strcat(strcpy(tempBuf1, targetFilePath),finalHashName);
		sprintf(cmdBuf, "cat ./temphash.bin >> %s",tempBuf1);
		printf("cmdBuf:%s\n",cmdBuf);
		system(cmdBuf);
		
		len-=size;
		printf("len=0x%x\n",len);
		//if(i==1) while(1);
		if(remove("tempFile")!=0){
			printf("[ERROR] remove tempFile fail\n");
			fclose(fsWrite);
			fclose(fsRead);
			free(buf);
			return-1;
		}
		
		
	}
	if(remove("temphash.bin")!=0){
		printf("[ERROR] remove temphash.bin fail\n");
		fclose(fsWrite);
		fclose(fsRead);
		free(buf);
		return-1;
	}	
	
	memset(cmdBuf,0,sizeof(cmdBuf));
	memset(tempBuf1,0,sizeof(tempBuf1));
	strcat(strcpy(tempBuf1, targetFilePath),finalHashName);
	sprintf(cmdBuf,  "./rsa_sign %s %s", tempBuf1, privateKey);
	printf("cmdBuf:%s\n",cmdBuf);
	system(cmdBuf);
	
	strcat(tempBuf1,RSA_SING_BIN_POST_FIX);
	memset(tempBuf2,0,sizeof(tempBuf2));
	strcat(strcpy(tempBuf2, targetFilePath),signatureName);	
	sprintf(cmdBuf,  "mv %s %s", tempBuf1,tempBuf2);
	printf("cmdBuf:%s\n",cmdBuf);
	system(cmdBuf);
	
	memset(tempBuf1,0,sizeof(tempBuf1));
	strcat(strcpy(tempBuf1, targetFilePath),finalHashName);
	strcat(tempBuf1,RSA_SING_POST_FIX);
	
	if(remove(tempBuf1)!=0){
		printf("[ERROR] remove tempSignature fail\n");
		fclose(fsWrite);
		fclose(fsRead);
		free(buf);
		return-1;
	}
	
	fclose(fsRead);	
	free(buf);
	return 0;
	
}


unsigned int GetFileSize(char *filePath)
{
	FILE *fsRead=NULL;
	unsigned int fileSize;
	
	fsRead=fopen(filePath,"r");
	if(fsRead==NULL){
		printf("[ERROR] open file %s fail\n",filePath);
		fclose(fsRead);
		return 0;
	}
	fseek(fsRead, 0, SEEK_END);
	fileSize=ftell(fsRead);
	fclose(fsRead);
	return fileSize;
}

unsigned int GetFileName(char *filePath, char * retfileName, unsigned int sizefileNameBuf)
{
	char *index;
	unsigned int nameLen;
	
	index=strrchr(filePath,'/');
	if(index==NULL){
		printf("[ERRROR] Doesn't found file name\n");
		return -1;
	}
	index+=1;
	nameLen=strlen(index);
	if(nameLen<sizefileNameBuf){
		strncpy(retfileName, index, nameLen);
		retfileName[nameLen]='\0';
	}
	else{
		strncpy(retfileName, index, sizefileNameBuf-1);
		retfileName[sizefileNameBuf-1]='\0';
	}
	
	return 0;
}

unsigned int GetFilePath(char *filePath, char *retfilePath, unsigned int sizefilePathBuf)
{
	char *index;
	unsigned int len;
	
	index=strrchr(filePath,'/');
	if(index==NULL){
		retfilePath[0]='\0';
		return;
	}
	
	
	len=index-filePath;
			
	len=len+1;

	if(len==0){
		retfilePath[len]='\0';
	}
	else{
		strncpy(retfilePath, filePath, len);
		retfilePath[len]='\0';
	}
	return 0;
}




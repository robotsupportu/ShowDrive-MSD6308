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
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>

// Convert binary file into HEX bytes for being included in a .c file.
int   str2hex(char*   pInput,   unsigned   char*   pOutput,   int*   len)
{
    char c1, c2;
    int i, length;
    
    length = strlen(pInput);
    if(length%2)
    {
        return 0;
    }
    
    for(i=0; i<length; i++)
    {
    	pInput[i] = toupper(pInput[i]);
    }
    
    for(i=0; i< length/2; i++)
    {
        c1 = pInput[2*i];
        c2 = pInput[2*i+1];
        if(c1<'0' || (c1 > '9' && c1 <'A') || c1 > 'F')
        {
            continue;
        }
        
        if(c2<'0' || (c2 > '9' && c2 <'A') || c2 > 'F')
        {
            continue;
        }
        
        c1 = c1>'9' ? c1-'A'+10 : c1 -'0';
        c2 = c2>'9' ? c2-'A'+10 : c2 -'0';
        pOutput[i] = c1<<4 | c2;
    }
    *len = i;
    return 1;
}

unsigned long str2int(char *str)
{
    unsigned char is_hex_type = 0;
    unsigned long out = 0;
    char c;
    int i, length;

    if (NULL == str)
    {
        return 0;
    }
    
    length = strlen(str);
    for(i=0; i<length; i++)
    {
    	str[i] = toupper(str[i]);
    }
    
    if (str[0] == '0' && str[1] == 'X')
    {
        is_hex_type = 1;
    }

    i = (is_hex_type) ? 2 : 0;
    for (;i<length;i++)
    {
        c = str[i];
        if (is_hex_type)
        {
            if (c<'0' || (c>'9' && c<'A') || c>'F')
            {
                return 0;
            }
            c = (c>'9') ? (c-'A'+10) : (c-'0');
            out = (16*out)+c;
        }
        else
        {
            if (c<'0' || c>'9')
            {
                return 0;
            }
            c = c-'0';
            out = (10*out)+c;
        }
    }
    return out;
}

int main(int argc, char* argv[])
{
    FILE *t_fpin_s, *t_fpin_d;
    int gap, src_len, dest_len;
    unsigned long append_addr;
    unsigned char *pBuf, *pSBuf;

    if (4 != argc)
    {
        printf("Usage: %s <source path> <destination path> <append address> \n", argv[0]);
        return 0;
    }

    if (NULL == (t_fpin_s = fopen(argv[1], "rb")))
    {
        printf("[Error]cannot open %s\n", argv[1]);
        return -1;
    }

    if (NULL == (t_fpin_d = fopen(argv[2], "ab+")))
    {
        printf("[Error]cannot open %s\n", argv[2]);
        return -1;
    }

		append_addr = str2int(argv[3]);
		
    fseek(t_fpin_s, 0, SEEK_END);
    src_len = ftell(t_fpin_s);
    fseek(t_fpin_s, 0, SEEK_SET);

    fseek(t_fpin_d, 0, SEEK_END);
    dest_len = ftell(t_fpin_d);
    fseek(t_fpin_d, 0, SEEK_SET);
    
			gap = append_addr - dest_len;
			//printf("append_addr = 0x%x, dest_len = 0x%X, gap = 0x%X\n", append_addr, dest_len, gap);

			if(append_addr == 0)
		  {
				gap = 0;
			}
					
			if(gap<0)
		  {
	    	pBuf = (unsigned char *)malloc(dest_len + src_len);
	    	memset(pBuf, 0, dest_len + src_len);

	      fseek(t_fpin_d, 0, SEEK_SET);
				fread(&pBuf[0], 1, dest_len, t_fpin_d);
					    	
	      fread(&pBuf[append_addr], 1, src_len, t_fpin_s);
	      
	      fclose(t_fpin_d);

		    if (NULL == (t_fpin_d = fopen(argv[2], "wb")))
		    {
		        printf("[Error]cannot open %s\n", argv[2]);
		        return -1;
		    }
		    
	    	fwrite(&pBuf[0], sizeof(unsigned char), (append_addr + src_len), t_fpin_d);
	    	free(pBuf);
	    }
	    else
	    {
	    	pBuf = (unsigned char *)malloc(dest_len + gap + src_len);
				memset(pBuf, 0, dest_len + gap + src_len);

	      fseek(t_fpin_d, 0, SEEK_SET);
				fread(&pBuf[0], 1, dest_len, t_fpin_d);
					      				
				fread(&pBuf[dest_len + gap], 1, src_len, t_fpin_s);
				
	      fclose(t_fpin_d);

		    if (NULL == (t_fpin_d = fopen(argv[2], "wb")))
		    {
		        printf("[Error]cannot open %s\n", argv[2]);
		        return -1;
		    }
		    
	    	fwrite(&pBuf[0], sizeof(unsigned char), (dest_len + gap + src_len), t_fpin_d);
	    	free(pBuf);
	    }
		
    fclose(t_fpin_s);
    fclose(t_fpin_d);
    printf("MergeBin Done !!\n");
    return 0;
}

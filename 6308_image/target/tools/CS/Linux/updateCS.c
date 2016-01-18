
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <string.h>

#define UPDATECS_DBG(fmt, arg...)         //printf((char *)fmt, ##arg)
#define UPDATECS_ERR(fmt, arg...)         printf((char *)fmt, ##arg)
#define UPDATECS_INFO(fmt, arg...)         printf((char *)fmt, ##arg)

unsigned char iniparser_CheckCS(unsigned char * ininame);
unsigned char iniparser_UpdateCS(unsigned char * ininame);
//#define	FILENAME   "system.ini"
int main(int argc, char* argv[])
{
    unsigned char test;
    int i;
/*    
 	//UPDATECS_DBG("enter main\n");	
	//===============================
    //unsigned char u8FilePath[36];
    
    unsigned char tmp2[16] ;
    //strcpy(u8FilePath, "/tmp/usb/");
    memset(tmp2,0, sizeof(tmp2));
    
    UPDATECS_DBG( "Please Input file name:\n ") ;
    scanf("%s", tmp2);
    //strcat(u8FilePath, tmp2);

    UPDATECS_DBG("Openfile=%s \n ",tmp2);
*/



    for( i=2; i<=argc;i++)
    {
        // UPDATECS_INFO("%s\n",argv[i-1]);
        test = iniparser_UpdateCS (argv[i-1]);
        if(test==0)
            return 1;
    }

    return 0;
 //   test = iniparser_UpdateCS (tmp2);
 //   UPDATECS_DBG("test [%d] \n",test);
   //===============================
		
}


unsigned char iniparser_UpdateCS(unsigned char * ininame)
{
   UPDATECS_DBG("%s\n",__FUNCTION__);

   unsigned char bRes = 0;
   FILE *pFile =NULL;
   unsigned char u8PatternSize=12;
   unsigned char u8FindPattern=0;
   unsigned int u32Filelength=0;
   unsigned int u32FileSize=0;
   unsigned char *pu8Buffer =NULL;
   unsigned int u32ReadSize=0;
   unsigned int u32Index=0;
   unsigned char u8ReadChar=0;
   unsigned int  u32CalculateCS=0;

   pFile = fopen(ininame,"rb");
   if(pFile == NULL)
   {
       UPDATECS_ERR("Open file Failed\n");
       return bRes;
   }

    fseek(pFile, 0, SEEK_END);
    u32Filelength = ftell(pFile);
    if ((u32Filelength == 0) || (u32Filelength <= u8PatternSize) )
    {
       UPDATECS_DBG("file size fail \n");
       fclose(pFile);
       pFile =NULL;
       return bRes;
    }

    fseek(pFile, -u8PatternSize, SEEK_END); //seek to pattern
    pu8Buffer = (unsigned char*) malloc(u32Filelength+u8PatternSize);
    if (pu8Buffer == NULL)
    {
        UPDATECS_DBG("malloc fail \n");
        fclose(pFile);
        pFile =NULL;
        return bRes;
    }

    //check pattern
    memset(pu8Buffer,0x0,u8PatternSize+u32Filelength);
    u32ReadSize = fread(pu8Buffer, 1, u8PatternSize, pFile);// read 12 bytes
    u32Index =0;

    while(u32ReadSize>0)
    {
        if (pu8Buffer[u32Index] == '#' && pu8Buffer[u32Index+1] =='@' && pu8Buffer[u32Index+2] == 'C' ) //find pattern
        {
            UPDATECS_DBG("find CS pattern \n");
            UPDATECS_DBG("CS data1 [0x%x] \n",pu8Buffer[u32Index+8]);
            UPDATECS_DBG("CS data2 [0x%x] \n",pu8Buffer[u32Index+9]);
            UPDATECS_DBG("CS data3 [0x%x] \n",pu8Buffer[u32Index+10]);
            UPDATECS_DBG("CS data4 [0x%x] \n",pu8Buffer[u32Index+11]);
            u32ReadSize =0;
            u8FindPattern=1;
        }
        else
        {
            u32Index++;
        }

        if (u32Index >=5 )
        {
            u32ReadSize =0;
            u8FindPattern=0;
            UPDATECS_DBG("not find CS pattern \n");
        }

    }


    rewind(pFile);
    memset(pu8Buffer,0x0,u8PatternSize+u32Filelength);
    u32ReadSize = fread(pu8Buffer, 1, u32Filelength, pFile);// read total data

    fclose(pFile);
    pFile = NULL;

    // Calculate CS
    u32Index =0;
    u32CalculateCS =0;
    u32FileSize = u32Filelength;

    if (u8FindPattern)
    {
        u32Filelength -=u8PatternSize;
    }

    while(u32Filelength > 0 )
    {
        u8ReadChar = (unsigned char)pu8Buffer[u32Index];
        u32CalculateCS += u8ReadChar;
       // UPDATECS_DBG("data[0x%x]\n",u8ReadChar);
        if (u32CalculateCS >= 0xFFFF)
        {
            u32CalculateCS =0;
        }
        u32Filelength--;
        u32Index++;
    }

    u32Index=0;
    u32Filelength = u32FileSize;

    UPDATECS_DBG("Calculate CS [0x%x] \n",u32CalculateCS);

    // update CS
    if (u8FindPattern)
    {
        pu8Buffer[u32Filelength -4]  = (((u32CalculateCS>>12)&0x0F) <= 9)? (((u32CalculateCS>>12)&0x0F)+0x30):( ((u32CalculateCS>>12)&0x0F)-0x0A + 0x41);
        pu8Buffer[u32Filelength -3]  = (((u32CalculateCS>>8)&0x0F) <= 9)? (((u32CalculateCS>>8)&0x0F)+0x30):( ((u32CalculateCS>>8)&0x0F)-0x0A + 0x41);
        pu8Buffer[u32Filelength -2]  = (((u32CalculateCS>>4)&0x0F) <= 9)? (((u32CalculateCS>>4)&0x0F)+0x30):( ((u32CalculateCS>>4)&0x0F)-0x0A + 0x41);
        pu8Buffer[u32Filelength -1]  = (((u32CalculateCS>>0)&0x0F) <= 9)? (((u32CalculateCS>>0)&0x0F)+0x30):( ((u32CalculateCS>>0)&0x0F)-0x0A + 0x41);
        UPDATECS_DBG("Updated CS data1 [0x%x] \n",pu8Buffer[u32Filelength -4]);
        UPDATECS_DBG("Updated CS data2 [0x%x] \n",pu8Buffer[u32Filelength -3]);
        UPDATECS_DBG("Updated CS data3 [0x%x] \n",pu8Buffer[u32Filelength -2]);
        UPDATECS_DBG("Updated CS data4 [0x%x] \n",pu8Buffer[u32Filelength -1]);

    }
    else
    {
        pu8Buffer[u32Filelength++] = '#';
        pu8Buffer[u32Filelength++] = '@';
        pu8Buffer[u32Filelength++] = 'C';
        pu8Buffer[u32Filelength++] = 'R';
        pu8Buffer[u32Filelength++] = 'C';
        pu8Buffer[u32Filelength++] = '=';
        pu8Buffer[u32Filelength++] = '0';
        pu8Buffer[u32Filelength++] = 'x';
        pu8Buffer[u32Filelength++]  = (((u32CalculateCS>>12)&0x0F) <= 9)? (((u32CalculateCS>>12)&0x0F)+0x30):( ((u32CalculateCS>>12)&0x0F)-0x0A + 0x41);
        pu8Buffer[u32Filelength++]  = (((u32CalculateCS>>8)&0x0F) <= 9)? (((u32CalculateCS>>8)&0x0F)+0x30):( ((u32CalculateCS>>8)&0x0F)-0x0A + 0x41);
        pu8Buffer[u32Filelength++]  = (((u32CalculateCS>>4)&0x0F) <= 9)? (((u32CalculateCS>>4)&0x0F)+0x30):( ((u32CalculateCS>>4)&0x0F)-0x0A + 0x41);
        pu8Buffer[u32Filelength++]  = (((u32CalculateCS>>0)&0x0F) <= 9)? (((u32CalculateCS>>0)&0x0F)+0x30):( ((u32CalculateCS>>0)&0x0F)-0x0A + 0x41);
        u32Filelength = u32FileSize+u8PatternSize;
        UPDATECS_DBG(">>Updated CS data1 [0x%x]<< \n",pu8Buffer[u32Filelength -4]);
        UPDATECS_DBG(">>Updated CS data2 [0x%x]<< \n",pu8Buffer[u32Filelength -3]);
        UPDATECS_DBG(">>Updated CS data3 [0x%x]<< \n",pu8Buffer[u32Filelength -2]);
        UPDATECS_DBG(">>Updated CS data4 [0x%x]<< \n",pu8Buffer[u32Filelength -1]);
    }

    // write CS
    // pFile = fopen("output.ini","w");
    pFile = fopen(ininame,"w");

   if(pFile == NULL)
   {
       UPDATECS_DBG("Open wirte file Failed\n");
       free(pu8Buffer);       
       return bRes;
   }

    if(!fwrite(pu8Buffer, 1, u32Filelength,  pFile))
    {
        UPDATECS_INFO("Ini file CS write fail : %s\n", ininame);
        bRes =0;
    }
    else
    {
        UPDATECS_INFO("Ini file CS write success : %s\n", ininame);
        bRes =1;
    }
        UPDATECS_DBG("===> file write %d bytes\n", u32Filelength);


   fclose(pFile);
   pFile = NULL;
   free(pu8Buffer);
   pu8Buffer =NULL;

  // system("umount -f /mnt/usb1/Drive1");

   return bRes;


}

unsigned char iniparser_CheckCS(unsigned char * ininame)
{
    unsigned char bRes = 0;
    FILE *pFile =NULL;
    unsigned int u32Filelength=0;
    unsigned char u8PatternSize=12;
    unsigned char u8ReadSize=0;
    unsigned short u16CS=0;
    unsigned char u8Index=0;
    unsigned int  u32CalculateCS=0;
    unsigned char u8ReadChar=0;
    unsigned char *pu8Buffer =NULL;
    UPDATECS_DBG("%s\n",__FUNCTION__);
    
    pFile = fopen(ininame,"rb");
    if(pFile == NULL)
    {
       UPDATECS_DBG("Open file Failed\n");
       return bRes;
    }

    fseek(pFile, 0, SEEK_END);
    u32Filelength = ftell(pFile);
    if ((u32Filelength == 0) || (u32Filelength <= u8PatternSize) )
    {
       UPDATECS_DBG("file size fail \n");
       fclose(pFile);
       pFile =NULL;
       return bRes;
    }

    fseek(pFile, -u8PatternSize, SEEK_END); //seek to pattern
    pu8Buffer = (unsigned char*) malloc(u8PatternSize);
    if (pu8Buffer == NULL)
    {
        UPDATECS_DBG("malloc fail \n");
        fclose(pFile);
        pFile =NULL;
        return bRes;

    }

    //check pattern, read 12 bytes
    memset(pu8Buffer,0x0,u8PatternSize);
    u8ReadSize = fread(pu8Buffer, 1, u8PatternSize, pFile);
    u8Index =0;
    while(u8ReadSize>0)
    {
        if (pu8Buffer[u8Index] == '#' && pu8Buffer[u8Index+1] =='@' && pu8Buffer[u8Index+2] == 'C' ) //find pattern
        {
            UPDATECS_DBG("find CS pattern \n");
            UPDATECS_DBG("CS data1 [0x%x] \n",pu8Buffer[u8Index+8]);
            UPDATECS_DBG("CS data2 [0x%x] \n",pu8Buffer[u8Index+9]);
            UPDATECS_DBG("CS data3 [0x%x] \n",pu8Buffer[u8Index+10]);
            UPDATECS_DBG("CS data4 [0x%x] \n",pu8Buffer[u8Index+11]);

            pu8Buffer[u8Index+8]  = (pu8Buffer[u8Index+8]>=0x41) ? (pu8Buffer[u8Index+8]-0x41+0x0A)   : (pu8Buffer[u8Index+8]-0x30);
            pu8Buffer[u8Index+9]  = (pu8Buffer[u8Index+9]>=0x41) ? (pu8Buffer[u8Index+9]-0x41+0x0A)   : (pu8Buffer[u8Index+9]-0x30);
            pu8Buffer[u8Index+10] = (pu8Buffer[u8Index+10]>=0x41)? (pu8Buffer[u8Index+10]-0x41+0x0A) : (pu8Buffer[u8Index+10]-0x30);
            pu8Buffer[u8Index+11] = (pu8Buffer[u8Index+11]>=0x41)? (pu8Buffer[u8Index+11]-0x41+0x0A) : (pu8Buffer[u8Index+11]-0x30);

            u16CS = (pu8Buffer[u8Index+8] << 12) |( pu8Buffer[u8Index+9] << 8) | ( pu8Buffer[u8Index+10] << 4) | ( pu8Buffer[u8Index+11] );

            UPDATECS_DBG("CS at file [0x%x] \n",u16CS);
            u8ReadSize =0;

        }
        else
        {
            u8Index++;
        }

        if (u8Index >=5 )
        {
            u8ReadSize =0;
            UPDATECS_DBG("not find pattern \n");
            free(pu8Buffer);
            fclose(pFile);
            pFile =NULL;
            pu8Buffer =NULL;
            return bRes;
        }

    }

    rewind(pFile);

    u32Filelength = u32Filelength -12;
    u32CalculateCS =0;
    while(u32Filelength>0 && !feof(pFile))
    {
        u8ReadChar = (unsigned char)fgetc(pFile);
        u32CalculateCS += u8ReadChar;

        if (u32CalculateCS >= 0xFFFF)
        {
            u32CalculateCS =0;
        }
        u32Filelength--;
    }

    UPDATECS_DBG("Calculate CS [0x%x] \n",u32CalculateCS);

    if (u32CalculateCS == u16CS)
    {
        bRes = 1;
    }

    free(pu8Buffer);
    fclose(pFile);
    pFile = NULL;
    pu8Buffer =NULL;
   return bRes;
}


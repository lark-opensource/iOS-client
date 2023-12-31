//
//  av_cache_utils.cpp
//  TTAVPlayer
//
//  Created by 黄清 on 2018/12/5.
//

#include "ttvideoenginecacheutils.h"
#include <CommonCrypto/CommonDigest.h>
#include <string.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>

#define MKTAG(a,b,c,d) ((a) | ((b) << 8) | ((c) << 16) | ((unsigned)(d) << 24))

typedef struct MFCACHEFILEENDBOX{
    int32_t length;
    int32_t head;
    int32_t crc;
    int32_t num;
    uint32_t file_size[2];
    int32_t rv1;
    int32_t rv2;
}MFCACHEFILEENDBOX;

int ttvideoengine_check_cache_file_integrity(const char* file, int64_t fileSize, const char* md5) {
    if (file == NULL || strlen(file) == 0 || md5 == NULL || strlen(md5) == 0 || fileSize <= 0) {
#ifdef DEBUG
        printf("parameter is invalid. \n");
#endif
        return 0;
    }
    
    int64_t read_size           = 0;
    int     file_handle         = 0;
    int64_t local_file_size     = 0;
    int64_t origin_file_size    = 0;
    int     head_size           = sizeof(uint32_t) * 2;
    int32_t head_info[2];
    MFCACHEFILEENDBOX box;
#ifdef DEBUG
    printf("file path%s \n",file);
#endif
    struct stat statbuf;
    if (file && stat(file, &statbuf) == 0) {
        local_file_size = statbuf.st_size;
    }
#ifdef DEBUG
    printf("local file size:%lld \n",local_file_size);
#endif
    
    file_handle = open(file, O_RDWR, 0777);
    if(file_handle <= 0) {
#ifdef DEBUG
        printf("open file fail \n");
#endif
        goto fail;
    }
    
    read_size = lseek(file_handle,local_file_size - head_size, SEEK_CUR);
    read_size = read(file_handle, head_info, head_size);
    if(read_size < head_size || head_info[0] <= 0 || head_info[1] != MKTAG('t','t','m','f')) {//no config
#ifdef DEBUG
        printf("no config. local file size:%lld \n",local_file_size);
#endif
        origin_file_size = local_file_size;
        goto calculate_md5;
    }
    
    read_size = lseek(file_handle,local_file_size - head_info[0], SEEK_SET);
    read_size = read(file_handle,&box,sizeof(MFCACHEFILEENDBOX));
    if(read_size < sizeof(MFCACHEFILEENDBOX) || box.length <= 0 || box.head != MKTAG('t','t','m','f') || box.num == 0) {
#ifdef DEBUG
        printf("open fail. read_size:%lld,box.length:%d,box.head:%x \n",read_size,box.length,box.head);
#endif
        goto fail;
    }
    
    origin_file_size =  box.file_size[1];
    origin_file_size <<= 32;
    origin_file_size |= box.file_size[0];
    
    //calculate md5
calculate_md5:
    if (fileSize != origin_file_size) {
        goto fail;
    }
    if(lseek(file_handle, 0, SEEK_SET) != 0) {
        goto fail;
    }
    {
        CC_MD5_CTX ctx;
        CC_MD5_Init(&ctx);
        
        int done = 0;
        uint32_t frame_size = 10240;
        uint64_t readFileSize = fileSize;
        uint32_t readBufferSize = readFileSize < frame_size ? (uint32_t)readFileSize : frame_size;
        uint8_t* bufferData = (uint8_t*)malloc(sizeof(uint8_t) * readBufferSize);
        while (!done) {
            uint32_t dataLength = readFileSize < readBufferSize ? (uint32_t)readFileSize : readBufferSize;
            read_size = read(file_handle,bufferData,dataLength);
            CC_MD5_Update(&ctx, bufferData, (CC_LONG)read_size);
            if (readFileSize <= read_size) {
                done = 1;
            } else {
                readFileSize -= read_size;
            }
        }
        
        if (bufferData != NULL) {
            free(bufferData);
            bufferData = NULL;
        }
        
        unsigned char digest[CC_MD5_DIGEST_LENGTH];
        CC_MD5_Final(digest, &ctx);
        
        char buf[33];
        for (int i=0; i<16; i++)
            sprintf(buf+i*2, "%02x", digest[i]);
        buf[32]=0;
        int result = strncmp(buf, md5, strlen(md5));
        
        if(file_handle > 0) {
            close(file_handle);
        }
        return result == 0;
    }
    
fail:
#ifdef DEBUG
    printf("open file fail! \n");
#endif
    origin_file_size = 0;
    if(file_handle > 0) {
        close(file_handle);
    }
    return 0;
}

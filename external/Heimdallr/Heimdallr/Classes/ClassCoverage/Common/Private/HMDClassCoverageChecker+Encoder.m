//
//  HMDClassCoverageChecker+Encoder.m
//  Heimdallr-30fca18e
//
//  Created by kilroy on 2020/6/14.
//

#import "HMDClassCoverageChecker+Encoder.h"
#import "HMDALogProtocol.h"
#include "HMDMacro.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"

static const int fileMaxBytesNums = 10 * HMD_MB;
//varint编码针对unsingned long 且小端
static const int MAXBYTENUMS = 10;
static const char MSB = 0x80;
static const char MSBALL = ~0x7F;

void varint_encode(unsigned long int n, char* buf, int len, unsigned char* bytes) {
    char* ptr = buf;
    while (n & MSBALL) {
        *(ptr++) = (n & 0xFF) | MSB;
        n = n >> 7;
        if (!((ptr - buf) < len)) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr",@"Failed due to writing over specified address range.");
            *buf = 0x00;
            *bytes = 1;
            return;
        }
    }
    *ptr = n;
    if (bytes != NULL)
        *bytes = ptr - buf + 1;
}


@implementation HMDClassCoverageChecker (Encoder)

+ (NSData *)encodeIntoPBDataWithDict:(NSDictionary *)dic {
    
    size_t currentSize = 0;
    char* allData = (char*)malloc(fileMaxBytesNums);
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr",@"Allocated %d bytes.", fileMaxBytesNums);
    if (allData == NULL) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr",@"Failed to allocate space when writing.");
        return NULL;
    }
    
    NSArray *keys = [dic allKeys];
    NSInteger dicLen = [dic count];
    unsigned char temp[8] = {0xFE,0xAB,0xCC,0x01,0x00,0x00,0x00,0x00};//此处为PB格式帧头
    memcpy(allData, temp, 8);
    currentSize = currentSize + 8;
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr",@"Begin to encode result.");
    for (NSInteger i = 0; i < dicLen; i++) {
        id key = [keys hmd_objectAtIndex: i];
        id value = [dic hmd_objectForKey:key class:NSNumber.class];
        if (!key || !value) continue;
        //encode data
        const char *key_cstr = [key UTF8String];
        size_t key_len = strlen(key_cstr);
        
        char *pKeyLen = malloc(MAXBYTENUMS*sizeof(char));
        if (pKeyLen == NULL) {
            free(allData);
            return NULL;
        }
        unsigned char btsFirst;
        varint_encode(key_len, pKeyLen, MAXBYTENUMS, &btsFirst);
        
        char* isInit = (char*)malloc(MAXBYTENUMS*sizeof(char));
        if (isInit == NULL) {
            free(pKeyLen);
            free(allData);
            return NULL;
        }
        unsigned char btsSecond;
        unsigned long intValue = [value unsignedLongValue];
        varint_encode(intValue, isInit, MAXBYTENUMS, &btsSecond);
        //check if size to be write is bigger than remain size
        unsigned long int sizetemp = (int)btsFirst + (int)key_len + (int)btsSecond;
        if (sizetemp + currentSize > fileMaxBytesNums) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr",@"Failed since that Class Coverage File exceeds the limits of 10MB.");
            free(allData);
            free(pKeyLen);
            free(isInit);
            return NULL;
        }
        memcpy(allData + currentSize, pKeyLen, (int)btsFirst);//store the length of ClassName
        currentSize = currentSize + (int)btsFirst;
        memcpy(allData + currentSize, key_cstr, key_len);//store ClassName
        currentSize = currentSize + key_len;
        memcpy(allData+currentSize, isInit, (int)btsSecond);//store Varint(isInit)
        currentSize = currentSize + (int)btsSecond;
        free(pKeyLen);
        free(isInit);
    }
    NSData *data = [NSData dataWithBytes:allData length:currentSize];
    free(allData);
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr",@"Result has been encoded and memory freed.");
    return data;
}

@end

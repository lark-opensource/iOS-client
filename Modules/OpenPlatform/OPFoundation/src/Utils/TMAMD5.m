//
//  HTSMD5.m
//  Pods
//
//  Created by Gavin on 2017/2/15.
//
//

#import "TMAMD5.h"
#import <CommonCrypto/CommonDigest.h>

#define CHUNK_SIZE 1024 * 8

@interface TMAMD5 () 

@end

@implementation TMAMD5

+ (NSString *)getMD5withURL:(NSURL *)fileURL {
    return [TMAMD5 getMD5withPath:[fileURL path]];
}

+ (NSString *)getMD5withPath:(NSString *)filePath {
    // lint:disable:next lark_storage_check
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if (handle == nil)
        return nil;

    CC_MD5_CTX md5Calculater;
    CC_MD5_Init(&md5Calculater);

    BOOL done = NO;
    while (!done) {
        @autoreleasepool {
            NSData *fileData = [handle readDataOfLength:CHUNK_SIZE];
            CC_MD5_Update(&md5Calculater, [fileData bytes], (CC_LONG)[fileData length]);
            if ([fileData length] == 0)
                done = YES;
        }
    }

    unsigned char md5Value[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(md5Value, &md5Calculater);

    char md5Array[2 * sizeof(md5Value) + 1];
    for (size_t i = 0; i < CC_MD5_DIGEST_LENGTH; ++i) {
        snprintf(md5Array + (2 * i), 3, "%02x", (int) (md5Value[i]));
    }

    [handle closeFile];

    NSString *MD5Str = [NSString stringWithFormat:@"%s", md5Array];


    return MD5Str;
}

@end

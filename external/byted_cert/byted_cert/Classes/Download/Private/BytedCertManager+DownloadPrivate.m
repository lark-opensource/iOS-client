//
//  BytedCertManager+DownloadPrivate.m
//  byted_cert-Pods-AwemeCore
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/12.
//

#import "BytedCertManager+DownloadPrivate.h"
#import <sys/utsname.h>
#import <CommonCrypto/CommonDigest.h>


@implementation BytedCertManager (DownloadPrivate)

+ (NSString *)getModelByPre:(NSString *)path pre:(NSString *)pre {
    return [self getResourceByPath:path pre:pre suffix:@"model"];
}

+ (NSString *)getResourceByPath:(NSString *)path pre:(NSString *)pre suffix:(NSString *)suffix {
    NSFileManager *fileManger = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = [fileManger fileExistsAtPath:path isDirectory:&isDir];
    if (isExist) {
        if (isDir) {
            NSArray *dirArray = [fileManger contentsOfDirectoryAtPath:path error:nil];
            NSString *subPath = nil;
            for (NSString *str in dirArray) {
                subPath = [path stringByAppendingPathComponent:str];
                BOOL issubDir = NO;
                [fileManger fileExistsAtPath:subPath isDirectory:&issubDir];
                if ([str hasPrefix:pre]) {
                    if ([str hasSuffix:suffix])
                        return subPath;
                }
            }
        } else {
            NSLog(@"this path is not dir!");
        }
    } else {
        NSLog(@"this path is not exist!");
    }
    return nil;
}

+ (bool)checkMd5:(NSString *)filePath md5:(NSString *)md5Str {
    //生成文件的MD5   校验的是压缩包的MD5  判断下载是否正确
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if (handle == nil) {
        NSLog(@"文件出错");
        return NO;
    }

    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    BOOL done = NO;
    while (!done) {
        NSData *fileData = [handle readDataOfLength:256];
        CC_MD5_Update(&md5, [fileData bytes], [fileData length]);
        if ([fileData length] == 0)
            done = YES;
    }
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5);
    NSString *fileMD5 = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                                                   digest[0], digest[1],
                                                   digest[2], digest[3],
                                                   digest[4], digest[5],
                                                   digest[6], digest[7],
                                                   digest[8], digest[9],
                                                   digest[10], digest[11],
                                                   digest[12], digest[13],
                                                   digest[14], digest[15]];
    return [md5Str containsString:fileMD5];
}

@end

//
//  IESMetadataUtils.m
//  IESMetadataStorage
//
//  Created by 陈煜钏 on 2021/1/26.
//

#import "IESMetadataUtils.h"

#include <sys/stat.h>

#import "IESMetadataLog.h"

int IESMetadataGetFileSize (int fd)
{
    struct stat st = {};
    if (fstat(fd, &st) != -1) {
        return (int)st.st_size;
    }
    return 0;
}

BOOL IESMetadataFillFileWithZero (int fd, int location, int length)
{
    if (fd < 0) {
        return NO;
    }
    if (lseek(fd, location, SEEK_SET) < 0) {
        IESMetadataLogError("fail to lseek fd[%d], %s", fd, strerror(errno));
        return NO;
    }
    
    int left = length;
    static const char zeros[4096] = {};
    while (left >= sizeof(zeros)) {
        if (write(fd, zeros, sizeof(zeros)) < 0) {
            IESMetadataLogError("fail to write fd[%d], %s", fd, strerror(errno));
            return NO;
        }
        left -= sizeof(zeros);
    }
    if (left > 0) {
        if (write(fd, zeros, left) < 0) {
            IESMetadataLogError("fail to write fd[%d], %s", fd, strerror(errno));
            return NO;
        }
    }
    return YES;
}

void IESMetadataCheckFileProtection (NSString *filePath)
{
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL];
    NSString *protection = attributes[NSFileProtectionKey];
    if ([protection isEqualToString:NSFileProtectionCompleteUntilFirstUserAuthentication]) {
        return;
    }
    NSMutableDictionary *updatedAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
    updatedAttributes[NSFileProtectionKey] = NSFileProtectionCompleteUntilFirstUserAuthentication;
    NSError *error = nil;
    if (![[NSFileManager defaultManager] setAttributes:[updatedAttributes copy] ofItemAtPath:filePath error:&error]) {
        IESMetadataLogError("fail to set file protection from %@ on [%@], %@",
                            protection, filePath, error.localizedDescription);
    }
}

//
//  HMDFileTool.m
//  Pods
//
//  Created by maniackk on 2021/7/29.
//

#import "HMDFileTool.h"
#include <sys/stat.h>
#import "NSArray+HMDSafe.h"

BOOL hmdCheckAndCreateDirectory(NSString *directory) {
    if (directory.length == 0) {
        return NO;
    }
    
    NSString *tmp = directory;
    NSMutableArray *components = [NSMutableArray array];
    while (access([tmp fileSystemRepresentation], F_OK) != 0) {
        NSString *c = [tmp lastPathComponent];
        tmp = [tmp stringByDeletingLastPathComponent];
        [components hmd_addObject:c];
    }
    while (components.count > 0) {
        NSString *c = [components lastObject];
        tmp = [tmp stringByAppendingPathComponent:c];
        if (mkdir(tmp.UTF8String, S_IRWXU) != 0) {
            return NO;
        }
        [components removeLastObject];
    }
    return YES;
}

bool HMDFileAllocate(int fd, size_t length, int *error) {
    fstore_t store = {F_ALLOCATECONTIG, F_PEOFPOSMODE, 0, length};
    // Try to get a continous chunk of disk space
    int ret = fcntl(fd, F_PREALLOCATE, &store);
    if (-1 == ret) {
        // OK, perhaps we are too fragmented, allocate non-continuous
        store.fst_flags = F_ALLOCATEALL;
        ret = fcntl(fd, F_PREALLOCATE, &store);
        if (error != NULL) *error = errno;
        if (-1 == ret) return false;
    }
    return 0 == ftruncate(fd, length);
}

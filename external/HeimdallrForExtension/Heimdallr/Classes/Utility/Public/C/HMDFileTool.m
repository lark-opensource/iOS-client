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

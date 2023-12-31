//
//  file_fragment_util.mm
//  FFFileFragment
//
//  Created by zhouyang11 on 2022/6/7.
//

#include "hmd_file_fragment_util.h"
#include "hmd_slardar_malloc_remap.h"
#import <Foundation/Foundation.h>
#import "HeimdallrUtilities.h"
#import "HMDFileTool.h"
#include <functional>
#include <sys/stat.h>
#include <string>

namespace HMDMemoryAllocator {

const char* mmap_file_tmp_path(const char* identifier) {
    NSString* tmpDirectoryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"hmd_mmap_allocator_tmp"];
    hmdCheckAndCreateDirectory(tmpDirectoryPath);
    NSString *tmpFile = [NSString stringWithFormat:@"mmap_file_%s", identifier];
    const char* tmpPath = [[tmpDirectoryPath stringByAppendingPathComponent:tmpFile] cStringUsingEncoding:NSUTF8StringEncoding];
    return strdup(tmpPath);
}
}

void methoda(void) {
    extern void vmrecorder_enumerator(const char* identifier);
    vmrecorder_enumerator(nullptr);
}

@interface HMDSMOC:NSObject
@end
@implementation HMDSMOC
@end

//
//  HMDClassCoverageChecker.m
//  Pods
//
//  Created by kilroy on 2020/6/10.
//

#import <objc/runtime.h>
#import <sys/time.h>
#include <string>
#include <map>

#import "HMDClassCoverageChecker.h"
#import "HMDClassCoverageChecker+Encoder.h"
#import "HMDClassCoverageDefine.h"
#import "HMDClassCoverageUploader.h"
#import "HMDALogProtocol.h"
#import "HMDGCD.h"
#import "HMDMacro.h"
#import "HMDCompactUnwind.hpp"
// PrivateServices
#import "HMDServerStateService.h"

@interface HMDClassCoverageChecker ()

@property (atomic, assign, readwrite) BOOL isChecking;
@property (nonatomic, assign) int count;
@property (nonatomic, copy, nullable) NSDictionary *allClassInfo;
@property (nonatomic, strong) dispatch_queue_t checkerQueue;
@property (nonatomic, strong) dispatch_source_t timer;

@end

@implementation HMDClassCoverageChecker

- (instancetype)init {
    if (self = [super init]) {
        _checkerQueue = dispatch_queue_create("com.heimdallr.classcoverage.checker", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)activateByConfig:(NSTimeInterval)checkInterval {
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, checkInterval * NSEC_PER_SEC);
    hmd_safe_dispatch_async(self.checkerQueue, ^{
        if (!self.timer) {
            self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.checkerQueue);
            if (!self.timer) return;
            
            dispatch_source_set_timer(self.timer, startTime, checkInterval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
            __weak __typeof(self) wself = self;
            dispatch_source_set_event_handler(self.timer, ^{
                __strong __typeof(wself) sself = wself;
                [sself checkClassesPeriodly];
            });
            dispatch_resume(self.timer);
        }
        else {
            dispatch_source_set_timer(self.timer, startTime, checkInterval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
        }
    });
}

- (void)invalidate {
    hmd_safe_dispatch_async(self.checkerQueue, ^{
        if (self.timer) {
            dispatch_source_cancel(self.timer);
            self.timer = nil;
        }
    });
}

- (void)checkClassesPeriodly {
    if (self.isChecking) {
        return;
    }
    // drop date due to disaster recovery strategy
    if (!hmd_drop_data(HMDReporterClassCoverage)) {
        [self checkAllClass];
    }
}

- (void)checkAllClass {
    self.isChecking = YES;
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr",@"Begin to check initialzation of all classes.");
    NSMutableDictionary *m_clzes_info = @{}.mutableCopy;
    self.count = 0;
    hmd_enumerate_app_image_list_using_block(^(hmd_async_image_t *image, int index, bool *stop) {
        const char* imageName = image->macho_image.name;
        if (!imageName) return;
        NSString *imgName = [[NSString stringWithUTF8String:imageName] lastPathComponent];
        unsigned int count = 0;
        self.count += count;
        const char **classes  = objc_copyClassNamesForImage(imageName, &count);
        for (int i = 0; i < count; i++) {
            @autoreleasepool {
                if (classes[i]) {
                    V_Class meta_clz = (__bridge V_Class)objc_getMetaClass(classes[i]);
                    NSString *clzName = [NSString stringWithUTF8String:classes[i]];
                    if (meta_clz && clzName) {
                        bool initStatus = meta_clz->isInitialized();
                        NSNumber *isInit = [NSNumber numberWithBool:initStatus];
                        NSString *finalName = [NSString stringWithFormat:@"%@:%@", imgName, clzName];
                        if (m_clzes_info && isInit && finalName)
                            m_clzes_info[finalName] = isInit;
                    }
                }
            }
        }
        free(classes);
    });
    self.allClassInfo = m_clzes_info.copy;
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr",@"Initialization of all classes has been checked.");
    [self dumpToFile];
    self.isChecking = NO;
}

#pragma mark - File Store

//write class coverage data into a new file
- (void)dumpToFile {
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr",@"Begin to dump result to file.");
    NSError *error;
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString *dirPath = [HMDClassCoverageUploader classCoveragePath];
    if (!self.allClassInfo){
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr",@"Failed due to no data.");
        return;
    }
    
    if (![fileManager fileExistsAtPath:dirPath]) {
        //create directory
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath
                                  withIntermediateDirectories:YES
                                                   attributes:@{NSFileProtectionKey : NSFileProtectionNone}
                                                        error:&error];
        //check if directory is created successfully
        if (error != nil) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr",@"Failed to create directory: %@", error);
            [[NSFileManager defaultManager] removeItemAtPath:[HMDClassCoverageUploader classCoveragePath] error:nil];
        }
    }
    
    HMDLog(@"Class Coverage File Directory: %@",dirPath);
    
    //set extra control items of directory in case that there is a problem occurring when iOS systems writes files
    NSURL *folderURL = [NSURL fileURLWithPath:dirPath];
    [folderURL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:&error];

    NSString *datFilePath = [dirPath stringByAppendingPathComponent:kHMDClassCoverageFileName];
    //encode data with PBData format
    NSData *data = [HMDClassCoverageChecker encodeIntoPBDataWithDict:self.allClassInfo];
    if (data) {
        [HMDClassCoverageUploader cleanFilesInPath:datFilePath];
        [data writeToFile:datFilePath atomically:YES];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr",@"Result saved to file.");
    } else {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr",@"Failed to encode result of class coverage.");
    }
}

@end

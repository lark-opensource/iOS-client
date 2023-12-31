//
//  HMDCrashDirectoryTest.m
//  HMDCrashDirectoryTest
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#include <stdatomic.h>
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"
#include "HMDFileTool.h"
#import "HMDCrashDirectory.h"
#import "HMDCrashDirectory+Private.h"
#import "HMDCrashDirectory+Path.h"
#import "HMDCrashEnvironmentBinaryImages.h"
#import "HMDCrashDirectoryTest.h"
#import "HMDCrashTracker.h"
#import "HMDInjectedInfo.h"

#include "HMDCrashDirectory.dynamic.inc"
#include "HMDCrashDirectory.exception.inc"
#include "HMDCrashDirectory.image.main.inc"
#include "HMDCrashDirectory.memory.inc"
#include "HMDCrashDirectory.meta.inc"
#include "HMDCrashDirectory.sdk_info.inc"
#include "HMDCrashDirectory.vmmap.inc"

@implementation HMDCrashDirectoryTest

+ (void)setUp    { /* 在所有测试前调用一次 */ }
+ (void)tearDown { /* 在所有测试后调用一次 */ }
- (void)setUp    { /* 在每次 -[ test_xxx] 方法前调用 */ }
- (void)tearDown { /* 在每次 -[ test_xxx] 方法后调用 */ }

- (void)tools_used_when_test {
    // Expectation
    XCTestExpectation *expectation = [self expectationWithDescription:@"description"];
    [expectation fulfill];
    [self waitForExpectationsWithTimeout:3 handler:nil];
    
    // Assert
    XCTAssert(nil, @"NSLog format:%@", nil);
}

static const char * crash_directory = "Library/Heimdallr/CrashCapture";

+ (void)generateCrashDataInActiveFolder {
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) return;
    
    NSString *baseDirectory = [[NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithUTF8String:crash_directory]] copy];
    NSString *activeDirectory = [[baseDirectory stringByAppendingPathComponent:@"Active"] copy];  // copy is must ⚠️
    
    NSFileManager *manager = NSFileManager.defaultManager;
    BOOL isDirectory;
    BOOL isExist = [manager fileExistsAtPath:activeDirectory isDirectory:&isDirectory];
    if(!isExist) hmdCheckAndCreateDirectory(activeDirectory);
    
//    NSArray<NSString *> *contentsAtActive = [manager contentsOfDirectoryAtPath:activeDirectory error:nil];
//
//    for(NSString *eachContentAtActive in contentsAtActive) {
//        NSString *eachPath = [activeDirectory stringByAppendingPathComponent:eachContentAtActive];
//
//    }
    
    {
        NSString *folderPath = [activeDirectory stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
        [manager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        [self write:dynamic length:dynamic_len to:@"dynamic" folder:folderPath];
        
        [self write:exception length:exception_len to:@"exception" folder:folderPath];
        
        [self write:image_main length:image_main_len to:@"image.main" folder:folderPath];
        
        [self write:memory length:memory_len to:@"memory" folder:folderPath];
        
        [self write:meta length:meta_len to:@"meta" folder:folderPath];
        
        [self write:sdk_info length:sdk_info_len to:@"sdk_info" folder:folderPath];
        
        [self write:vmmap length:vmmap_len to:@"vmmap" folder:folderPath];
    }
    
    {
        NSString *folderPath = [activeDirectory stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
        [manager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        [self write:dynamic length:dynamic_len to:@"dynamic" folder:folderPath];
        
        [self write:exception length:exception_len to:@"exception.tmp" folder:folderPath];
        
        [self write:image_main length:image_main_len to:@"image.main" folder:folderPath];
        
        [self write:memory length:memory_len to:@"memory" folder:folderPath];
        
        [self write:meta length:meta_len to:@"meta" folder:folderPath];
        
        [self write:sdk_info length:sdk_info_len to:@"sdk_info" folder:folderPath];
        
        [self write:vmmap length:vmmap_len to:@"vmmap" folder:folderPath];
    }
}

+ (void)write:(const unsigned char *)data length:(unsigned int)length to:(NSString *)fileName folder:(NSString *)folderPath {
    NSString *path = [folderPath stringByAppendingPathComponent:fileName];
    [[NSData dataWithBytes:data length:length] writeToFile:path options:NSDataWritingAtomic error:nil];
}

- (void)test_lastTimeDirectory {
    
    NSFileManager *manager = NSFileManager.defaultManager;
    BOOL isDirectory;
    
    [HMDCrashDirectoryTest generateCrashDataInActiveFolder];
    
    HMDInjectedInfo.defaultInfo.appID = @"492373";
    if(!HMDCrashTracker.sharedTracker.isRunning)
        [HMDCrashTracker.sharedTracker start];
    //    [HMDCrashDirectory setup];
    
    // LastTime Directory
    NSString * _Nullable lastTimeDirectory = HMDCrashDirectory.lastTimeDirectory;
    XCTAssert(lastTimeDirectory != nil);
    
    // Contents of LastTime Directory
    // Folder with UUID <27F32EC2-3EEE-4F8D-A5D6-B80641407F24>
    NSArray<NSString *> * contents = [manager contentsOfDirectoryAtPath:lastTimeDirectory error:nil];
    XCTAssert(contents.count != 0);
    
    // crashDataPath consist of binaryImage SDKLog etc.
    NSString *crashDataDirectory = [lastTimeDirectory stringByAppendingPathComponent:contents.firstObject];
    
    XCTAssert([manager fileExistsAtPath:crashDataDirectory isDirectory:&isDirectory]);
    
    XCTAssert(isDirectory);
    
    HMDImageOpaqueLoader *imageLoader = [[HMDImageOpaqueLoader alloc] initWithDirectory:crashDataDirectory];
    
    // Access all images using this method
    NSArray<HMDCrashBinaryImage *> * _Nullable images = imageLoader.currentlyUsedImages;
    
    XCTAssert(images.count > 0);
}

@end

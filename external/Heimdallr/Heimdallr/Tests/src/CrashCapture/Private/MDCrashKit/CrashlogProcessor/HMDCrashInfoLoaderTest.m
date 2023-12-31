//
//  HMDCrashInfoLoaderTest.m
//  HMDCrashInfoLoaderTest
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"
#import "HMDCrashInfoLoader.h"
#include <sys/stat.h>
#include <mach/vm_statistics.h>
#include "HMDMacro.h"
#include "HMDCrashDynamicSavedFiles.h"
#import "HMDCrashInfoLoader.h"
#import "NSString+HMDJSON.h"
#import "NSString+HMDCrash.h"
#import "HMDInvalidThreadsJSONParser.h"
#import "NSString+HMDSafe.h"
#import "HMDCrashRegisterAnalysis.h"
#import "HMDCrashStackAnalysis.h"
#import "HMDCrashVMRegion.h"

@interface HMDCrashInfo (Equal)

- (NSUInteger)hash;
- (BOOL)isEqual:(id)object;

@end

@implementation HMDCrashInfo (Equal)

- (NSUInteger)hash {
    return self.meta.UUID.hash;
}

- (BOOL)isEqual:(id)object {
    if(![object isKindOfClass:HMDCrashInfo.class]) return NO;
    HMDCrashInfo *another = object;
    if(![self.meta isEqual:another.meta]) return NO;
    return YES;
}

@end


@interface HMDCrashMetaData (Equal)

- (NSUInteger)hash;
- (BOOL)isEqual:(id)object;

@end

@implementation HMDCrashMetaData (Equal)

- (NSUInteger)hash {
    return self.UUID.hash;
}

- (BOOL)isEqual:(id)object {
    
#define MY_ASSERT(something) \
    XCTAssert(something, @"%s", #something)
    
    HMDCrashMetaData *another = object;
    
    MY_ASSERT([object isKindOfClass:HMDCrashMetaData.class]);
    MY_ASSERT([self.UUID isEqual:another.UUID]);
    MY_ASSERT(self.exceptionMainAddress == another.exceptionMainAddress);
    MY_ASSERT([self.processName isEqual:another.processName]);
    MY_ASSERT([self.osFullVersion isEqual:another.osFullVersion]);
    MY_ASSERT([self.bundleID isEqual:another.bundleID]);
    MY_ASSERT([self.appVersion isEqual:another.appVersion]);
    MY_ASSERT([self.osBuildVersion isEqual:another.osBuildVersion]);
    MY_ASSERT(self.startTime == another.startTime);
    MY_ASSERT(self.processID == another.processID);
    MY_ASSERT([self.commitID isEqual:another.commitID]);
    MY_ASSERT(self.isMacARM == another.isMacARM);
    MY_ASSERT([self.arch isEqual:another.arch]);
    MY_ASSERT(self.physicalMemory == another.physicalMemory);
    MY_ASSERT([self.osVersion isEqual:another.osVersion]);
    MY_ASSERT([self.osVersion isEqual:another.osVersion]);
    MY_ASSERT([self.bundleVersion isEqual:another.bundleVersion]);
    MY_ASSERT([self.deviceModel isEqual:another.deviceModel]);

    return YES;
}

@end

@interface NSDictionary (six_six_six)
@end

@implementation NSDictionary (six_six_six)

- (NSData *)jsonData {
    return [NSJSONSerialization dataWithJSONObject:self options:0 error:nil];
}

- (void)writeJsonToFile:(NSString *)filePath {
    [[self jsonData] writeToFile:filePath atomically:YES];
}

+ (NSDictionary *)randomMeta:(HMDCrashInfo *)info {
    NSString *UUID = NSUUID.UUID.UUIDString;
    uint64_t exception_main_address = arc4random();
    NSString *process_name = NSUUID.UUID.UUIDString;
    NSString *os_full_version = NSUUID.UUID.UUIDString;
    NSString *bundle_id = NSUUID.UUID.UUIDString;
    NSString *app_version = NSUUID.UUID.UUIDString;
    NSString *sdk_version = NSUUID.UUID.UUIDString;
    NSString *os_build_version = NSUUID.UUID.UUIDString;
    double start_time = (double)(arc4random() % 10086);
    uint64_t process_id = arc4random();
    NSString *commit_id = NSUUID.UUID.UUIDString;
    BOOL is_mac_arm = arc4random() % 2 == 0 ? YES : NO;
    NSString *arch = NSUUID.UUID.UUIDString;
    uint64_t physical_memory = arc4random();
    NSString *os_version = NSUUID.UUID.UUIDString;
    NSString *bundle_version = NSUUID.UUID.UUIDString;
    NSString *device_model = NSUUID.UUID.UUIDString;
    
    
    HMDCrashMetaData *meta = [HMDCrashMetaData new];
    meta.UUID = UUID;
    meta.exceptionMainAddress = exception_main_address;
    meta.processName = process_name;
    meta.osFullVersion = os_full_version;
    meta.bundleID = bundle_id;
    meta.appVersion = app_version;
    meta.sdkVersion = sdk_version;
    meta.osBuildVersion = os_build_version;
    meta.startTime = start_time;
    meta.processID = process_id;
    meta.commitID = commit_id;
    meta.isMacARM = is_mac_arm;
    meta.arch = arch;
    meta.physicalMemory = physical_memory;
    meta.osVersion = os_version;
    meta.bundleVersion = bundle_version;
    meta.deviceModel = device_model;
    
    info.meta = meta;
    
    return @{
        @"meta": @{
            @"uuid": UUID,
            @"exception_main_address": @(exception_main_address),
            @"process_name": process_name,
            @"os_full_version": os_full_version,
            @"bundle_id": bundle_id,
            @"app_version": app_version,
            @"sdk_version": sdk_version,
            @"os_build_version": os_build_version,
            @"start_time": @(start_time),
            @"process_id": @(process_id),
            @"commit_id": commit_id,
            @"is_mac_arm": @(is_mac_arm),
            @"arch": arch,
            @"physical_memory": @(physical_memory),
            @"os_version": os_version,
            @"bundle_version": bundle_version,
            @"device_model": device_model
        }
    };
}

@end


@interface HMDCrashInfoLoaderTest : XCTestCase

@end

@implementation HMDCrashInfoLoaderTest

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

- (NSString *)generateRandomInputDirectory {
    NSString *path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    
    [NSFileManager.defaultManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    
    return path;
}

- (void)test_equal {
    NSString *inputDir = [self generateRandomInputDirectory];
    HMDCrashInfo *info = HMDCrashInfo.new;
    [[NSDictionary randomMeta:info] writeJsonToFile:[inputDir stringByAppendingPathComponent:@"meta"]];
    
    HMDCrashInfoLoader *loader = HMDCrashInfoLoader.new;
    HMDCrashInfo *anotherInfo = HMDCrashInfo.new;
    [HMDCrashInfoLoaderTest parseMetaFile:anotherInfo inputDir:inputDir];
    
    XCTAssert([info isEqual:anotherInfo], @"not equal");
}

+ (void)parseMetaFile:(HMDCrashInfo *)info inputDir:(NSString *)inputDir {

    NSString *fileName = @"meta";
    
//    [info info:@"start process %@",fileName];
    
    NSString *path = [inputDir stringByAppendingPathComponent:fileName];
    
    NSString *content = [self loadFileContent:path info:info];
    
    NSDictionary *dict = [content hmd_jsonDict];
    
    if (dict.count == 0) {
//        [info error:@"meta content:\n%@", content];
        return;
    }
    
    HMDCrashMetaData *meta = [HMDCrashMetaData objectWithDictionary:dict];
    info.meta = meta;
}

+ (NSString * _Nullable)loadFileContent:(NSString *)path info:(HMDCrashInfo *)info {
    
    NSError *  _Nullable error = nil;
    NSString * _Nullable content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    if(content.length > 0) return content;
    
    info.fileIOError = YES;
    
    NSString *fileName = path.lastPathComponent;
    
    if(error != nil) [info error:@"%@ load error: %@", fileName, error.localizedDescription];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [info error:@"%@ file is missing", fileName];
        info.isCorrupted = YES;
        return nil;
    }
    
    error = nil;
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    
    if(error != nil) {
        [info error:@"%@ load error: %@", path.lastPathComponent, error.localizedDescription];
        return nil;
    }
    
    [info error:@"%@ file corrupted, file_size:%llu createDate:%@", fileName, attributes.fileSize, attributes.fileCreationDate];
    
    info.isCorrupted = YES;
    
    return nil;
}

@end

//
//  HMDBootingProtectionTests.m
//  HMDBootingProtectionTests
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#include <sys/dirent.h>
#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDMacro.h"
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"
#import "HMDCrashDirectoryTest.h"
#import "HMDCrashTracker.h"
#import "HMDInjectedInfo.h"
#import "HMDBootingProtection.h"

#pragma mark - NSMutableString (Indention) 声明开始

@interface NSMutableString (Indention)

- (void)test_indent:(NSUInteger)indent appendFormat:(NSString *)format, ... __attribute__((format(NSString, 2, 3)));

@end

#pragma mark NSMutableString (Indention) 声明结束

static void FCSRW_show_directory_content(const char * _Nullable directory);

static BOOL forceHeimdallrPretendedWorking = NO;

@interface HMDBootingProtectionTests : XCTestCase

@end

@implementation HMDBootingProtectionTests

+ (void)setUp    {
    HMD_mockClassTreeForInstanceMethod(Heimdallr, enableWorking, ^BOOL (id thisSelf) {
        if(forceHeimdallrPretendedWorking) return YES;
        return DC_IS(DC_OB(thisSelf, MOCK_enableWorking), NSNumber).boolValue;
    });
}
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

- (void)test_launchCrashDetectionSuccess {
    HMDInjectedInfo.defaultInfo.appID = @"4025";
    [HMDCrashDirectoryTest generateCrashDataInActiveFolder];
    if(!HMDCrashTracker.sharedTracker.isRunning)
        [HMDCrashTracker.sharedTracker start];
    
    uint32_t makeCount = arc4random() % 10 + 1;
    
    static NSString *launchFileRelativePath = @"Library/Heimdallr/BootingProtect/LastTimeLaunchExit";
    static NSString *crashCountPath = @"Library/Heimdallr/BootingProtect/CrashFiles";
    
    [self createFolderAtRelativePath:launchFileRelativePath appendRandomPath:NO];
    
    FCSRW_show_directory_content([NSHomeDirectory() stringByAppendingPathComponent:crashCountPath].UTF8String);
    
    [self clearContentOfReleativeDirectory:crashCountPath];
    
    FCSRW_show_directory_content([NSHomeDirectory() stringByAppendingPathComponent:crashCountPath].UTF8String);
    
    for(uint32_t index = 0; index < makeCount; index++) {
        [self createFolderAtRelativePath:crashCountPath appendRandomPath:YES];
    }
    
    FCSRW_show_directory_content([NSHomeDirectory() stringByAppendingPathComponent:crashCountPath].UTF8String);
    
    [HMDBootingProtection startProtectWithLaunchTimeThreshold:5 handleCrashBlock:^(NSInteger successiveCrashCount) {
        XCTAssert(makeCount + 1 == successiveCrashCount);
    }];
}

- (void)test_crashDetectionCouldBeReported_method {
    HMDInjectedInfo.defaultInfo.appID = @"4025";
    [HMDCrashDirectoryTest generateCrashDataInActiveFolder];
    if(!HMDCrashTracker.sharedTracker.isRunning)
        [HMDCrashTracker.sharedTracker start];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"appExitReasonWithLaunchCrashTest"];
    
    forceHeimdallrPretendedWorking = YES;
    [HMDBootingProtection appExitReasonWithLaunchCrashTimeThreshold:5 handleBlock:^(HMDApplicationRelaunchReason reason, NSUInteger frequency, BOOL isLaunchCrash) {
        XCTAssert(reason == HMDApplicationRelaunchReasonCrash);
        [expectation fulfill];
    }];
    forceHeimdallrPretendedWorking = NO;
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)clearContentOfReleativeDirectory:(NSString *)path {
    path = [NSHomeDirectory() stringByAppendingPathComponent:path];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [manager contentsOfDirectoryAtPath:path error:nil];
    for (NSString *fileName in files) {
        NSString *filePath = [path stringByAppendingPathComponent:fileName];
        [manager removeItemAtPath:filePath error:nil];
    }
}

- (void)createFolderAtRelativePath:(NSString * _Nonnull)relativePath appendRandomPath:(BOOL)append {
    DEBUG_ASSERT(relativePath != nil);
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:relativePath];
    if(append) {
        path = [path stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    }
    
    [self findOrCreateDirectoryInPath:path];
}

- (BOOL)findOrCreateDirectoryInPath:(NSString *)path {
    
    NSFileManager *mgr = [NSFileManager defaultManager];
    BOOL isDic;
    BOOL isEst = [mgr fileExistsAtPath:path isDirectory:&isDic];
    if(isEst) {
        if(isDic) return YES;
    }
    else
        return [mgr createDirectoryAtPath:path
              withIntermediateDirectories:YES
                               attributes:nil
                                    error:nil];
    return NO;
}


@end

#pragma mark - show directory 定义开始

static void FCSRW_show_directory_content_internal(const char * _Nullable directory,
                                                  NSMutableString *result,
                                                  size_t indentation,
                                                  size_t indentation_increase_next);

static void FCSRW_show_directory_content(const char * _Nullable directory) {
    NSMutableString *result = NSMutableString.string;
    
    if(directory == NULL) {
        [result appendString:@"[FCSRW][DIR] path is NULL\n"];
        goto output_string;
    }
    
    [result appendFormat:@"[FCSRW][DIR] %s\n", directory];
    
    FCSRW_show_directory_content_internal(directory, result, 2, 2);
    
output_string:
    fprintf(stdout, "%s\n", result.UTF8String);
    fflush(stdout);
}

static void FCSRW_show_directory_content_internal(const char * _Nullable directory,
                                                  NSMutableString *result,
                                                  size_t indentation,
                                                  size_t indentation_increase_next) {
    DIR * _Nullable directory_opaque = NULL;
    if((directory_opaque = opendir(directory)) == NULL) {
        [result test_indent:indentation appendFormat:@"[open directory failed]\n"];
        return;
    }
    
    BOOL hasAnyContent = NO;
    
    struct dirent *content;
    while((content = readdir(directory_opaque)) != NULL) {
        
        
        uint16_t nameLength = content->d_namlen;
        const char *name = content->d_name;
        uint8_t type = content->d_type;
        
        if((nameLength == 1 || nameLength == 2) && type == DT_DIR && (strcmp(name, ".") == 0 || strcmp(name, "..") == 0))
            continue;
        
        hasAnyContent = YES;
        
        const char *fileType;
        switch (type) {
            default:
            case DT_UNKNOWN:
                fileType = "unknown_type";
                break;
            case DT_FIFO:
                fileType = "FIFO";
                break;
            case DT_CHR:
                fileType = "character_device";
                break;
            case DT_DIR:
                fileType = "D";
                break;
            case DT_BLK:
                fileType = "block_device";
                break;
            case DT_REG:
                fileType = "F";
                break;
            case DT_LNK:
                fileType = "symbolic_link";
                break;
            case DT_SOCK:
                fileType = "local_domain_socket";
                break;
            case DT_WHT:
                fileType = "whiteout";
                break;
        }
        
        [result test_indent:indentation appendFormat:@"[%s]%s\n", fileType, name];
        
        if(type == DT_DIR) {
            NSString *next_directory_path = [NSString stringWithCString:directory encoding:NSUTF8StringEncoding];
            NSString *next_directory_name = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
            next_directory_path = [next_directory_path stringByAppendingPathComponent:next_directory_name];
            
            FCSRW_show_directory_content_internal(next_directory_path.UTF8String, result,
                                                  indentation + indentation_increase_next,
                                                  indentation_increase_next);
        }
    }
    
    closedir(directory_opaque);
}

#pragma mark show directory 定义结束

#pragma mark - NSMutableString (Indention) 定义开始

@implementation NSMutableString (Indention)

- (void)test_indent:(NSUInteger)indent appendFormat:(NSString *)format, ... {
    va_list ap;
    va_start(ap, format);
    NSString *appended = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end(ap);
    for(NSUInteger index = 0; index < indent; index++)
        [self appendString:@" "];
    [self appendString:appended];
}

@end

#pragma mark NSMutableString (Indention) 定义结束

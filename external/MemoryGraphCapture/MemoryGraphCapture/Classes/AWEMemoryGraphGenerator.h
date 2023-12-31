//
//  AWEMemoryGraphGenerator.h
//  Hello
//
//  Created by brent.shu on 2019/10/20.
//  Copyright © 2019 brent.shu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <mach/mach_types.h>

typedef BOOL(^LockSafeChecker)(void);
typedef NSString* _Nullable (^ThreadNameParser)(thread_t port);

typedef NS_ENUM(NSUInteger, AWEMemoryGraphDegradeType) {
    DegradeTypeNone,//@note:正常
    DegradeTypeNodeOverSize,//@note:节点过多导致降级
    DegradeTypeMemoryIssue//@note:可用内存不足强制降级
};

@interface AWEMemoryGraphGenerateRequest: NSObject

@property (nonatomic,   copy) NSString            * _Nullable path;            // path to persist result. will clear old item at the path
@property (nonatomic, strong) NSNumber            * _Nullable maxMemoryUsage;  // in megabytes, default 100
@property (nonatomic, strong) NSNumber            * _Nullable maxFileSize;     // in megabytes, default 250
@property (nonatomic, assign) BOOL                useNaiveVersion;  // only record clustered result
@property (nonatomic,   copy) LockSafeChecker _Nullable     checker;          // use to check env lock state
@property (nonatomic, strong) NSMutableDictionary * _Nullable jsonOutput;      // resultoutput in json
@property (nonatomic, assign) BOOL                doCppSymbolic;    // do cpp symbolic or not, default NO;
@property (nonatomic, assign) uint64_t            memoryUsageBeforeSuspend;     // memoryUsage when triger memory graph, for double check.
@property (nonatomic, assign) NSUInteger             timeOutDuration;
@property (nonatomic,   copy) ThreadNameParser _Nullable    threadParser;
@property (nonatomic, strong) NSMutableDictionary * _Nullable extraConfiguration;
@end

@interface AWEMemoryGraphGenerator: NSObject

+ (void)generateMemoryGraphWithRequest:(nonnull AWEMemoryGraphGenerateRequest *)request error:(NSError *_Nullable*_Nullable)err_output degrade:(AWEMemoryGraphDegradeType*_Nullable)degrade_type;

+ (BOOL)checkIfHasGraphUnderPath:(nonnull NSString *)path;

@end

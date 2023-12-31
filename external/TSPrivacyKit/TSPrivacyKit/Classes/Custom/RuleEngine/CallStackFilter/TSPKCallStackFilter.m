//
//  TSPKCallStackFilter.m
//  BDAlogProtocol
//
//  Created by bytedance on 2022/7/21.
//

#import "TSPKCallStackFilter.h"
#import "TSPKCallStackRuleInfo.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "TSPKCallStackCacheInfo.h"
#import "TSPKBinaryInfo.h"
#import "TSPKCallStackMacro.h"
#import "TSPKCallStackRuleInfo.h"
#import <PNSServiceKit/PNSBacktraceProtocol.h>
#import "TSPKLock.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKLogger.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

static NSString *allowKey = @"isAllow";
static NSString *disableCacheKey = @"disableCache";
static NSString *contentKey = @"content";
static NSString *rulesKey = @"methods";

@interface TSPKCallStackFilter ()

@property (nonatomic, copy) NSString *appVersion; // update
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) NSMutableDictionary <NSString*, TPSKCallStackDataTypeInfo*> *callStackFilterInfo;
@property (nonatomic, assign) BOOL disableCache;
@property (nonatomic, assign) BOOL isUpdating;
@property (nonatomic, strong) id<TSPKLock> lock;

@end

@implementation TSPKCallStackFilter

+ (instancetype)shared {
    static TSPKCallStackFilter *s_control;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_control = [[TSPKCallStackFilter alloc] init];
    });
    return s_control;
}

- (instancetype)init {
    if (self = [super init]) {
        _lock = [TSPKLockFactory getLock];
        _callStackFilterInfo = [NSMutableDictionary dictionary];
        _queue = dispatch_queue_create("com.tspk.callstack.filter", DISPATCH_QUEUE_SERIAL);
        _appVersion = [[[NSBundle mainBundle] infoDictionary] btd_stringValueForKey:@"CFBundleVersion"]; // build Id
        _isUpdating = NO;
    }

    return self;
}

- (void)parseInfoToRules:(nonnull NSDictionary *)info {
    [info enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSDictionary *_Nonnull dataTypeInfoDic, BOOL * _Nonnull stop) {
        TPSKCallStackDataTypeInfo *dataTypeInfo = [TPSKCallStackDataTypeInfo new];
        dataTypeInfo.isAllow = [dataTypeInfoDic btd_boolValueForKey:allowKey ];
        NSArray *rules = [dataTypeInfoDic btd_arrayValueForKey:rulesKey];

        NSMutableArray *mutableRules = [NSMutableArray arrayWithCapacity:rules.count];

        [rules enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull methodInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            TSPKCallStackRuleInfo *methodInfoObj = [[TSPKCallStackRuleInfo alloc] initWithDictionary:methodInfo];
            [mutableRules addObject:methodInfoObj];
        }];

        dataTypeInfo.rules = mutableRules;
        self.callStackFilterInfo[key] = dataTypeInfo;
    }];
}

/// add other info - end slide and binary name
- (BOOL)fixRules {
    BOOL useCache = !self.disableCache;

    if (useCache) {
        [self fixWithCache];
    }

    NSMutableArray *mutableRules = [NSMutableArray array];
    [self.callStackFilterInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, TPSKCallStackDataTypeInfo * _Nonnull dataTypeInfo, BOOL * _Nonnull stop) {
        [dataTypeInfo.rules sortUsingSelector:@selector(compare:)]; // sort
        if (dataTypeInfo.rules.count > 0) {
            [mutableRules addObjectsFromArray:dataTypeInfo.rules];
        }
    }];

    [mutableRules sortUsingSelector:@selector(compare:)]; // sort
    BOOL hadUpdateRules = [[TSPKBinaryInfo sharedInstance] fixSortedRules:mutableRules];

    return hadUpdateRules;
}

- (void)fixWithCache {
    NSDictionary *cache = [[TSPKCallStackCacheInfo sharedInstance] loadWithVersion:self.appVersion];

    [self.callStackFilterInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, TPSKCallStackDataTypeInfo * _Nonnull dataTypeInfo, BOOL * _Nonnull stop) {
        NSDictionary *dataTypeCache = [cache btd_dictionaryValueForKey:key];
        [dataTypeInfo.rules enumerateObjectsUsingBlock:^(TSPKCallStackRuleInfo * _Nonnull methodInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *uniqueKey = [methodInfo uniqueKey];

            NSDictionary *curCache = [dataTypeCache btd_dictionaryValueForKey:uniqueKey];
            methodInfo.binaryName = [curCache btd_objectForKey:TSPKMethodBinaryKey default:nil];
            methodInfo.end = [[curCache btd_objectForKey:TSPKMethodEndKey default:@0] unsignedIntegerValue];
            methodInfo.slide = [[TSPKBinaryInfo sharedInstance] slideOfMachName:methodInfo.binaryName]; // get slide from mach info
            methodInfo.start -= methodInfo.slide;   // start = start - slide
        }];
    }];
}

#pragma mark - public method

- (void)updateWithConfigs:(nonnull NSDictionary *)configs {
    if (BTD_isEmptyDictionary(configs)) {
        return;
    }

    BOOL isUpdating = NO;
    [self.lock lock];
    isUpdating = self.isUpdating;
    if (!isUpdating) {
        self.isUpdating = YES;
    }
    [self.lock unlock];

    if (isUpdating) {
        return;
    }

    self.disableCache = [configs btd_boolValueForKey:disableCacheKey default:NO];
    NSDictionary *info = [configs btd_dictionaryValueForKey:contentKey];

    dispatch_async(self.queue, ^{
        [self parseInfoToRules:info]; // parse dic info to rule models

        BOOL isConfigUpdate = [self fixRules];

        if (isConfigUpdate) {
            [[TSPKCallStackCacheInfo sharedInstance] save:self.callStackFilterInfo forVersion:self.appVersion];
        }

        [self.lock lock];
        self.isUpdating = NO;
        [self.lock unlock];
    });
}

- (BOOL)checkAllowCallWithDataType:(nonnull NSString *)dataType {
//    [TSPKLogger logWithTag:TSPKLogCommonTag message:[NSString stringWithFormat:@"call stack filter is checking, dataType %@", dataType]];

    BOOL isUpdating = NO;
    [self.lock lock];
    isUpdating = self.isUpdating;
    [self.lock unlock];

    if (isUpdating) { // just return if it is updating
//        [TSPKLogger logWithTag:TSPKLogCommonTag message:@"call stack filter is checking, early return YES because config is updating"];
        return YES;
    }
    
    if (self.callStackFilterInfo.allKeys.count == 0) {
        return YES;
    }
        
    // make sure at least one rule is complete
    NSArray <TSPKCallStackRuleInfo *> *methods = self.callStackFilterInfo[dataType].rules;
    
    if (methods.count == 0) {
        return YES;
    }

    __block BOOL isContinueCheck = NO;
    [methods enumerateObjectsUsingBlock:^(TSPKCallStackRuleInfo * _Nonnull rule, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([rule isCompleted]) {
            isContinueCheck = YES;
            *stop = YES;
        }
    }];
    
    if (!isContinueCheck) {
        return YES;
    }
    
    // continue check
    NSArray <NSNumber *> *addresses = [PNS_GET_INSTANCE(PNSBacktraceProtocol) getCurrentBacktraceAddressesWithSkippedDepth:5];
    BOOL isAllow = self.callStackFilterInfo[dataType].isAllow;

    __block BOOL isMatched = NO;
//    [TSPKLogger logWithTag:TSPKLogCommonTag message:[NSString stringWithFormat:@"call stack filter is checking, isAllow %@, rule method count: %@, rules: %@", @(isAllow), @(methods.count), methods]];
    
    [methods enumerateObjectsUsingBlock:^(TSPKCallStackRuleInfo * _Nonnull rule, NSUInteger idx, BOOL * _Nonnull outerStop) {
        NSUInteger slide = rule.slide;
        [addresses enumerateObjectsUsingBlock:^(NSNumber *_Nonnull addressNum, NSUInteger idx, BOOL * _Nonnull innerStop) {
            NSUInteger methodAddr = [addressNum unsignedIntegerValue];
            NSUInteger targetAddr = methodAddr - slide; // minus ASLR slide value
//            [TSPKLogger logWithTag:TSPKLogCommonTag message:[NSString stringWithFormat:@"call stack filter is checking, call address: %@", @(targetAddr)]]; // need delete
            NSUInteger startAddr = rule.start;
            NSUInteger endAddr = rule.end;
            if (startAddr <= targetAddr && targetAddr < endAddr) { // targetAddr must locate between startAddr & endAddr
                isMatched = YES;
                *outerStop = YES;
                *innerStop = YES;
            }
        }];
    }];

    BOOL allowCall = (isMatched && isAllow) ||
                     (!isMatched && !isAllow);
//    [TSPKLogger logWithTag:TSPKLogCommonTag message:[NSString stringWithFormat:@"call stack filter is checking done, allowCall %@", @(allowCall)]];

    return allowCall;
}

@end

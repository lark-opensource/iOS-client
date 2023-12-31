//
//  MLeaksConfig.m
//  MLeaksFinder
//
//  Created by xushuangqing on 2019/8/12.
//

#import "TTMLeaksConfig.h"
#import "TTMLeaksFinder.h"

NSInteger TTMLStackDepthInBuildRetainTreeOperation = 15;
NSInteger TTMLBuildRetainTreeMaxNode = 2500;
NSInteger TTMLOneClassCheckMaxCount = 5;
NSInteger TTMLOneClassBuildRetainTreeMaxCount = 5;


NSInteger TTMLStackDepthInDetectRetainCycleOperation = 15;
NSInteger TTMLOneClassOnceDetectRetainCycleMaxCount = 5;
NSInteger TTMLOneClassOnceDetectRetainMaxTraversedNodeNumber = 2500;

@implementation TTMLeaksCase

- (NSDictionary *)transToParams {
    NSDictionary *params = @{
        @"aid" : self.aid ?: @"",
        @"view_stack" : [self.viewStack description] ?: @"",
        @"retain_cycles" : self.retainCycle ?: @"",
        @"cycle_key_class" : self.cycleKeyClass ?: @"",
        @"id" : self.ID ?: @"",
        @"build_info" : self.buildInfo ?: @"",
        @"user_info" : self.hostAppUserInfo ?: @"",
        @"cycle_id" : self.cycleID ?: @"",
        @"version_code" : self.appVersion ?: @"",
        @"mleaks_version_code" : self.mleaksVersion ?: @"",
        @"leaks_size":self.leakCycle.leakSize ?: @"",
    };
    return params;
}

- (NSDictionary *)transToNotificationUserInfo {
    NSDictionary *userInfo = @{
        @"id" : self.ID,
        @"viewStack" : [self.viewStack description] ?: @"",
        @"retainCycles" : self.retainCycle ?: @"",
        @"buildInfo" : self.buildInfo ?: @"",
        @"cycleID" : self.cycleID,
        @"cycleKeyClass" : self.cycleKeyClass ?: @"",
        @"leaks_size":self.leakCycle.leakSize ?: @""
    };
    return userInfo;
}

@end

@implementation TTMLeaksConfig
@synthesize enableAssociatedObjectHook = _enableAssociatedObjectHook;
@synthesize enableNoVcAndViewHook = _enableNoVcAndViewHook;
@synthesize classWhitelist = _classWhitelist;
@synthesize filters = _filters;

- (void)setEnableAssociatedObjectHook:(BOOL)enableAssociatedObjectHook {
    _enableAssociatedObjectHook = enableAssociatedObjectHook;
    [TTMLeaksFinder updateMemoryLeakConfig];
}

- (BOOL)enableAssociatedObjectHook {
    return _enableAssociatedObjectHook;
}

- (void)setEnableNoVcAndViewHook:(BOOL)enableNoVcAndViewHook {
    _enableNoVcAndViewHook = enableNoVcAndViewHook;
    [TTMLeaksFinder updateMemoryLeakConfig];
}

- (BOOL)enableNoVcAndViewHook {
    return _enableNoVcAndViewHook;
}

- (void)setClassWhitelist:(NSArray<NSString *> *)classWhitelist {
    _classWhitelist = [classWhitelist copy];
    [TTMLeaksFinder updateMemoryLeakConfig];
}

- (NSArray <NSString *> *)classWhitelist {
    return _classWhitelist;
}

- (void)setFilters:(NSDictionary<NSString *,NSArray<NSString *> *> *)filters {
    _filters = [filters copy];
    [TTMLeaksFinder updateMemoryLeakConfig];
}

- (NSDictionary<NSString *,NSArray<NSString *> *> *)filters {
    return _filters;
}

- (instancetype)initWithAid:(NSString *)aid {
    return [self initWithAid:aid
  enableAssociatedObjectHook:NO
                     filters:nil
              classWhitelist:nil
               viewStackType:MLeaksViewStackTypeViewController
                  appVersion:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]
                   buildInfo:nil
               userInfoBlock:nil];
}

- (instancetype)initWithAid:(NSString *)aid
 enableAssociatedObjectHook:(BOOL)enableAssociatedObjectHook
                    filters:(nullable NSDictionary<NSString *, NSArray<NSString *> *> *)filters
              viewStackType:(MLeaksViewStackType)viewStackType
                 appVersion:(NSString *)appVersion
                  buildInfo:(nullable NSString *)buildInfo
              userInfoBlock:(nullable MLeaksGetUserInfoBlock)userInfoBlock {
    return [self initWithAid:aid
  enableAssociatedObjectHook:enableAssociatedObjectHook
                     filters:filters
              classWhitelist:nil
               viewStackType:viewStackType
                  appVersion:appVersion
                   buildInfo:buildInfo
               userInfoBlock:userInfoBlock];
}

- (instancetype)initWithAid:(NSString *)aid
enableAssociatedObjectHook:(BOOL)enableAssociatedObjectHook
                   filters:(nullable NSDictionary<NSString *, NSArray<NSString *> *> *)filters
            classWhitelist:(nullable NSArray<NSString *> *)classWhitelist
             viewStackType:(MLeaksViewStackType)viewStackType
                appVersion:(NSString *)appVersion
                 buildInfo:(nullable NSString *)buildInfo
              userInfoBlock:(nullable MLeaksGetUserInfoBlock)userInfoBlock {
    return [self initWithAid:aid
  enableAssociatedObjectHook:enableAssociatedObjectHook
enableNoVcAndViewHook: NO
                     filters:filters
              classWhitelist:classWhitelist
               viewStackType:viewStackType
                  appVersion:appVersion
                   buildInfo:buildInfo
               userInfoBlock:userInfoBlock
               delegateClass:nil];
}

- (instancetype)initWithAid:(NSString *)aid
 enableAssociatedObjectHook:(BOOL)enableAssociatedObjectHook
      enableNoVcAndViewHook:(BOOL)enableNoVcAndViewHook
                    filters:(nullable NSDictionary<NSString *, NSArray<NSString *> *> *)filters
             classWhitelist:(nullable NSArray<NSString *> *)classWhitelist
              viewStackType:(MLeaksViewStackType)viewStackType
                 appVersion:(NSString *)appVersion
                  buildInfo:(nullable NSString *)buildInfo
              userInfoBlock:(nullable MLeaksGetUserInfoBlock)userInfoBlock
              delegateClass:(nullable Class<TTMLeaksFinderDelegate>)delegateClass
{
    return [self initWithAid:aid
  enableAssociatedObjectHook:enableAssociatedObjectHook
       enableNoVcAndViewHook:enableNoVcAndViewHook
                     filters:filters
              classWhitelist:classWhitelist
               viewStackType:viewStackType
                  appVersion:appVersion
                   buildInfo:buildInfo
               userInfoBlock:userInfoBlock
                  doubleSend:NO
              enableAlogOpen:NO
     enableDetectSystemClass:0
               delegateClass:delegateClass];
}

- (instancetype)initWithAid:(NSString *)aid
 enableAssociatedObjectHook:(BOOL)enableAssociatedObjectHook
      enableNoVcAndViewHook:(BOOL)enableNoVcAndViewHook
                    filters:(nullable NSDictionary<NSString *, NSArray<NSString *> *> *)filters
             classWhitelist:(nullable NSArray<NSString *> *)classWhitelist
              viewStackType:(MLeaksViewStackType)viewStackType
                 appVersion:(NSString *)appVersion
                  buildInfo:(nullable NSString *)buildInfo
              userInfoBlock:(nullable MLeaksGetUserInfoBlock)userInfoBlock
                 doubleSend:(BOOL)doubleSend
             enableAlogOpen:(BOOL)enableAlogOpen
    enableDetectSystemClass:(NSInteger)enableDetectSystemClass
              delegateClass:(nullable Class<TTMLeaksFinderDelegate>)delegateClass
{
    if (self = [super init]) {
        _aid = [aid copy];
        _enableNoVcAndViewHook = enableNoVcAndViewHook;
        _enableAssociatedObjectHook = enableAssociatedObjectHook;
        
        __block BOOL valid = YES;
        [filters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (![key isKindOfClass:[NSString class]] || ![obj isKindOfClass:[NSArray class]]) {
                valid = NO;
                *stop = YES;
            }
            NSArray *array = (NSArray *)obj;
            for (id s in array) {
                if (![s isKindOfClass:[NSString class]]) {
                    valid = NO;
                    *stop = YES;
                    break;
                }
            }
        }];//检测下发的filters是不是合法
        if (valid) {
            _filters = [filters copy];
        }
        else {
            NSLog(@"error filter params");
        }
        _classWhitelist = classWhitelist;
        _viewStackType = viewStackType;
        _appVersion = [appVersion copy];
        _buildInfo = [buildInfo copy];
        _userInfoBlock = [userInfoBlock copy];
        _doubleSend = doubleSend;
        _delegateClass = delegateClass;
        _enableAlogOpen = enableAlogOpen;
        _enableDetectSystemClass = enableDetectSystemClass;
    }
    return self;
}



@end

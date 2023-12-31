//
//  TMASessionManager.m
//  Timor
//
//  Created by CsoWhy on 2018/8/21.
//

#import "TMASessionManager.h"
#import <ECOInfra/BDPLog.h>
#import <ECOInfra/ECOInfra-Swift.h>

#define BDP_LOGIN_ANONYMOUS_ID @"TMA_Local_AnonymousID"
#define BDP_LOGIN_SESSION @"TMA_Local_Session"

// TMASessionManager delegate的包装类
@interface TMASessionManagerDelegateWrapper : NSObject
@property (nonatomic, weak) id<TMASessionManagerDelegate> delegate; // 代理
@property (nonatomic, weak) id<BDPSandboxProtocol> sandbox; // 沙盒
@end

@implementation TMASessionManagerDelegateWrapper
- (instancetype)initWithDelegate:(id)delegate sandbox:(id)sandbox
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        _sandbox = sandbox;
    }
    return self;
}
@end

@interface TMASessionManager()
// delegate map
@property (nonatomic, strong) NSMapTable<id<TMASessionManagerDelegate>, TMASessionManagerDelegateWrapper *> *delegateMapTable;
@end
@implementation TMASessionManager

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
+ (instancetype)sharedManager
{
    static TMASessionManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TMASessionManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _delegateMapTable = [[NSMapTable alloc] initWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory capacity:10];
    }
    return self;
}

#pragma mark - Variables Getters & Setters
/*-----------------------------------------------*/
//     Variables Getters & Setters - 变量相关
/*-----------------------------------------------*/
- (void)updateSession:(NSString *)session sandbox:(id<BDPSandboxProtocol> )sandbox
{
    if (sandbox && session) {
        [self broadcastDelegatesWithSession:session sandbox:sandbox];
        [sandbox.privateStorage setObject:session forKey:BDP_LOGIN_SESSION];
    }
}

- (NSString *)getSession:(id<BDPSandboxProtocol> )sandbox
{
    if (sandbox) {
        NSString *session = [sandbox.privateStorage objectForKey:BDP_LOGIN_SESSION];
        return session;
    }
    return nil;
}

- (void)updateAnonymousID:(NSString *)anonymousID
{
    [[LSUserDefault standard] setString:anonymousID ?: @"" forKey:BDP_LOGIN_ANONYMOUS_ID];
    [[LSUserDefault standard] synchronize];
}

- (NSString *)getAnonymousID
{
    NSString *anonymousID = [[LSUserDefault standard] getStringForKey:BDP_LOGIN_ANONYMOUS_ID];
    return anonymousID;
}

// 增加TMASessionManager的多播delegate
- (void)addDelegate:(id<TMASessionManagerDelegate>)delegate sandbox:(id<BDPSandboxProtocol>)sandbox {
    TMASessionManagerDelegateWrapper *wrapper = [[TMASessionManagerDelegateWrapper alloc] initWithDelegate:delegate sandbox:sandbox];
    [_delegateMapTable setObject:wrapper forKey:delegate];
}

// 移除delegate
- (void)removeDelegate:(id<TMASessionManagerDelegate>)delegate
{
    [_delegateMapTable removeObjectForKey:delegate];
}

// 广播session更新
- (void)broadcastDelegatesWithSession:(NSString *)session sandbox:(id<BDPSandboxProtocol>)sandbox
{
    if ([[self getSession:sandbox] isEqualToString:session]) {
        BDPLogInfo(@"session update session, session not change");
        return;
    }
    NSArray *allKeys = [_delegateMapTable keyEnumerator].allObjects;
    for (NSInteger i = 0; i < allKeys.count; i++) {
        id<TMASessionManagerDelegate> delegate = allKeys[i];
        TMASessionManagerDelegateWrapper* wrapper = [_delegateMapTable objectForKey:delegate];
        if (wrapper.sandbox == sandbox) {
            if (delegate && [delegate respondsToSelector:@selector(sessionUpdated:)]) {
                [delegate sessionUpdated:session];
            } else {
                BDPLogWarn(@"session update broadcast fail, delegate is nil");
            }
        }
    }
}

@end

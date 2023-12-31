//
//  BDPPrivacyAccessNotifier.m
//  AFgzipRequestSerializer
//
//  Created by zhangquan on 2019/9/25.
//

#import "BDPPrivacyAccessNotifier.h"
#import <OPFoundation/BDPUtils.h>

@interface BDPPrivacyAccessNotifier ()

@property (atomic, assign) BDPPrivacyAccessStatus currentStatus;
@property (nonatomic, strong) NSHashTable <id<BDPPrivacyAccessNotifyDelegate>> *delegates;  //  weakObjectsHashTable

@end

@implementation BDPPrivacyAccessNotifier

#pragma mark - Initialize
/*-----------------------------------------------*/
//             Initialize - 初始化相关
/*-----------------------------------------------*/
+ (instancetype)sharedNotifier
{
    static BDPPrivacyAccessNotifier *sharedInstance = nil;
    if (!sharedInstance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedInstance = [[[self class] alloc] init];
        });
    }
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.delegates = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

#pragma mark - Delegate
/*-----------------------------------------------*/
//               Delegate - 监听代理
/*-----------------------------------------------*/
- (void)addDelegate:(id<BDPPrivacyAccessNotifyDelegate>)delegate
{
    if (!delegate || ![delegate conformsToProtocol:@protocol(BDPPrivacyAccessNotifyDelegate)]) {
        return;
    }
    BDPLogDebug(@"BDPPrivacyAccessNotifier add delegate: %@ %p", [delegate class], delegate);
    @synchronized (self.delegates) {
        [self.delegates addObject:delegate];
    }
}

- (void)removeDelegate:(id<BDPPrivacyAccessNotifyDelegate>)delegate
{
    if (!delegate || ![delegate conformsToProtocol:@protocol(BDPPrivacyAccessNotifyDelegate)]) {
        return;
    }
    BDPLogDebug(@"BDPPrivacyAccessNotifier remove delegate: %@ %p", [delegate class], delegate);
    @synchronized (self.delegates) {
        [self.delegates removeObject:delegate];
    }
}

#pragma mark - AccessManager Function
/*-----------------------------------------------*/
//      AccessManager Function - 权限管理方法
/*-----------------------------------------------*/
- (void)setPrivacyAccessStatus:(BDPPrivacyAccessStatus)status isUsing:(BOOL)isUsing
{
    BDPPrivacyAccessStatus lastStatus = self.currentStatus;
    if (isUsing) {
        self.currentStatus |= status;
    } else {
        self.currentStatus &= ~status;
    }
    
    // 权限发生变化时，主动通知外部代理对象
    if (lastStatus != self.currentStatus) {
        [self notifyPrivacyAccessStatusChanged];
    }
}

#pragma mark - Utils
/*-----------------------------------------------*/
//                  Utils - 工具
/*-----------------------------------------------*/
- (void)notifyPrivacyAccessStatusChanged
{
    if (!self.delegates.count) {
        return;
    }
    
    // 先把delegate提取出来，避免通知时每个delegate处理时间过长把同步锁卡住了
    NSMutableSet *retainedDelegates = [NSMutableSet set];
    @synchronized (self.delegates) {
        for (id delegate in self.delegates) {
            [retainedDelegates addObject:delegate];
        }
    }
    
    BDPLogDebug(@"BDPPrivacyAccessNotifier change status:%d delegateList:%@", (int)self.currentStatus, retainedDelegates);
    // 主线通知权限变化
    BDPExecuteOnMainQueue(^{
        for (id<BDPPrivacyAccessNotifyDelegate> delegate in retainedDelegates) {
            if ([delegate conformsToProtocol:@protocol(BDPPrivacyAccessNotifyDelegate)]) {
                [delegate privacyAccessNotifier:self didChangePrivacyAccessStatus:self.currentStatus];
            }
        }
    });
}

@end


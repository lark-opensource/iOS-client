//
//  BDPJSSDKForceUpdateManager.m
//  TTMicroApp
//
//  Created by Nicholas Tau on 2021/2/10.
//

#import "BDPJSSDKForceUpdateManager.h"
#import <TTMicroApp/TTMicroApp-Swift.h>

NSString * const BDPJSSDKSyncForceUpdateBeginNoti   =   @"kBDPJSSDKSyncForceUpdateBeginNoti";
NSString * const BDPJSSDKSyncForceUpdateFinishNoti  =   @"kBDPJSSDKSyncForceUpdateFinishNoti";

@interface BDPJSSDKForceUpdateManager ()
@property(nonatomic, strong) dispatch_semaphore_t semaphore;
@property(nonatomic, strong) dispatch_queue_t forceUpdateQueue;
@property(nonatomic, assign) BOOL updateResult;
@end

@implementation BDPJSSDKForceUpdateManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.forceUpdateQueue = dispatch_queue_create("com.lark.jssdk.forceupdate", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

+ (instancetype)sharedInstance {
    static BDPJSSDKForceUpdateManager* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BDPJSSDKForceUpdateManager alloc] init];
    });
    
    return instance;
}
//默认返回 false，检查超时
-(BOOL)forceJSSDKUpdateWaitUntilCompeteOrTimeout
{
    BOOL enable = [BDPFeatureGatingBridge forceJSSDKUpdateCheckEnable];
    //如果功能不开启，默认返回false，不影响原有流程逻辑
    if (!enable) {
        return false;
    }
    @synchronized (self) {
        self.updateResult = NO;
        self.semaphore = dispatch_semaphore_create(0);
    }
    dispatch_async(self.forceUpdateQueue, ^{
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateComplete:)
                                                     name:BDPJSSDKSyncForceUpdateFinishNoti
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:BDPJSSDKSyncForceUpdateBeginNoti
                                                            object:self];
    });
    //begin waitig here, until timeout or receive complete notification
    //wait for 1 seconds
    dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)));
    return self.updateResult;
}

-(void)updateComplete:(NSNotification *)notification
{
    @synchronized (self) {
        self.updateResult = [notification.userInfo[@"isSuccess"] boolValue];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:BDPJSSDKSyncForceUpdateFinishNoti
                                                  object:nil];
    dispatch_semaphore_signal(self.semaphore);
}

@end

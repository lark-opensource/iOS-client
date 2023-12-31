//
//  BDPInterruptionManager.m
//  Timor
//
//  Created by CsoWhy on 2018/10/18.
//

#import <UIKit/UIKit.h>
#import "BDPInterruptionManager.h"
#import <OPFoundation/BDPBootstrapHeader.h>
#import <OPFoundation/BDPUniqueID.h>

@interface BDPInterruptionManager ()

@property (nonatomic, assign) BOOL isInterrupted;

@end

@implementation BDPInterruptionManager

@BDPBootstrapLaunch(BDPInterruptionManager, {
    [BDPInterruptionManager sharedManager];
});

#pragma mark - Initilize
+ (instancetype)sharedManager
{
    static BDPInterruptionManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[BDPInterruptionManager alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupObserver];
        // 初始值设置成NO，避免APP第一次回后台不能触发小程序的onHide的问题
         _isInterrupted = NO;
    }
    return self;
}

#pragma mark - Notification Observer
/*-----------------------------------------------*/
//         Notification Observer - 通知
/*-----------------------------------------------*/
- (void)setupObserver
{
    //UIApplicationDidEnterBackgroundNotification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    //UIApplicationWillResignActiveNotification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    //UIApplicationWillEnterForegroundNotification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    //UIApplicationDidBecomeActiveNotification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)applicationDidEnterBackground {
    [self applicationBeginInterrupted];
    
    // DidEnterBackground的时候标记一下
    self.didEnterBackground = YES;
}

- (void)applicationWillResignActive {
    [self applicationBeginInterrupted];
}

- (void)applicationWillEnterForeground {
    [self applicationEndInterrupted];
    self.didEnterBackground = NO;
}

- (void)applicationDidBecomeActive {
    [self applicationEndInterrupted];
    self.didEnterBackground = NO;
}

- (void)applicationBeginInterrupted
{
    if (!self.isInterrupted) {
        [self postInterruptionNotification:YES];
        self.isInterrupted = YES;
    }
}

- (void)applicationEndInterrupted
{
    if (self.isInterrupted) {
        [self postInterruptionNotification:NO];
        self.isInterrupted = NO;
    }
}

- (void)postInterruptionNotification:(BOOL)isInterruption
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:1];
    [dict setValue:@(isInterruption) forKey:kBDPInterruptionStatusUserInfoKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kBDPInterruptionNotification
                                                        object:nil
                                                      userInfo:[dict copy]];
}

+ (void)postEnterForegroundNotification:(BDPType)type uniqueID:(BDPUniqueID *)uniqueID
{
    if (!uniqueID) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:kBDPEnterForegroundNotification
                                                        object:nil
                                                      userInfo:@{kBDPUniqueIDUserInfoKey : uniqueID}];
}

+(void)postDidEnterForegroundNotification:(BDPType)type uniqueID:(OPAppUniqueID *)uniqueID{
    if (!uniqueID) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:kBDPDidEnterForegroundNotification
                                                        object:nil
                                                      userInfo:@{@"mp_id" : uniqueID.appID?:@""}];
}

+ (void)postEnterBackgroundNotification:(BDPType)type uniqueID:(BDPUniqueID *)uniqueID
{
    if (!uniqueID) return;
    [[NSNotificationCenter defaultCenter] postNotificationName:kBDPEnterBackgroundNotification
                                                        object:nil
                                                      userInfo:@{kBDPUniqueIDUserInfoKey : uniqueID,
                                                                 @"mp_id": uniqueID.appID?:@""
                                                      }];
}

@end

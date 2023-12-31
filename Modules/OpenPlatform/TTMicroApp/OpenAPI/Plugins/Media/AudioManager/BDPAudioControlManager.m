//
//  BDPAudioControlManager.m
//  Timor
//
//  Created by CsoWhy on 2018/7/27.
//

#import "BDPAudioControlManager.h"
#import "BDPInterruptionManager.h"
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPNotification.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPUniqueID.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <TTMicroApp/TTMicroApp-Swift.h>

#define COMPLETION_BLOCK if(completion){completion();}

@interface BDPAudioControlManager()

@property (nonatomic, assign) NSInteger activeInstance;
@property (nonatomic, assign) NSInteger activeContainer;

@end

@implementation BDPAudioControlManager

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
+ (instancetype)sharedManager
{
    static BDPAudioControlManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[BDPAudioControlManager alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _activeInstance = 0;
        _activeContainer = 0;
        
        // 初始化中断管理器，确保kBDPInterruptionNotification消息有效
        [BDPInterruptionManager sharedManager];
    }
    return self;
}

#pragma mark - Audio Interruption Observer Switch
/*-----------------------------------------------*/
//  Audio Interruption Observer Switch - 监听开关
/*-----------------------------------------------*/

- (void)increaseActiveContainer
{
    self.activeContainer++;
    if (self.activeContainer > 0) {
        // 前台运行小程序时，主动监听
        [self setupObserver];
    }
}

- (void)decreaseActiveContainer
{
    self.activeContainer--;
    if (self.activeContainer <= 0) {
        self.activeContainer = 0;
        
        // 没有前台运行的小程序时，关闭音频中断的监听
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

#pragma mark - Notification Observer
/*-----------------------------------------------*/
//        Notification Observer - 通知监听
/*-----------------------------------------------*/
- (void)setupObserver
{
    //kBDPInterruptionNotification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:kBDPInterruptionNotification
                                               object:nil];
    
    //AVAudioSessionInterruptionNotification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAVAudioSessionInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:nil];
}

- (void)handleInterruption:(NSNotification *)notification
{
    BOOL isInterruption = [notification.userInfo bdp_boolValueForKey:kBDPInterruptionStatusUserInfoKey];
    BDPLogInfo(@"handleInterruption: %@", @(isInterruption));
    if (isInterruption) {
        [self beginInterruption:nil];
    } else {
        [self endInterruption:nil];
    }
}

- (void)handleAVAudioSessionInterruption:(NSNotification *)notification
{
    NSUInteger interruptionType = [notification.userInfo bdp_unsignedIntegerValueForKey:AVAudioSessionInterruptionTypeKey];
    NSUInteger interruptionOption = [notification.userInfo bdp_unsignedIntegerValueForKey:AVAudioSessionInterruptionOptionKey];
    BDPLogInfo(@"[BDPlatform] Audio: %@", interruptionType == AVAudioSessionInterruptionTypeBegan ? @"Begin Interruption" : @"End Interruption");
    
    //Check Interruption Status
    if (interruptionType == AVAudioSessionInterruptionTypeBegan) {
        // 音频中断
        [self postAudioInterruption:BDPAudioInterruptionOperationTypeSystemBegan uniqueID:nil];

    } else if (interruptionType == AVAudioSessionInterruptionTypeEnded) {
        
        // 在系统通知恢复时才强制恢复
        if (interruptionOption == AVAudioSessionInterruptionOptionShouldResume) {
            [self postAudioInterruption:BDPAudioInterruptionOperationTypeSystemEnd uniqueID:nil];
        }
    }
}

#pragma mark - Utils
/*-----------------------------------------------*/
//                  Utils - 工具
/*-----------------------------------------------*/
- (void)beginInterruption:(BDPUniqueID *)uniqueID
{
    // 音频中断 - 执行顺序需要保证
    // 全局音频暂停 -> OpenAL中断 -> 全局音频设置为非活跃状态并恢复原始音频资源
    BDPLogInfo(@"beginInterruption: %@", uniqueID);
    [self postAudioInterruption:BDPAudioInterruptionOperationTypeBackground uniqueID:uniqueID];
}

- (void)endInterruption:(BDPUniqueID *)uniqueID
{
    // 音频恢复 - 执行顺序需要保证
    // OpenAL恢复 -> 全局音频恢复(全局音频活跃状态在播放时按需设置)
    BDPLogInfo(@"endInterruption: %@", uniqueID);
    [self postAudioInterruption:BDPAudioInterruptionOperationTypeForeground uniqueID:uniqueID];
}

- (void)postAudioInterruption:(BDPAudioInterruptionOperationType)operation uniqueID:(BDPUniqueID *)uniqueID
{
    //Post Notification
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:1];
    [dict setValue:uniqueID forKey:kBDPUniqueIDUserInfoKey];
    [dict setValue:@(operation) forKey:kBDPAudioInterruptionOperationUserInfoKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kBDPAudioInterruptionNotification
                                                        object:nil
                                                      userInfo:[dict copy]];
}

@end

//
//  TMAPlayerScreenIdleManager.m
//  AFgzipRequestSerializer
//
//  Created by bupozhuang on 2019/4/1.
//

#import <UIKit/UIKit.h>
#import "TMAPlayerScreenIdleManager.h"

@interface TMAPlayerScreenIdleManager()
@property(nonatomic, strong) NSMutableArray *playingPlayers;
@property(nonatomic, assign) BOOL initialState;// 开始播放之前是否常亮状态
@end

@implementation TMAPlayerScreenIdleManager
+ (instancetype)shared {
    static TMAPlayerScreenIdleManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TMAPlayerScreenIdleManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.playingPlayers = [NSMutableArray new];
    }
    return self;
}

- (void)startPlay:(NSInteger) playerID {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.playingPlayers.count == 0) {// 保留初始设置
            self.initialState = [UIApplication sharedApplication].isIdleTimerDisabled;
        }
        if (![self.playingPlayers containsObject:@(playerID)]) {
            [self.playingPlayers addObject:@(playerID)];
        }
        [self idleDisableIfNeed];
    });
}

- (void)stopPlay:(NSInteger) playerID {
     dispatch_async(dispatch_get_main_queue(), ^{
         [self.playingPlayers removeObject:@(playerID)];
         [self idleDisableIfNeed];
     });
}

- (void)idleDisableIfNeed {
    if (self.playingPlayers.count > 0) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    } else {
        [UIApplication sharedApplication].idleTimerDisabled = self.initialState; //还原初始状态
    }
}
@end

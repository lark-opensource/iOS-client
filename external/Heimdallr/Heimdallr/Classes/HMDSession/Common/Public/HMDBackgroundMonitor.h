//
//  HMDBackgroundMonitor.h
//  Pods
//
//  Created by 白昆仑 on 2020/4/10.
//

#import <Foundation/Foundation.h>

@protocol HMDApplicationStatusChangeDelegate <NSObject>

- (void)applicationChangeToForeground;
- (void)applicationChangeToBackground;

@end

FOUNDATION_EXPORT BOOL HMDApplicationSession_backgroundState(void);

@interface HMDBackgroundMonitor : NSObject

@property(nonatomic, assign, readonly) BOOL isBackground;

+ (instancetype _Nonnull)sharedInstance;

- (void)updateBackgroundState;

- (void)addStatusChangeDelegate:(id<HMDApplicationStatusChangeDelegate>_Nonnull)delegate;

- (void)removeStatusChangeDelegate:(id<HMDApplicationStatusChangeDelegate>_Nonnull)delegate;
@end


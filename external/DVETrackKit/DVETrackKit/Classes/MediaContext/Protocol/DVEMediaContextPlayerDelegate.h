//
//  DVEMediaContextPlayerDelegate.h
//  DVETrackKit
//
//  Created by bytedance on 2021/9/6.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/HTSDefine.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVEMediaContextPlayerDelegate <NSObject>

@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *playerTimeDidChangeSignal;

- (void)mediaDelegateSeekToTime:(CMTime)time
                       isSmooth:(BOOL)isSmooth;

- (void)mediaDelegatePause;

- (NSTimeInterval)currentPlayerTime;

- (BOOL)playing;

@end

NS_ASSUME_NONNULL_END

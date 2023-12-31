//
//  AWEReactMicrophoneButton.h
//  AWEStudio
//
//  Created by lixingdong on 2018/9/7.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreativeKit/ACCAnimatedButton.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEReactMicrophoneButton : ACCAnimatedButton

@property (nonatomic, assign, readonly) BOOL isMuted;
@property (nonatomic, assign, readonly) BOOL isLockedDisable;///由于特殊道具等原因 处于置灰但仍响应点击 (PM要求置灰不可点 还要点击弹toast 无语)
@property (nonatomic, assign, readonly) BOOL mementoMuted;

- (void)mutedMicrophone:(BOOL)isMuted;

- (void)lockButtonDisable:(BOOL)disable shouldShow:(BOOL)show;

- (void)setMemento:(BOOL)muted;

@end

NS_ASSUME_NONNULL_END

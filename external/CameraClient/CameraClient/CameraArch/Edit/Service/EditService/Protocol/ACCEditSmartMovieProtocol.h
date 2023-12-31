//
//  ACCEditSmartMovieProtocol.h
//  CreationKitRTProtocol-Pods-Aweme
//
//  Created by LeonZou on 2021/8/3.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CreationKitRTProtocol/ACCEditWrapper.h>

@class RACSignal, NLEInterface_OC, NLETrack_OC;
@protocol ACCMusicModelProtocol;
@protocol ACCEditVideoDataProtocol;

@protocol ACCEditSmartMovieMusicTupleProtocol <NSObject>

@property (nonatomic, strong, nullable) id<ACCMusicModelProtocol> to;
@property (nonatomic, strong, nullable) id<ACCMusicModelProtocol> from;

@end

@protocol ACCEditSmartMovieProtocol <ACCEditWrapper>

@property (nonatomic, weak, readonly, nullable) NLEInterface_OC *nle;
@property (nonatomic, assign, readonly) BOOL isSmartMovieBubbleAllowed;
@property (nonatomic, strong, readonly, nullable) RACSignal *recoverySignal;
@property (nonatomic, strong, readonly, nullable) RACSignal *willSwitchMusicSignal;
@property (nonatomic, strong, readonly, nullable) RACSignal *didSwitchMusicSignal;

- (void)triggerSignalForRecovery;
- (void)triggerSignalForDidSwitchMusic;
- (void)triggerSignalForWillSwitchMusic:(id<ACCEditSmartMovieMusicTupleProtocol> _Nonnull)musicTuple;
- (void)updateSmartMovieBubbleAllowed:(BOOL)allowed;
// 智照场景判断
- (BOOL)isSmartMovieMode;

// 展示编辑页云端处理提示Toast
- (void)showUploadRemindToastIfNeeded;

// 使用本地音乐
- (void)useLocalMusic:(id<ACCMusicModelProtocol> _Nonnull)localMusicModel withTotalVideoDuration:(CGFloat)totalVideoDuration;

// 替换音轨，用于场景切换时替换成用户所选择的音乐
- (void)useMusic:(id<ACCMusicModelProtocol> _Nonnull)musicModel ForVideoData:(id<ACCEditVideoDataProtocol> _Nonnull)videoData;

// 取消音乐
- (void)dismissMusicForVideoData:(id<ACCEditVideoDataProtocol> _Nonnull)videoData;

@end

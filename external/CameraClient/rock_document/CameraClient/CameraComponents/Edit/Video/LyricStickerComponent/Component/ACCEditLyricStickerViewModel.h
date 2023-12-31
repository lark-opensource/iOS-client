//
//  ACCEditLyricStickerViewModel.h
//  Pods
//
//  Created by liyingpeng on 2020/8/7.
//

#import "ACCEditViewModel.h"
#import "ACCLyricsStickerServiceProtocol.h"
#import "AWEVideoEditDefine.h"
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditLyricStickerViewModel : NSObject <ACCLyricsStickerServiceProtocol>

@property (nonatomic, weak) AWEVideoPublishViewModel *repository;
@property (nonatomic, assign) BOOL musicLyricVCPresented; // 歌词贴纸->选择音乐 是否已显示
// 是否已经添加音乐贴纸
@property (nonatomic, assign, readonly) BOOL hasAlreadyAddLyricSticker;

- (void)sendAddClipViewSignal;

- (void)sendShowClipViewSignal;

- (void)sendDidFinishCutMusicSignal:(HTSAudioRange)range
                        repeatCount:(NSInteger)repeatCount;

- (void)sendDidSelectMusicSignal:(id<ACCMusicModelProtocol>)music;

- (void)sendUpdateMusicRelateUISignal;

- (void)sendUpdateLyricsStickerButtonSignal:(ACCMusicPanelLyricsStickerButtonChangeType)changeType;

- (void)sendWillShowLyricMusicSelectPanelSignal;

- (void)sendDidCancelLyricMusicSelectSignal;

@end

NS_ASSUME_NONNULL_END

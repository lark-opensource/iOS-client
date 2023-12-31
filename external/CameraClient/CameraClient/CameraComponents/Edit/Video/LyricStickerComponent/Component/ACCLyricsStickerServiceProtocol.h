//
//  ACCLyricsStickerServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2020/12/28.
//

#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicModelProtocol;
@protocol ACCLyricsStickerServiceProtocol <NSObject>

// 音乐贴纸选择音乐界面是否弹出
@property (nonatomic, assign, readonly) BOOL musicLyricVCPresented;

// 是否已经添加音乐贴纸
@property (nonatomic, assign, readonly) BOOL hasAlreadyAddLyricSticker;

@property (nonatomic, strong, readonly) RACSignal *willShowLyricMusicSelectPanelSignal;
@property (nonatomic, strong, readonly) RACSignal *didCancelLyricMusicSelectSignal;

@property (nonatomic, strong, readonly) RACSignal *addClipViewSignal;

@property (nonatomic, strong, readonly) RACSignal *showClipViewSignal;

@property (nonatomic, strong, readonly) RACSignal<RACTwoTuple<NSValue *, NSNumber *> *> *didFinishCutMusicSignal;

@property (nonatomic, strong, readonly) RACSignal<id<ACCMusicModelProtocol>> *didSelectMusicSignal;

@property (nonatomic, strong, readonly) RACSignal *updateMusicRelateUISignal;

@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *updateLyricsStickerButtonSignal;

@end

NS_ASSUME_NONNULL_END

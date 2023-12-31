//
//  ACCEditLyricsStickerViewController.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2020/12/6.
//

#import <UIKit/UIKit.h>
#import "AWEVideoEditDefine.h"
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCStickerContainerView,
AWEVideoPublishViewModel,
ACCEditLyricStickerViewModel,
IESEffectModel,
ACCMusicModel,
AWELyricStickerPanelView,
AWEVideoPublishViewModel;

@protocol ACCEditServiceProtocol,
ACCEditorDraftService,
ACCMusicModelProtocol;

@class ACCEditLyricsStickerViewController;
@protocol ACCEditLyricsStickerDatasource <NSObject>

// 添加歌词贴纸
- (void)editLyricsViewController:(ACCEditLyricsStickerViewController *)viewControler
                addLyricsSticker:(IESEffectModel *)sticker
                            path:(NSString *)path
                         tabName:(nullable NSString *)tabName
                      completion:(nullable void (^)(NSInteger))completion;

// 移除歌词贴纸
- (void)editLyricsViewControllerRemoveMusicLyricSticker:(ACCEditLyricsStickerViewController *)viewControler;

@end

@protocol ACCEditLyricsStickerDelegate<NSObject>

// 相关调用都已经加上responseTo的保护
@optional
- (void)editLyricsViewControllerAddAudioClipView:(ACCEditLyricsStickerViewController *)viewControler;
- (void)editLyricsViewControllerShowAudioClipView:(ACCEditLyricsStickerViewController *)viewControler;
- (void)editLyricsViewControllerClipMusic:(HTSAudioRange)audioRange
                              repeatCount:(NSInteger)repeatCount;

- (void)editLyricsViewController:(ACCEditLyricsStickerViewController *)viewControler
                  didSelectMusic:(nullable id<ACCMusicModelProtocol>)music
                           error:(nullable NSError *)error;
- (void)editLyricsViewController:(ACCEditLyricsStickerViewController *)viewControler didSelectColor:(UIColor *)color;
- (void)editLyricsViewControllerDidDismiss:(ACCEditLyricsStickerViewController *)viewControler;

@end

extern CGFloat const kACCEditLyricsStickerPanelHeight;

@interface ACCEditLyricsStickerInputData : NSObject

@property (nonatomic, strong) AWEVideoPublishViewModel *repository;
@property (nonatomic, assign) NSInteger stickerId;
@property (nonatomic, strong) ACCStickerContainerView *stickerContainer;
// 拍摄器布局
@property (nonatomic, assign) CGRect originalPlayerViewContainerViewFrame;

@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, strong) id<ACCEditorDraftService> draftService;

@property (nonatomic, weak) UIViewController *containerViewController;

@property (nonatomic, assign) BOOL disableChangeMusic;

@end

// 编辑歌词贴纸样式界面，新容器实现
@interface ACCEditLyricsStickerViewController : UIViewController

@property (nonatomic, strong, readonly) ACCEditLyricsStickerInputData *inputData;
@property (nonatomic, weak) id<ACCEditLyricsStickerDatasource> datasource;
@property (nonatomic, weak) id<ACCEditLyricsStickerDelegate> delegate;

- (instancetype)initWithInputData:(ACCEditLyricsStickerInputData *)inputData
                       datasource:(id<ACCEditLyricsStickerDatasource>)datasource;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) AWELyricStickerPanelView *lyricPanelView;

- (void)clipMusic:(HTSAudioRange)audioRange repeatCount:(NSInteger)repeatCount;
- (void)updatePlayerModelAudioRange:(HTSAudioRange)audioRange;
- (void)audioRangeChanging:(HTSAudioRange)range changeType:(AWEAudioClipRangeChangeType)changeType;
- (void)audioRangeDidChange:(HTSAudioRange)range changeType:(AWEAudioClipRangeChangeType)changeType;
- (void)presentMusicStickerSearchVCFromLyricEdit:(BOOL)fromLyricEdit completion:(void (^)(id<ACCMusicModelProtocol>, NSError *, BOOL dismiss))completion;

@end

NS_ASSUME_NONNULL_END

//
//  AWEStudioCaptionsManager.h
//  Pods
//
//  Created by lixingdong on 2019/8/28.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCRepoCaptionModel.h>
#import <CreationKitRTProtocol/ACCEditStickerProtocol.h>
#import "ACCStickerServiceProtocol.h"
#import "ACCEditPreviewProtocolD.h"
#import <CreationKitArch/AWEStudioCaptionModel.h>

@protocol ACCEditServiceProtocol;
@class ACCRepoVideoInfoModel;

typedef NS_ENUM(NSInteger, AWECaptionEditMode) {
    AWECaptionEditModeNone = 0,     // 仅展示
    AWECaptionEditModeStyleAndLocation = 1,
    AWECaptionEditModeWordsAndLocation = 2
};

@interface AWEStudioCaptionsManager : NSObject
<ACCEditPreviewMessageProtocolD>

@property (nonatomic, strong, readonly) AWEStudioCaptionInfoModel *captionInfo;
@property (nonatomic, strong) NSMutableArray<AWEStudioCaptionModel *> *captions;
@property (nonatomic, strong, readonly) NSMutableDictionary *captionStickerIdMaps;
@property (nonatomic, assign) BOOL forceUpdate;

// 字体公共属性
@property (nonatomic, strong) NSIndexPath *colorIndex;
@property (nonatomic, strong) AWEStoryColor *fontColor;
@property (nonatomic, strong) NSIndexPath *fontIndex;
@property (nonatomic, strong) AWEStoryFontModel *fontModel;
@property (nonatomic, assign) AWEStoryTextStyle textStyle;
@property (nonatomic, strong) AWEInteractionStickerLocationModel *location;
// 当前正在编辑的贴纸 id
@property (nonatomic, assign, readonly) NSInteger stickerEditId;

// 新容器编辑字幕回调
@property (nonatomic, copy, nullable) void(^editStickerAction)(void);
// 新容器删除字幕回调
@property (nonatomic, copy, nullable) void(^deleteStickerAction)(void);

- (instancetype)initWithRepoCaptionModel:(ACCRepoCaptionModel *)repoCaption
                               repoVideo:(ACCRepoVideoInfoModel *)repoVideo;

#pragma mark - 字幕容器逻辑

// 配置player对应的 imageBlock信息 以及 字幕手势view
- (void)configCaptionImageBlockForEditService:(id<ACCEditServiceProtocol>)editService
                                containerView:(ACCStickerContainerView *)containerView;

// 添加字幕
- (void)addCaptionsForEditService:(id<ACCEditServiceProtocol>)editService
                    containerView:(ACCStickerContainerView *)containerView;

// 删除字幕（从player删除，不显示字幕，未清空字幕数据）
- (void)removeCaptionForEditService:(id<ACCEditServiceProtocol>)editService
                      containerView:(ACCStickerContainerView *)containerView;

// 发布专用
- (void)addCaptionsForPublishTaskWithEditService:(id<ACCEditServiceProtocol>)editService;

#pragma mark - Render

// 更新字幕背景Path
- (void)updateCaptionLineRectForAll;

//备份样式
- (void)backupTextStyle;

//恢复样式
- (void)restoreTextStyle;

//备份所有字幕信息
- (void)backupCaptionData;

//恢复字幕信息
- (void)restoreCaptionData;

//删除字幕（数据）
- (void)deleteCaption;

/// Need upload audio flag
- (void)setNeedUploadAudio;

// 重置是否删除贴纸的标记
- (void)resetDeleteState;

@end

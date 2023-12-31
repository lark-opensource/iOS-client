//
//  ACCRecordViewControllerInputData.h
//  Pods
//
//  Created by songxiangwu on 2019/8/20.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "AWECaptureButtonAnimationView.h"
#import <CreationKitArch/AWERecordEnterFromDefine.h>
#import <CreationKitArch/ACCRecodInputDataProtocol.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <AVFoundation/AVFoundation.h>
#import <CreativeKit/ACCBusinessConfiguration.h>

@class IESEffectModel;

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecordViewControllerInputData : NSObject <ACCRecodInputDataProtocol, ACCBusinessInputData>
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, copy) NSString *groupID; // 道具详情页带音乐进入时，原视频itemID，打点用
@property (nonatomic, strong, nullable) IESEffectModel *localSticker; // 贴纸应用
@property (nonatomic, strong, nullable) IESEffectModel *duetDefaultSticker; // 合拍的原视频道具
@property (nonatomic, copy, nullable) NSArray<IESEffectModel *> *localBindEffects; // 关联道具
@property (nonatomic, assign) BOOL isSplitOrChallenge;//是否抢镜或或者合拍
@property (nonatomic, assign) BOOL showStickerPanelAtLaunch;//进入拍摄页是否立即展示道具面板
@property (nonatomic, copy, nullable) NSString *stickerCategoryKey;//进入拍摄页如果要立即展示道具面板，需要定位到哪个tab，默认为nil，定位到热门
@property (nonatomic, assign) BOOL motivationTaskShowPropPanel;
@property (nonatomic, copy) NSString *ugcPathRefer;
@property (nonatomic, strong) id<ACCMusicModelProtocol> sameStickerMusic;
@property (nonatomic, strong) NSString *closeWarning;
@property (nonatomic, copy) IESEffectModel *sameMVTemplateModel; // 同款影集mv的模板id
@property (nonatomic, copy) NSString *statusTemplateId; // 同款status作品模板id
@property (nonatomic, copy) IESEffectModel *statusTemplateModel; // 同款status作品模板
@property (nonatomic, strong, nullable) NSArray<IESEffectModel *> *prioritizedStickers; // 贴纸插入

@property (nonatomic, copy) NSString *lynxURL;
@property (nonatomic, copy) NSString *lynxDebugURL;
@property (nonatomic, copy) NSString *lynxData;

/**
 sticker ids for stickers which will insert into hot tab in sticker panel.
 */
@property (nonatomic, copy) NSArray<NSString *> *prioritizedStickerIds;

@property (nonatomic, copy) NSString *charityID; // 慈善机构ID
@property (nonatomic, assign) BOOL filterBusiness; // 是否过滤道具面板上的商业化道具，默认为NO。
@property (nonatomic, assign) NSInteger needsFilterStickerType;


// Amazon alexa voice command parameters
@property (nonatomic, assign) AVCaptureDevicePosition cameraPosition;

@property (nonatomic, assign) NSInteger firstCaptureAppState;

- (void)recordCurrentApplicateState;

@end

NS_ASSUME_NONNULL_END

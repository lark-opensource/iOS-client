//
//  ACCNLEPublishEditorBuilder.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/7/9.
//

#import "ACCNLEPublishEditorBuilder.h"
#import "ACCEditVideoDataDowngrading.h"
#import "ACCEditViewControllerInputData.h"
#import "ACCMediaContainerView.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import "ACCStickerMigrateUtil.h"
#import <CreationKitRTProtocol/ACCEditCanvasProtocol.h>
#import "AWEXScreenAdaptManager.h"
#import "ACCVideoEdgeDataHelper.h"
#import "ACCNLEHeaders.h"
#import "ACCNLELogger.h"
#import <CreationKitInfra/ACCConfigManager.h>
#import "ACCConfigKeyDefines.h"
#import "AWERepoVideoInfoModel.h"
#import "ACCEditVideoDataDowngrading.h"

#import <NLEPlatform/NLEInterface.h>
#import <NLEPlatform/NLEConstDefinition.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <TTVideoEditor/IESVideoAddEdgeData.h>
#import <CameraClient/NLEEditor_OC+Extension.h>
#import "ACCNLEUtils.h"
#import <CameraClientModel/ACCVideoCanvasType.h>

@interface ACCNLEPublishEditorBuilder()

@property (nonatomic, weak) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong) NLEInterface_OC *nle;
@property (nonatomic, readonly) NLEEditor_OC *editor;
@property (nonatomic, strong) NSHashTable *subscribers;

@property (nonatomic, strong) NSMutableDictionary *slotNameUserInfoMap;

@end
@implementation ACCNLEPublishEditorBuilder
@synthesize mediaContainerView = _mediaContainerView;

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    ACC_CHECK_NLE_COMPATIBILITY(YES, publishModel);
    self = [super init];
    if (self) {
        _publishModel = publishModel;
    }
    return self;
}

- (ACCEditSessionWrapper *)buildEditSession
{   
    [NLELogger registerPerformer:[ACCNLELogger new]];
    // 1.set up preview
    [self.mediaContainerView builder];
    self.publishModel.repoVideoInfo.video.normalizeSize = self.mediaContainerView.bounds.size;
    // 2.create NLE Interface
    ACCNLEEditVideoData *nleVideoData = acc_videodata_take_nle(self.publishModel.repoVideoInfo.video);
    self.nle = nleVideoData.nle;
    
    if (self.nle.enableMultiTrack) {
        [nleVideoData.nleModel setCanvasRatioWithUpdateRelativeLocation:9.f / 16.f];
    }
    
    // restore sticker userinfo to nle if needed
    if (self.slotNameUserInfoMap.count) {
        [self.slotNameUserInfoMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL * _Nonnull stop) {
            [self.nle setUserInfo:obj forStickerSlot:key];
        }];
        [self.slotNameUserInfoMap removeAllObjects];
    }
    
    ACCEditSessionWrapper *wrapper = [[ACCEditSessionWrapper alloc] initWithEditorSession:self.nle.veEditor];
    // DI editor to all submodule subscribers
    for (id<ACCEditBuildListener> listener in self.subscribers) {
        [listener onEditSessionInit:wrapper];
        if ([listener respondsToSelector:@selector(onNLEEditorInit:)]) {
            [listener onNLEEditorInit:self.nle];
        }
    }
    AWELogToolInfo2(@"ACCNLEEditorBuilder", AWELogToolTagEdit, @"NLE::EDITOR:::nle editor create success!");
    
    // 恢复 NLEModel 数据
    [self.editor setModel:nleVideoData.nleModel];
    [self.editor acc_commitAndRender:nil];
    
    [self.nle resetPlayerWithViews:@[self.mediaContainerView]];

    return wrapper;
}

- (void)resetEditSessionWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    self.publishModel = publishModel;
}

- (void)resetPreModel {
    [self.nle ResetPreModel];
}

#pragma mark -

- (void)resetPlayerAndPreviewEdge {
    [self.mediaContainerView resetView];
    [self.nle resetPlayerWithViews:@[self.mediaContainerView]];
    BOOL needAdaptScreen = [AWEXScreenAdaptManager needAdaptScreen] && ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay);
    if (needAdaptScreen) {
        NSValue *outputSize = [ACCVideoEdgeDataHelper sizeValueOfViewWithPublishModel:self.publishModel];
        if (outputSize) {
            BOOL aspectFill = [AWEXScreenAdaptManager aspectFillForRatio:outputSize.CGSizeValue isVR:NO];
            NLEPlayerPreviewMode previewMode = aspectFill ? NLEPlayerPreviewModePreserveAspectRatioAndFill : NLEPlayerPreviewModePreserveAspectRatio;
            [self.nle setPreviewModeType:previewMode];
            self.mediaContainerView.coverImageView.contentMode = aspectFill ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit;
        }
    }
    
    BOOL needPreviewEdge = YES;
    IESVideoAddEdgeData *edge = [ACCVideoEdgeDataHelper buildAddEdgeDataWithTranscoderParam:self.publishModel.repoVideoInfo.video.transParam publishModel:self.publishModel];
    CGSize previewEdgeSize = edge.targetFrameSize;
    NSValue *outputSize = [ACCVideoEdgeDataHelper sizeValueOfViewWithPublishModel:self.publishModel];
    if (needAdaptScreen && outputSize && [AWEXScreenAdaptManager aspectFillForRatio:[outputSize CGSizeValue] isVR:NO] && !AWECGSizeIsNaN(previewEdgeSize)) {
        CGSize sizeOfVideo = [outputSize CGSizeValue];
        CGFloat ratio = previewEdgeSize.width / previewEdgeSize.height;
        CGFloat videoRatio = sizeOfVideo.width / sizeOfVideo.height;
        if (ABS(ratio - videoRatio) > 0.001) {
            edge.addEdgeMode = IESAddEdgeModeFit;
            CGRect videoFrameRect = CGRectZero;
            videoFrameRect.size = previewEdgeSize;
            if (ratio > videoRatio) {
                videoFrameRect.origin.y = round((previewEdgeSize.height - previewEdgeSize.width / videoRatio) * 0.5);
                needPreviewEdge = NO;
            } else {
                videoFrameRect.origin.x = round((previewEdgeSize.width - previewEdgeSize.height * videoRatio) * 0.5);
            }
            edge.videoFrameRect = videoFrameRect;
        }
    }
    self.publishModel.repoVideoInfo.playerFrame = self.mediaContainerView.frame;
    
    if (self.publishModel.repoVideoInfo.canvasType != ACCVideoCanvasTypeNone) {
        needPreviewEdge = NO;
    }
    
    if (needPreviewEdge) {
        [self.nle setPreviewEdge:edge];
        self.publishModel.repoVideoInfo.video.infoStickerAddEdgeData = edge;
    }
}


- (void)addEditSessionListener:(nonnull id<ACCEditBuildListener>)listener {
    if ([listener respondsToSelector:@selector(setupPublishViewModel:)]) {
        [listener setupPublishViewModel:self.publishModel];
    }
    
    if (self.nle) {
        [listener onEditSessionInit:[[ACCEditSessionWrapper alloc] initWithEditorSession:self.nle.veEditor]];
        if ([listener respondsToSelector:@selector(onNLEEditorInit:)]) {
            [listener onNLEEditorInit:self.nle];
        }
    } else {
        [self.subscribers addObject:listener];
    }
}

- (void)restoreStickerUserInfoToNLE {
    NSArray<IESInfoSticker *> *infoStickersWithUserInfo = [self.publishModel.repoVideoInfo.video.infoStickers acc_filter:^BOOL(IESInfoSticker * _Nonnull item) {
        return item.userinfo != nil;
    }];

    for (IESInfoSticker *sticker in infoStickersWithUserInfo) {
        NSString *slotName = [sticker.userinfo acc_stringValueForKey:NLEStickerUserInfoSlotName];
        if (slotName) {
            self.slotNameUserInfoMap[slotName] = sticker.userinfo;
        }
    }
}

#pragma mark - getter

- (NLEEditor_OC *)editor {
    return self.nle.editor;
}

- (UIView<ACCMediaContainerViewProtocol> *)mediaContainerView
{
    if (!_mediaContainerView) {
        _mediaContainerView = [[ACCMediaContainerView alloc] initWithPublishModel:self.publishModel];
    }
    return _mediaContainerView;
}

- (NSHashTable *)subscribers
{
    if (!_subscribers) {
        _subscribers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return _subscribers;
}

- (NSMutableDictionary *)slotNameUserInfoMap {
    if (!_slotNameUserInfoMap) {
        _slotNameUserInfoMap = [NSMutableDictionary dictionary];
    }
    return _slotNameUserInfoMap;
}

@end

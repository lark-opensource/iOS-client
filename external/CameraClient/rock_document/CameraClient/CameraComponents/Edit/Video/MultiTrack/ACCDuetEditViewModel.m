//
//  ACCDuetEditViewModel.m
//  CameraClient-Pods-AwemeCore
//
//  Created by 饶骏华 on 2021/9/24.
//

#import "ACCDuetEditViewModel.h"

#import <CameraClient/ACCNLEUtils.h>
#import <CameraClient/AWERepoDuetModel.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CameraClient/ACCDuetLayoutModel.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CameraClient/AWERepoDuetModel.h>
#import <CameraClient/ACCDuetLayoutModel.h>
#import <CameraClient/AWERepoDraftModel.h>
#import <CameraClient/NLEModel_OC+Extension.h>
#import <CameraClient/NLETrack_OC+Extension.h>
#import <CameraClient/NLETrackSlot_OC+Extension.h>
#import <CameraClient/NLEEditor_OC+Extension.h>
#import <CameraClient/ACCEditVideoDataDowngrading.h>
#import <CameraClient/ACCEditorConfig.h>
#import <CameraClient/ACCConfigKeyDefines.h>

#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

#import <MobileCoreServices/UTCoreTypes.h>

@implementation ACCDuetEditViewModel

+ (BOOL)enableDuetMultiTrackWithPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel {
    BOOL enableNLE = [ACCNLEUtils useNLEWithRepository:publishViewModel];
    BOOL isDuet = publishViewModel.repoDuet.isDuet;
    BOOL isDuetUpload = publishViewModel.repoDuet.isDuetUpload;
    return enableNLE && isDuetUpload && isDuet;
}

+ (void)configImpotMultiTrackDuetWithPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel {
    if (![self enableDuetMultiTrackWithPublishViewModel:publishViewModel]) {
        AWELogToolError2(@"Duet", AWELogToolTagImport, @"import Duet unsupport.");
        return;
    }
    
    if (publishViewModel.repoDraft.isDraft || publishViewModel.repoDraft.isBackUp) {
        // 草稿恢复不需要重新配置nle模型
        AWELogToolInfo2(@"Duet", AWELogToolTagImport, @"recover config impot MultiTrack duet from draft.");
        return;
    }
    
    NSString *duetLayout = publishViewModel.repoDuet.duetLayout;
    NSString *duetLayoutMessage = publishViewModel.repoDuet.duetLayoutMessage;
    NSArray<NSString *> *supportLayoutList = [ACCDuetLayoutFrameModel supportDuetLayoutFrameList];
    __block BOOL support = NO;
    [supportLayoutList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([duetLayout isEqualToString:obj]) {
            support = YES;
            *stop = YES;
        }
    }];
    
    ACCDuetLayoutFrameModel *layoutFrame;
    if (support) {
        layoutFrame = [ACCDuetLayoutFrameModel configDuetLayoutFrameModelWithString:duetLayoutMessage];
    } else {
        // 不支持的布局默认实现左右布局
        duetLayout = supportDuetLayoutNewLeft;
        AWELogToolError2(@"Duet", AWELogToolTagImport, @"Duet multi track unsupport layout:%@", publishViewModel.repoDuet.duetLayout);
    }
    
    ACCEditVideoData *videoData = publishViewModel.repoVideoInfo.video;
    ACCNLEEditVideoData *nleVideoData = acc_videodata_take_nle(videoData);
    NLEModel_OC *nleModel = nleVideoData.nleModel;
    
    // 1.初始化被合拍视频bgm音轨
    [self setupDuetMultiTrackAudioTrackWithPublishViewModel:publishViewModel nleModel:nleModel];
    // 2.初始化合拍多轨画布
    [self setupDuetMultiTrackCanvas:nleModel];
    // 3.对齐合拍裁剪时长
    [self handleDuetMinimunClipTimeWithNLEModel:nleModel publishViewModel:publishViewModel];
    // 4.处理合拍布局
    if ([duetLayout isEqualToString:supportDuetLayoutNewRight] || [duetLayout isEqualToString:supportDuetLayoutNewLeft]) {
        [self handleDuetLayoutLeftToRight:[duetLayout isEqualToString:supportDuetLayoutNewLeft] nleModel:nleModel];
    } else if ([duetLayout isEqualToString:supportDuetLayoutNewUp] || [duetLayout isEqualToString:supportDuetLayoutNewDown]) {
        [self handleDuetLayoutUpToDown:[duetLayout isEqualToString:supportDuetLayoutNewUp] layoutFrameModel:layoutFrame publishViewModel:publishViewModel nleModel:nleModel];
    } else if ([duetLayout isEqualToString:supportDuetLayoutPictureInPicture]) {
        [self handleDuetLayoutPictureInPicture:layoutFrame publishViewModel:publishViewModel nleModel:nleModel];
    }
}

#pragma mark - Duet
+ (void)setupDuetMultiTrackAudioTrackWithPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel
                                             nleModel:(NLEModel_OC *)nleModel {
    AVAsset *duetSourceAsset = [AVURLAsset URLAssetWithURL:publishViewModel.repoDuet.duetLocalSourceURL options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
    if (!duetSourceAsset) { // 被合拍视频是添加在副轨道使用两者皆可，对齐拍摄合拍添加音轨优先使用duetLocalSourceURL
        AWELogToolInfo2(@"Duet", AWELogToolTagImport, @"duetLocalSourceURL asset is null.");
        NSArray<AVAsset *> *subAssets = [publishViewModel.repoVideoInfo.video.subTrackVideoAssets copy];
        duetSourceAsset = subAssets.firstObject;
    }
    
    if (publishViewModel.repoDuet.duetUploadType == ACCDuetUploadTypeVideo) {
        CGFloat assetVolume = ACCConfigDouble(kConfigDouble_duet_import_asset_volume) * 10;
        // 配置合拍导入素材的音量，导入素材添加在主轨
        [nleModel acc_setVideoVolumn:assetVolume forTrackCondition:^BOOL(NLETrack_OC * _Nonnull track) {
            return track.isMainTrack;
        }];
    }
        
    if (duetSourceAsset) {
        // 添加被合拍视频配乐bgm音轨
        ACCEditVideoData *videoData = publishViewModel.repoVideoInfo.video;
        [videoData addAudioWithAsset:duetSourceAsset];
        // 设置附轨道音量为0，由bgm音轨道控制被合拍视频音量
        [nleModel acc_setVideoVolumn:0 forTrackCondition:^BOOL(NLETrack_OC * _Nonnull track) {
            return track.isVideoSubTrack;
        }];
    } else {
        AWELogToolInfo2(@"Duet", AWELogToolTagImport, @"setup duet audio track failed, asset is null.");
    }
}

+ (void)setupDuetMultiTrackCanvas:(NLEModel_OC *)nleModel {
    // 主轨道支持画布模式
    [[self getMainTrackSlotsWithNLEModel:nleModel] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        if (!obj.videoSegment.canvasStyle) {
            obj.videoSegment.canvasStyle = [[NLEStyCanvas_OC alloc] init];
        }
    }];
    
    // 目前只支持一条副轨道，副轨道支持画布模式
    NLETrack_OC *subTrack = [[nleModel tracksWithType:NLETrackVIDEO] acc_match:^BOOL(NLETrack_OC * _Nonnull item) {
        return item.isVideoSubTrack;
    }];
    [[subTrack slots] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        if (!obj.videoSegment.canvasStyle) {
            obj.videoSegment.canvasStyle = [[NLEStyCanvas_OC alloc] init];
        }
        obj.layer = subTrack.layer;
    }];
}

+ (void)handleDuetMinimunClipTimeWithNLEModel:(NLEModel_OC *)nleModel  publishViewModel:(AWEVideoPublishViewModel *)publishViewModel {
    // 取最小视频时长进行裁减
    CMTime mainTrackDuration = [self mainTrackDurationWithNLEModel:nleModel];
    CMTime subTrackDuration = [self subTrackDurationWithNLEModel:nleModel];
    CMTime minimunDuration = subTrackDuration;
    CMTime differenceDuration = CMTimeMake(500, 10000);
    if (publishViewModel.repoDuet.duetUploadType == ACCDuetUploadTypeVideo) { // 主轨导入的素材为视频
        minimunDuration = CMTimeMinimum(mainTrackDuration, subTrackDuration);
        int32_t compareResult = CMTimeCompare(mainTrackDuration, subTrackDuration);
        if (compareResult == -1) {
            // 副轨道视频比主轨道视频长
            [self updateMainTrackWithClipTimeEnd:minimunDuration nleModel:nleModel];
            [self updateSubTrackWithClipTimeEnd:minimunDuration nleModel:nleModel];
        } else {
            // 主轨道视频时长大于或等于副轨道视频时长，对齐时长减少CMTimeMake(1, 20)，防止副轨道黑帧
            CMTime mainDuraion = CMTimeSubtract(minimunDuration, differenceDuration);
            [self updateMainTrackWithClipTimeEnd:mainDuraion nleModel:nleModel];
            [self updateSubTrackWithClipTimeEnd:minimunDuration nleModel:nleModel];
        }
    } else {
        // 导入图片素材对齐被合拍视频时长
        CMTime mainDuraion = CMTimeSubtract(minimunDuration, differenceDuration);
        [self updateMainTrackWithClipTimeEnd:mainDuraion nleModel:nleModel];
        [self updateSubTrackWithClipTimeEnd:minimunDuration nleModel:nleModel];
    }
}

+ (void)handleDuetLayoutLeftToRight:(BOOL)leftToRight nleModel:(NLEModel_OC *)nleModel {
    float mainTransformX = 0;
    float subTransformX = 0;
    if (leftToRight) {
        mainTransformX = -0.25;
        subTransformX = 0.25;
    } else {
        mainTransformX = 0.25;
        subTransformX = -0.25;
    }
    [self updateMainTrackWithTransformX:mainTransformX transformY:0 scale:0.5 nleModel:nleModel];
    [self updateSubTrackWithTransformX:subTransformX transformY:0 scale:0.5 nleModel:nleModel];
}

+ (void)handleDuetLayoutUpToDown:(BOOL)upToDown
                layoutFrameModel:(ACCDuetLayoutFrameModel *)layoutFrameModel
                publishViewModel:(AWEVideoPublishViewModel *)publishViewModel
                        nleModel:(NLEModel_OC *)nleModel {
    CGSize mainAssetSize = [self sizeWithNleModel:nleModel mainTrack:YES]; // 导入的素材
    CGSize canvasSize = publishViewModel.repoVideoInfo.video.canvasSize; // 画布大小
    
    CGFloat halfCutRange = 0.5f;
    if (mainAssetSize.height == 0 || canvasSize.height == 0) {
        AWELogToolError2(@"Duet", AWELogToolTagImport, @"Duet mainAsset size:%@, canvasSize:%@", NSStringFromCGSize(mainAssetSize), NSStringFromCGSize(canvasSize));
    } else {
        // 计算高超出情况截取范围
        CGFloat mainAssetRatio = mainAssetSize.width / mainAssetSize.height;
        CGFloat canvasRatio = (canvasSize.width / canvasSize.height) * 2;
        if (mainAssetRatio <= canvasRatio && canvasRatio != 0) { // 宽 < 高
            CGFloat targetHeight = mainAssetSize.width / canvasRatio;
            halfCutRange = (targetHeight / mainAssetSize.height) / 2;
        }
    }
    
    // 归一化坐标 左上(0,0) 右下(1,1) 中心(0.5,0.5)
    CGPoint mainLeftTopPoint = CGPointMake(0, 0.5 - halfCutRange);
    CGPoint mainRightBottomPoint = CGPointMake(1, 0.5f + halfCutRange);
    [self updateMainTrackWithCropLeftTopPoint:mainLeftTopPoint rightBottomPoint:mainRightBottomPoint nleModel:nleModel];
  
    CGPoint subLeftTopPoint = CGPointMake(0, 0);
    CGPoint subRightBottomPoint = CGPointMake(1, 1);
    if (layoutFrameModel) {
        subLeftTopPoint = CGPointMake(layoutFrameModel.x1, layoutFrameModel.y1);
        subRightBottomPoint = CGPointMake(layoutFrameModel.x2, layoutFrameModel.y2);
    } else {
        AWELogToolError2(@"Duet", AWELogToolTagImport, @"Duet LayoutUpToDown layoutFrameModel is null.");
    }
    [self updateSubTrackWithCropLeftTopPoint:subLeftTopPoint rightBottomPoint:subRightBottomPoint nleModel:nleModel];
        
    CGFloat mainTransformY = 0.25;
    CGFloat subTransformY = - 0.25;
    if (upToDown) {
        mainTransformY = - 0.25;
        subTransformY = 0.25;
    }
    [self updateMainTrackWithTransformX:0 transformY:mainTransformY scale:1 nleModel:nleModel];
    [self updateSubTrackWithTransformX:0 transformY:subTransformY scale:1 nleModel:nleModel];
}

+ (void)handleDuetLayoutPictureInPicture:(ACCDuetLayoutFrameModel *)layoutFrameModel
                        publishViewModel:(AWEVideoPublishViewModel *)publishViewModel
                                nleModel:(NLEModel_OC *)nleModel  {
    [self updateMainTrackWithTransformX:0 transformY:0 scale:1 nleModel:nleModel];
    // 处理画中画被合拍视频
    CGFloat defaultScale = 1.0f;
    CGFloat scaleX = 0.3;
    CGFloat scaleY =  0.3;
    CGFloat centerX = 0.25;
    CGFloat centerY = 0.25;
    CGPoint centerPoint = CGPointMake(centerX - 0.5, centerY - 0.5);
    if (layoutFrameModel) {
        scaleX = (layoutFrameModel.x2 - layoutFrameModel.x1) / defaultScale;
        scaleY = (layoutFrameModel.y2 - layoutFrameModel.y1) / defaultScale;
        // 归一化坐标 取值范围[-1,1]，左上(-1,1) 右下(1,1) 中心点(0,0)
        centerX = layoutFrameModel.x1 + (layoutFrameModel.x2 - layoutFrameModel.x1)/2;
        centerY = layoutFrameModel.y1 + (layoutFrameModel.y2 - layoutFrameModel.y1)/2;
        centerPoint = CGPointMake(centerX - 0.5, centerY - 0.5);
    } else {
        AWELogToolError2(@"Duet", AWELogToolTagImport, @"PictureInPicture Duet layoutFrameModel is null.");
    }
    // 抢镜视频位移和缩放
    CGFloat transformScale = scaleY > scaleX ? scaleY : scaleX;
    [self updateSubTrackWithTransformX:centerPoint.x transformY:centerPoint.y scale:transformScale nleModel:nleModel];
    // 兼容后续安卓草稿迁移，画布外圈描边
    [self updateSubTrackCanvasStyleWithBorderWidth:2 borderColor:[UIColor whiteColor] nleModel:nleModel];
    // 计算抢镜被合拍视频的边框自定义贴纸，后续多轨画布边框应由ve实现
    CGSize videoSize = [self sizeWithNleModel:nleModel mainTrack:NO]; // 被合拍的素材
    
    if (videoSize.width == 0 || videoSize.height == 0) {
        AWELogToolError2(@"Duet", AWELogToolTagImport, @"PictureInPicture Duet layout draw border failed, videoSize:%@", NSStringFromCGSize(videoSize));
        return;
    }
    
    ACCEditorConfig *editorConfig = [ACCEditorConfig editorConfigWithPublishModelAndEnsurePublishModelIsConfiged:publishViewModel];
    CGSize playerSize = editorConfig.playerFrame.size;
    // 默认是使用定宽计算高度
    CGFloat relativeWidth = playerSize.width;
    CGFloat relativeHeight = (playerSize.width * videoSize.height) / videoSize.width;
    CGFloat relativeScale = scaleX;
    if (scaleY > scaleX) { // 高宽比大于屏幕比例，使用定高计算
        relativeHeight = playerSize.height;
        relativeWidth = (playerSize.height * videoSize.width) / videoSize.height;
        relativeScale = scaleY;
    }
    CGFloat offset = 4;
    CGFloat videoWidth = relativeScale * relativeWidth + offset;
    CGFloat videoHeight = relativeScale * relativeHeight + offset;
    UIView *container = [[UIView alloc] init];
    container.backgroundColor = [UIColor clearColor];
    container.layer.borderWidth = 2;
    container.layer.borderColor = [[UIColor whiteColor] CGColor];
    container.layer.frame = CGRectMake(0, 0, videoWidth, videoHeight);
    UIGraphicsBeginImageContextWithOptions(container.bounds.size, NO, 0);
    [container.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGFloat maxEdgeNumber = MAX(videoWidth, videoHeight);
    [editorConfig.stickerConfigAssembler addCustomSticker:^(ACCEditorCustomStickerConfig * _Nonnull config) {
        config.image = image;
        config.dataUIT = (id)(kUTTypePNG);
        config.maxEdgeNumber = @(maxEdgeNumber);
        config.location.x = centerX;
        config.location.y = centerY;
        config.deleteable = NO;
        config.editable = NO;
        config.supportedGestureType = NO;
        config.layerIndex = -1000;
    }];
}

#pragma mark - Utils

+ (void)updateMainTrackWithTransformX:(float)transformX transformY:(float)transformY scale:(float)scale nleModel:(NLEModel_OC *)nleModel {
    [[self getMainTrackSlotsWithNLEModel:nleModel] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        obj.transformX = transformX;
        obj.transformY = transformY;
        obj.scale = scale;
    }];
}

+ (void)updateSubTrackWithTransformX:(float)transformX transformY:(float)transformY scale:(float)scale nleModel:(NLEModel_OC *)nleModel {
    [[self getSubTrackSlotsWithNLEModel:nleModel] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        obj.transformX = transformX;
        obj.transformY = transformY;
        obj.scale = scale;
    }];
}

+ (void)updateMainTrackWithCropLeftTopPoint:(CGPoint)leftTopPoint rightBottomPoint:(CGPoint)rightBottomPoint nleModel:(NLEModel_OC *)nleModel {
    [[self getMainTrackSlotsWithNLEModel:nleModel] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        NLESegmentVideo_OC *videoSegment = ACCDynamicCast(obj.videoSegment, NLESegmentVideo_OC);
        NLEStyCrop_OC *crop = videoSegment.crop;
        if (!crop) {
            crop =  [[NLEStyCrop_OC alloc] init];
        }
        crop.upperLeftX = leftTopPoint.x;
        crop.upperLeftY = leftTopPoint.y;
        crop.lowerRightX = rightBottomPoint.x;
        crop.lowerRightY = rightBottomPoint.y;
        videoSegment.crop = crop;
    }];
}

+ (void)updateSubTrackWithCropLeftTopPoint:(CGPoint)leftTopPoint rightBottomPoint:(CGPoint)rightBottomPoint nleModel:(NLEModel_OC *)nleModel {
    [[self getSubTrackSlotsWithNLEModel:nleModel] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        NLESegmentVideo_OC *videoSegment = ACCDynamicCast(obj.videoSegment, NLESegmentVideo_OC);
        NLEStyCrop_OC *crop = videoSegment.crop;
        if (!crop) {
            crop =  [[NLEStyCrop_OC alloc] init];
        }
        crop.upperLeftX = leftTopPoint.x;
        crop.upperLeftY = leftTopPoint.y;
        crop.lowerRightX = rightBottomPoint.x;
        crop.lowerRightY = rightBottomPoint.y;
        videoSegment.crop = crop;
    }];
}

+ (void)updateSubTrackCanvasStyleWithBorderWidth:(NSInteger)borderWidth borderColor:(UIColor *)borderColor nleModel:(NLEModel_OC *)nleModel {
    [[self getSubTrackSlotsWithNLEModel:nleModel] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        NLESegmentVideo_OC *videoSegment = ACCDynamicCast(obj.videoSegment, NLESegmentVideo_OC);
        NLEStyCanvas_OC *canvasStyle = videoSegment.canvasStyle;
        if (!canvasStyle) {
            canvasStyle = [[NLEStyCanvas_OC alloc] init];
            videoSegment.canvasStyle = canvasStyle; // 这里需要先赋值，后续setCanvasSource方法才能正常调用
        }
        // slot后续剥离IESMMCanvasSource做配置
        IESMMCanvasSource *canvasSource = obj.canvasSource;
        canvasSource.borderWidth = borderWidth;
        canvasSource.borderColor = borderColor;
        [obj setCanvasSource:canvasSource];
    }];
}

+ (CGSize)sizeWithNleModel:(NLEModel_OC *)nleModel mainTrack:(BOOL)mainTrack {
    NSArray<NLETrackSlot_OC *> *allSlots =
    [[[nleModel tracksWithType:NLETrackVIDEO] acc_filter:^BOOL(NLETrack_OC * _Nonnull item) {
        if (mainTrack) {
            return item.isMainTrack;
        } else {
            return item.isVideoSubTrack && !item.isMainTrack;
        }
    }] acc_flatMap:^NSArray * _Nonnull(NLETrack_OC *_Nonnull obj) {
        return [obj slots];
    }];
    
    NLETrackSlot_OC *curSlot = allSlots.firstObject;
    if (curSlot) {
        NLESegmentVideo_OC *videoSegment = ACCDynamicCast(curSlot.videoSegment, NLESegmentVideo_OC);
        NLEResourceAV_OC *resource = videoSegment.videoFile;
        return CGSizeMake(resource.width, resource.height);
    } else {
        AWELogToolError2(@"multiTrack", AWELogToolTagImport, @"asset is not assmble, size not found.");
        return CGSizeZero;
    }
}

+ (void)updateMainTrackWithClipTimeEnd:(CMTime)timeClipEnd nleModel:(NLEModel_OC *)nleModel {
    [[self getMainTrackSlotsWithNLEModel:nleModel] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        obj.startTime = CMTimeMake(0 * USEC_PER_SEC, USEC_PER_SEC);
        obj.endTime = timeClipEnd;
        NLESegmentVideo_OC *videoSegment = ACCDynamicCast(obj.videoSegment, NLESegmentVideo_OC);
        videoSegment.timeClipStart =  CMTimeMake(0 * USEC_PER_SEC, USEC_PER_SEC);
        videoSegment.timeClipEnd = timeClipEnd;
    }];
}

+ (void)updateSubTrackWithClipTimeEnd:(CMTime)timeClipEnd nleModel:(NLEModel_OC *)nleModel {
    [[self getSubTrackSlotsWithNLEModel:nleModel] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        obj.startTime = CMTimeMake(0 * USEC_PER_SEC, USEC_PER_SEC);
        obj.endTime = timeClipEnd;
        NLESegmentVideo_OC *videoSegment = ACCDynamicCast(obj.videoSegment, NLESegmentVideo_OC);
        videoSegment.timeClipStart = CMTimeMake(0 * USEC_PER_SEC, USEC_PER_SEC);
        videoSegment.timeClipEnd = timeClipEnd;
    }];
}

+ (CMTime)mainTrackDurationWithNLEModel:(NLEModel_OC *)nleModel {
    __block CMTime allDuration = kCMTimeZero;
    [[self getMainTrackSlotsWithNLEModel:nleModel] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        NLESegmentVideo_OC *videoSegment = ACCDynamicCast(obj.videoSegment, NLESegmentVideo_OC);
        CMTime duration = videoSegment.getDuration;
        allDuration = CMTimeAdd(allDuration, duration);
    }];
    return allDuration;
}

+ (CMTime)subTrackDurationWithNLEModel:(NLEModel_OC *)nleModel {
    __block CMTime allDuration = kCMTimeZero;
    [[self getSubTrackSlotsWithNLEModel:nleModel] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        NLESegmentVideo_OC *videoSegment = ACCDynamicCast(obj.videoSegment, NLESegmentVideo_OC);
        CMTime duration = videoSegment.getDuration;
        allDuration = CMTimeAdd(allDuration, duration);
    }];
    return allDuration;
}

+ (NSArray<NLETrackSlot_OC *> *)getMainTrackSlotsWithNLEModel:(NLEModel_OC *)nleModel  {
    NLETrack_OC *mainTrack = [[nleModel tracksWithType:NLETrackVIDEO] acc_match:^BOOL(NLETrack_OC * _Nonnull item) {
        return item.isMainTrack;
    }];
    return [mainTrack slots];
}

+ (NSArray<NLETrackSlot_OC *> *)getSubTrackSlotsWithNLEModel:(NLEModel_OC *)nleModel  {
    // 目前只支持一条副轨道，副轨道支持画布模式
    NLETrack_OC *subTrack = [[nleModel tracksWithType:NLETrackVIDEO] acc_match:^BOOL(NLETrack_OC * _Nonnull item) {
        return item.isVideoSubTrack;
    }];
    return [subTrack slots];
}

@end

//
//  ACCNLEEditMultiTrackWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/9/17.
//

#import "ACCNLEEditMultiTrackWrapper.h"

#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMacros.h>

#import "ACCNLEEditVideoData.h"
#import "NLEModel_OC+Extension.h"
#import "NLETrack_OC+Extension.h"
#import "NLETrackSlot_OC+Extension.h"
#import "NLEEditor_OC+Extension.h"
#import "ACCEditVideoDataDowngrading.h"
#import "ACCNLEBundleResource.h"

@interface ACCNLEEditMultiTrackWrapper() <ACCEditBuildListener>

@property (nonatomic, weak) NLEInterface_OC *nle;
@property (nonatomic, weak) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, weak) id<ACCEditSessionProvider> editSessionProvider;

@end

@implementation ACCNLEEditMultiTrackWrapper

- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider {
    [editSessionProvider addEditSessionListener:self];
}

#pragma mark - ACCEditBuildListener

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editorSession {
    // 用于ve editSession兼容实现
}

- (void)onNLEEditorInit:(NLEInterface_OC *)editor {
    self.nle = editor;
}
   
- (void)setupPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel {
    self.publishModel = publishViewModel;
}

#pragma mark - Public

- (void)setupMultiTrackCanvas {
    // 主轨道支持画布模式
    [[self getMainTrackSlots] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        if (!obj.videoSegment.canvasStyle) {
            obj.videoSegment.canvasStyle = [[NLEStyCanvas_OC alloc] init];
        }
    }];
    
    // 目前只支持一条副轨道，副轨道支持画布模式
    NLEModel_OC *nleModel = [self.nle.editor getModel];
    NLETrack_OC *subTrack = [[nleModel tracksWithType:NLETrackVIDEO] acc_match:^BOOL(NLETrack_OC * _Nonnull item) {
        return item.isVideoSubTrack;
    }];
    [[subTrack slots] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        if (!obj.videoSegment.canvasStyle) {
            obj.videoSegment.canvasStyle = [[NLEStyCanvas_OC alloc] init];
        }
        obj.layer = subTrack.layer;
    }];
    
    [self commitAndRender];
}

#pragma mark - information

- (CGSize)sizeWithAsset:(AVAsset *)asset {
    NLEModel_OC *nleModel = [self.nle.editor getModel];
    NSArray<NLETrackSlot_OC *> *allSlots = [[nleModel tracksWithType:NLETrackVIDEO] acc_flatMap:^NSArray * _Nonnull(NLETrack_OC * _Nonnull obj) {
        return [obj slots];
    }];
    NLETrackSlot_OC *curSlot = [allSlots acc_match:^BOOL(NLETrackSlot_OC * _Nonnull item) {
        return [self.nle acc_slot:item isRelateWithAsset:asset];
    }];
    if (curSlot) {
        NLESegmentVideo_OC *videoSegment = ACCDynamicCast(curSlot.videoSegment, NLESegmentVideo_OC);
        NLEResourceAV_OC *resource = videoSegment.videoFile;
        return CGSizeMake(resource.width, resource.height);
    } else {
        AWELogToolError2(@"multiTrack", AWELogToolTagImport, @"asset is not assmble, size not found.");
        return CGSizeZero;
    }
}

- (CMTime)mainTrackDuration {
    __block CMTime allDuration = kCMTimeZero;
    [[self getMainTrackSlots] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        NLESegmentVideo_OC *videoSegment = ACCDynamicCast(obj.videoSegment, NLESegmentVideo_OC);
        CMTime duration = videoSegment.getDuration;
        allDuration = CMTimeAdd(allDuration, duration);
    }];
    return allDuration;
}

- (CMTime)subTrackDuration {
    __block CMTime allDuration = kCMTimeZero;
    [[self getSubTrackSlots] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        NLESegmentVideo_OC *videoSegment = ACCDynamicCast(obj.videoSegment, NLESegmentVideo_OC);
        CMTime duration = videoSegment.getDuration;
        allDuration = CMTimeAdd(allDuration, duration);
    }];
    return allDuration;
}

#pragma mark - Action

- (void)updateMainTrackWithClipTimeEnd:(CMTime)timeClipEnd {
    [[self getMainTrackSlots] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        NLESegmentVideo_OC *videoSegment = ACCDynamicCast(obj.videoSegment, NLESegmentVideo_OC);
        videoSegment.timeClipStart =  CMTimeMake(0 * USEC_PER_SEC, USEC_PER_SEC);
        videoSegment.timeClipEnd = timeClipEnd;
    }];
    [self commitAndRender];
}

- (void)updateSubTrackWithClipTimeEnd:(CMTime)timeClipEnd {
    [[self getSubTrackSlots] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        NLESegmentVideo_OC *videoSegment = ACCDynamicCast(obj.videoSegment, NLESegmentVideo_OC);
        videoSegment.timeClipStart =  CMTimeMake(0 * USEC_PER_SEC, USEC_PER_SEC);
        videoSegment.timeClipEnd = timeClipEnd;
    }];
    [self commitAndRender];
}

- (void)updateMainTrackWithTransformX:(float)transformX transformY:(float)transformY scale:(float)scale {
    [[self getMainTrackSlots] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        obj.transformX = transformX;
        obj.transformY = transformY;
        obj.scale = scale;
    }];
    [self commitAndRender];
}

- (void)updateSubTrackWithTransformX:(float)transformX transformY:(float)transformY scale:(float)scale {
    [[self getSubTrackSlots] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        obj.transformX = transformX;
        obj.transformY = transformY;
        obj.scale = scale;
    }];
    [self commitAndRender];
}

- (void)updateMainTrackWithCropLeftTopPoint:(CGPoint)leftTopPoint rightBottomPoint:(CGPoint)rightBottomPoint {
    [[self getMainTrackSlots] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
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
    [self commitAndRender];
}

- (void)updateSubTrackWithCropLeftTopPoint:(CGPoint)leftTopPoint rightBottomPoint:(CGPoint)rightBottomPoint { 
    [[self getSubTrackSlots] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
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
    [self commitAndRender];
}

- (void)updateMainTrackCanvasStyleWithBorderWidth:(NSInteger)borderWidth borderColor:(UIColor *)borderColor { // 更新所有主轨道片段的画布外框
    [[self getMainTrackSlots] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        NLESegmentVideo_OC *videoSegment = ACCDynamicCast(obj.videoSegment, NLESegmentVideo_OC);
        NLEStyCanvas_OC *canvasStyle = videoSegment.canvasStyle;
        if (!canvasStyle) {
            canvasStyle = [[NLEStyCanvas_OC alloc] init];
            videoSegment.canvasStyle = canvasStyle;
        }
        // slot后续剥离IESMMCanvasSource做配置
        IESMMCanvasSource *canvasSource = obj.canvasSource;
        canvasSource.borderWidth = borderWidth;
        canvasSource.borderColor = borderColor;
        [obj setCanvasSource:canvasSource];
    }];
    [self commitAndRender];
}

- (void)updateSubTrackCanvasStyleWithBorderWidth:(NSInteger)borderWidth borderColor:(UIColor *)borderColor { // 更新所有副轨道片段的画布外框
    [[self getSubTrackSlots] acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
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
    [self commitAndRender];
}

#pragma mark - private

- (NSArray<NLETrackSlot_OC *> *)getMainTrackSlots {
    NLEModel_OC *nleModel = [self.nle.editor getModel];
    NLETrack_OC *mainTrack = [[nleModel tracksWithType:NLETrackVIDEO] acc_match:^BOOL(NLETrack_OC * _Nonnull item) {
        return item.isMainTrack;
    }];
    return [mainTrack slots];
}

- (NSArray<NLETrackSlot_OC *> *)getSubTrackSlots {
    NLEModel_OC *nleModel = [self.nle.editor getModel];
    // 目前只支持一条副轨道，副轨道支持画布模式
    NLETrack_OC *subTrack = [[nleModel tracksWithType:NLETrackVIDEO] acc_match:^BOOL(NLETrack_OC * _Nonnull item) {
        return item.isVideoSubTrack;
    }];
    return [subTrack slots];
}

- (void)commitAndRender {
    [self.nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
        if (error) {
            AWELogToolError2(@"multiTrack", AWELogToolTagImport, @"commitAndRender error:%@", error);
        }
    }];
}

@end

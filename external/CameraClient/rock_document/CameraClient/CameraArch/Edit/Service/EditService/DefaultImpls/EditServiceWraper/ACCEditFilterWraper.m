//
//  ACCEditFilterWraper.m
//  CameraClient
//
//  Created by haoyipeng on 2020/8/13.
//

#import "ACCEditFilterWraper.h"
#import "AWERepoVideoInfoModel.h"
#import "ACCEditVideoDataDowngrading.h"
#import <TTVideoEditor/VEEditorSession+Effect.h>
#import "VEEditorSession+ACCFilter.h"
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitArch/IESEffectModel+ComposerFilter.h>

@interface ACCEditFilterWraper () <ACCEditBuildListener>

@property (nonatomic, weak) VEEditorSession *player;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong, readonly) HTSVideoData *videoData;

@end

@implementation ACCEditFilterWraper

- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

#pragma mark - ACCEditBuildListener

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editSession
{
    self.player = editSession.videoEditSession;
}

- (void)setupPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel
{
    self.publishModel = publishViewModel;
}

- (HTSVideoData *)videoData
{
    return acc_videodata_take_hts(self.publishModel.repoVideoInfo.video);
}

#pragma mark - ACCEditFilterProtocol

- (void)applyFilterEffect:(nullable IESEffectModel *)effect {
    [self applyFilterEffect:effect intensity:1.f];
}

- (void)applyFilterEffect:(IESEffectModel *)effect intensity:(float)intensity {
    [self.player acc_applyFilterEffect:effect intensity:intensity videoData:self.videoData];
}

- (float)filterEffectOriginIndensity:(nullable IESEffectModel *)effect {
    return [self.player acc_filterEffectOriginIndensity:effect];
}

- (BOOL)switchColorLeftFilter:(IESEffectModel *)leftFilter
                  rightFilter:(IESEffectModel *)rightFilter
                   inPosition:(float)position
              inLeftIntensity:(float)leftIntensity
             inRightIntensity:(float)rightIntensity {
    
    return [self.player acc_switchColorLeftFilter:leftFilter rightFilter:rightFilter inPosition:position inLeftIntensity:leftIntensity inRightIntensity:rightIntensity videoData:self.videoData];
}

- (BOOL)switchColorLeftFilter:(IESEffectModel *)leftFilter
                  rightFilter:(IESEffectModel *)rightFilter
                   inPosition:(float)position {
    if (leftFilter.isComposerFilter || rightFilter.isComposerFilter) {
        return [self switchColorLeftFilter:leftFilter
                               rightFilter:rightFilter
                                inPosition:position
                           inLeftIntensity:leftFilter.filterConfigItem.defaultIntensity
                          inRightIntensity:rightFilter.filterConfigItem.defaultIntensity];
    } else {
        NSString *leftPath = [leftFilter filePathForCameraPosition:AVCaptureDevicePositionFront] ?: @"";
        NSString *rightPath = [rightFilter filePathForCameraPosition:AVCaptureDevicePositionFront] ?: @"";
        return [self switchColorFilterIntensity:leftPath
                                   inFilterPath:rightPath
                                     inPosition:position
                                inLeftIntensity:1.f
                               inRightIntensity:1.f];
    }
}

- (BOOL)switchColorFilterIntensity:(NSString *)leftFilterPath
                      inFilterPath:(NSString *)rightFilterPath
                        inPosition:(float)position
                   inLeftIntensity:(float)leftIntensity
                  inRightIntensity:(float)rightIntensity {
    return [self.player switchColorFilterIntensity:leftFilterPath
                                      inFilterPath:rightFilterPath
                                        inPosition:position
                                   inLeftIntensity:leftIntensity
                                  inRightIntensity:rightIntensity];
}

@end

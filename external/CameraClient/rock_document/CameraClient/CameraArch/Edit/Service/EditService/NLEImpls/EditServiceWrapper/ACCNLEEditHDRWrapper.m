//
//  ACCNLEEditHDRWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by HuangHongsen on 2021/2/7.
//

#import "ACCNLEEditHDRWrapper.h"
#import <NLEPlatform/NLEInterface.h>
#import <NLEPlatform/NLESegmentFilter+iOS.h>
#import <NLEPlatform/NLESegmentHDRFilter+iOS.h>
#import <NLEPlatform/NLEFilter+iOS.h>
#import <NLEPlatform/NLETrack+iOS.h>
#import <NLEPlatform/NLENativeDefine.h>
#import <CreativeKit/ACCMacros.h>
#import <TTVideoEditor/VEOneKeySceneStrategyConfig.h>
#import <TTVideoEditor/VEAlgorithmSessionConfig.h>
#import <TTVideoEditor/VEAlgorithmSession.h>
#import <TTVideoEditor/IESMMLogger.h>
#import "NLEModel_OC+Extension.h"
#import "NLEResourceAV_OC+Extension.h"
#import "NLEEditor_OC+Extension.h"
#import "NLETrack_OC+Extension.h"

@interface ACCNLEEditHDRWrapper()<ACCEditBuildListener>

@property (nonatomic, weak) NLEInterface_OC *nle;
@property (nonatomic, strong) VEAlgorithmSession *algorithmSession;
@property (nonatomic, assign) VEOneKeySceneCase oneKeyScene;

@end

@implementation ACCNLEEditHDRWrapper

- (void)setEditSessionProvider:(nonnull id<ACCEditSessionProvider>)editSessionProvider {
    [editSessionProvider addEditSessionListener:self];
}

- (void)enableLensHDRWithModelPath:(NSString *)modelPath {
    NLEResourceNode_OC *filterResource = [[NLEResourceNode_OC alloc] init];
    [filterResource acc_setGlobalResouceWithPath:modelPath];
    filterResource.resourceType = NLEResourceTypeFilter;
    
    NLESegmentHDRFilter_OC *filterSegment = [[NLESegmentHDRFilter_OC alloc] init];
    [filterSegment setEffectSDKFilter:filterResource];
    filterSegment.intensity = 1.f;
    filterSegment.filterName = LENS_HDR;
    
    NLETrack_OC *track = [[NLETrack_OC alloc] init];
    track.isLensHDRTrack = YES;
    NLETrackSlot_OC *slot = [[NLETrackSlot_OC alloc] init];
    slot.segment = filterSegment;
    [track addSlot:slot];
    [[self.nle.editor getModel] addTrack:track];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)disableLensHDR {
    NSArray <NLETrack_OC *> *tracks = [[self.nle.editor getModel] tracksWithType:NLETrackFILTER];
    for (NLETrack_OC *track in tracks) {
        if (track.isLensHDRTrack) {
            [[self.nle.editor getModel] removeTrack:track];
            break;
        }
    }
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)enableOneKeyHDRWithModel:(NSString *)modelPath
                  disableDenoise:(BOOL)disableDenoise
                         asfMode:(NSInteger)asfMode
                         hdrMode:(NSInteger)hdrMode
{
    [self p_removeAllHDRTrack];
    
    NLEResourceNode_OC *filterResource = [[NLEResourceNode_OC alloc] init];
    [filterResource acc_setGlobalResouceWithPath:modelPath];
    filterResource.resourceType = NLEResourceTypeFilter;
    
    NLESegmentHDRFilter_OC *filterSegment = [[NLESegmentHDRFilter_OC alloc] init];
    filterSegment.effectSDKFilter = filterResource;
    filterSegment.filterName = VIDEO_LENS_HDR;
    filterSegment.denoise = !disableDenoise;
    filterSegment.asfMode = asfMode;
    filterSegment.hdrMode = hdrMode;
    filterSegment.frameType = self.oneKeyScene;
    
    NLETrack_OC *track = [[NLETrack_OC alloc] init];
    track.isOneKeyHDRTrack = YES;
    NLETrackSlot_OC *slot = [[NLETrackSlot_OC alloc] init];
    slot.segment = filterSegment;
    [track addSlot:slot];
    [[self.nle.editor getModel] addTrack:track];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)disableOneKeyHDR
{
    NSArray <NLETrack_OC *> *tracks = [[self.nle.editor getModel] tracksWithType:NLETrackFILTER];
    NSMutableArray *tracksToRemove = [NSMutableArray array];
    for (NLETrack_OC *track in tracks) {
        if (track.isOneKeyHDRTrack) {
            [tracksToRemove addObject:track];
        }
    }
    for (NLETrack_OC *trackToRemove in tracksToRemove) {
        [[self.nle.editor getModel] removeTrack:trackToRemove];
    }
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)p_removeAllHDRTrack
{
    NSArray <NLETrack_OC *> *tracks = [[self.nle.editor getModel] tracksWithType:NLETrackFILTER];
    NSMutableArray *tracksToRemove = [NSMutableArray array];
    for (NLETrack_OC *track in tracks) {
        if (track.isLensHDRTrack || track.isOneKeyHDRTrack) {
            [tracksToRemove addObject:track];
        }
    }
    for (NLETrack_OC *trackToRemove in tracksToRemove) {
        [[self.nle.editor getModel] removeTrack:trackToRemove];
    }
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)startMatchingAlgorithmWithVideoData:(id<ACCEditVideoDataProtocol>)videoData
                                 completion:(nonnull void (^)(int))completion
{
    AVAsset *asset = [videoData.videoAssets firstObject];
    if (![asset isKindOfClass:[AVURLAsset class]]) {
        ACCBLOCK_INVOKE(completion, VEOneKeySceneCaseCommon);
        return ;
    }
    NSURL *url = ((AVURLAsset *)asset).URL;
    VEAlgorithmSessionConfig *config = [[VEAlgorithmSessionConfig alloc] init];
    config.type = VEAlgorithmSessionType_OneKeyHdr;
    
    VEAlgorithmSessionParamsOneKeyHdr *params = [VEAlgorithmSessionParamsOneKeyHdr new];
    params.resource_finder_path = url.path;
    params.resource_finder_t = [IESMMParamModule getResourceFinder];
    config.params = params;
    config.params.path = url.path;
    self.algorithmSession = [[VEAlgorithmSession alloc] initWithConfig:config error:nil];
    if (self.algorithmSession == nil) {
        IESMMLogI(@"algorithm session creation fails");
        return;
    }
    self.algorithmSession.progressCallback = ^(float progress) {
        IESMMLogI(@"progress is %f", progress);
    };
    
    @weakify(self)
    [self.algorithmSession startWithCompletion:^(VEAlgorithmSessionResult * _Nonnull result) {
        if (result.error == nil && result.type == VEAlgorithmSessionType_OneKeyHdr) {
            @strongify(self)
            self.oneKeyScene = [(VEAlgorithmSessionResultOneKeyHdr *)result scene];
            IESMMLogI(@"scene is %d", (int)self.oneKeyScene);
            // 这里进行增强调用
            ACCBLOCK_INVOKE(completion, self.oneKeyScene);
        } else {
            ACCBLOCK_INVOKE(completion, VEOneKeySceneCaseCommon);
            IESMMLogE(@"Algorithm Session Check Failed: %@", result.error);
        }
    }];
}

- (int)currentScene
{
    return self.oneKeyScene;
}

- (int)detectHDRScene
{
    self.oneKeyScene = [self.nle applyLensOneKeyHdrDetect];
    return self.oneKeyScene;
}

- (BOOL)shouldUseDenoise
{
    return self.oneKeyScene == VEOneKeySceneCaseNight;
}

#pragma mark - ACCEditBuildListener

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editorSession {}

- (void)onNLEEditorInit:(NLEInterface_OC *)editor
{
    self.nle = editor;
}

@end

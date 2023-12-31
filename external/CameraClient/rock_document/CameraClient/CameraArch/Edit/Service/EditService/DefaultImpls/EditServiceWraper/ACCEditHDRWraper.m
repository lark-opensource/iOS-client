//
//  ACCEditMusicWraper.m
//  CameraClient
//
//  Created by haoyipeng on 2020/9/10.
//

#import "ACCEditHDRWraper.h"
#import <TTVideoEditor/VEEditorSession+Effect.h>
#import <TTVideoEditor/VEAlgorithmSessionConfig.h>
#import <TTVideoEditor/IESMMParamModule.h>
#import <TTVideoEditor/VEAlgorithmSessionParams.h>
#import <TTVideoEditor/VEAlgorithmSession.h>
#import <TTVideoEditor/VEAlgorithmSessionResult.h>
#import <TTVideoEditor/IESMMLogger.h>
#import <TTVideoEditor/VEOneKeySceneStrategyConfig.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCEditHDRWraper () <ACCEditBuildListener>

@property (nonatomic, strong) VEAlgorithmSession *algorithmSession;
@property (nonatomic, assign) VEOneKeySceneCase oneKeyScene;
@property (nonatomic, weak) VEEditorSession *player;

@end

@implementation ACCEditHDRWraper

- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

#pragma mark - ACCEditBuildListener

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editSession
{
    self.player = editSession.videoEditSession;
    self.oneKeyScene = VEOneKeySceneCaseCommon;
}

- (void)enableLensHDRWithModelPath:(NSString *)modelPath
{
    [self.player applyLensHdrWithPath:modelPath ? : @""];
}

- (void)disableLensHDR
{
    [self.player applyLensHdrWithPath:@""];
}

- (int)detectHDRScene
{
    self.oneKeyScene = [self.player applyLensOneKeyHdrDetect];
    return self.oneKeyScene;
}

- (void)startMatchingAlgorithmWithVideoData:(id<ACCEditVideoDataProtocol>)videoData completion:(void (^)(int))completion
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
    params.path = url.path;
    config.params = params;
    
    NSError *error = nil;
    self.algorithmSession = [[VEAlgorithmSession alloc] initWithConfig:config error:&error];
    if (self.algorithmSession == nil || error) {
        IESMMLogI(@"algorithm session creation fails. error: %@", error);
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

- (void)enableOneKeyHDRWithModel:(NSString *)modelPath
                  disableDenoise:(BOOL)disableDenoise
                         asfMode:(NSInteger)asfMode
                         hdrMode:(NSInteger)hdrMode
{
    VEOneKeySceneStrategyConfig *param = [[VEOneKeySceneStrategyConfig alloc] init];
    param.modelPath = modelPath;
    param.disableDenoise = disableDenoise;
    param.sceneCase = self.oneKeyScene;
    param.asfMode = asfMode;
    param.hdrMode = hdrMode;
    [self.player applyLensOneKeyHdrInfo:param];
}

- (void)disableOneKeyHDR
{
    [self.player applyLensOneKeyHdrInfo:nil];
}

- (int)currentScene
{
    return self.oneKeyScene;
}

- (BOOL)shouldUseDenoise
{
    return self.oneKeyScene == VEOneKeySceneCaseNight;
}

@end

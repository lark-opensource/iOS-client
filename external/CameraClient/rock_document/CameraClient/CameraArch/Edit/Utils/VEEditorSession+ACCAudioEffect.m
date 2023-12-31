//
//  VEEditorSession+ACCAudioEffect.m
//  CameraClient
//
//  Created by haoyipeng on 2020/8/18.
//

#import "VEEditorSession+ACCAudioEffect.h"

#import <CreativeKit/ACCMacros.h>
#import <TTVideoEditor/VEAudioEffectPreprocessor.h>

#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCEditMVModel.h"

@implementation VEEditorSession (ACCAudioEffect)

- (void)acc_applyAudioEffectWithVideoData:(HTSVideoData *)videoData
                          audioEffectInfo:(IESMMEffectStickerInfo *)info
                         inPreProcessInfo:(nullable NSString *)infoData
                                  inBlock:(void (^)(NSString *str, NSError *outErr))block {
    @weakify(self);
    void (^doApplyEffect)(NSDictionary *) = ^(NSDictionary<AVAsset *,NSString *> *infoMap){
        @strongify(self);
        // construct filters for video assets
        for (AVAsset *videoAsset in videoData.videoAssets) {
            IESMMAudioPitchConfigV2 *config = [IESMMAudioPitchConfigV2 new];
            config.effectPath = info.path;
            // infoData关乎着效果的好坏
            config.infoData = infoMap[videoAsset];
            IESMMAudioFilter *pitchFilter = [IESMMAudioFilter new];
            pitchFilter.config = config.effectPath.length > 0 ? config : nil;
            pitchFilter.type = IESAudioFilterTypePitch;
            [self setAudioFilter:pitchFilter forVideoAssets:@[videoAsset]];
        }
        ACCBLOCK_INVOKE(block, nil, nil);
    };
    BOOL needsPreprocess = YES;
    if (needsPreprocess && info.path.length > 0) {
        //2. TODO: diff-get assets that needs preprocess
        NSArray *assetsToPreprocess = videoData.videoAssets;
        [VEAudioEffectPreprocessor preprocessAVAssets:assetsToPreprocess effectPath:info.path inRangeMap:videoData.videoTimeClipInfo completion:^(NSDictionary<AVAsset *,NSString *> *infoMap) {
            doApplyEffect(infoMap);
        }];
    } else {
        doApplyEffect(nil);
    }
}

- (float)acc_bgmVolume
{
    return self.bgmVolume;
}

- (void)acc_setVolumeForVideo:(float)volume videoData:(HTSVideoData *)videoData
{
    NSArray<AVAsset *> *videoAssets = videoData.videoAssets;
    float videoVolume = MAX(0, volume);
    
    if (videoData.mvModel) {
        videoAssets = [ACCEditMVModel videoAssetsSelectedByUserFromVideoData:videoData];
    }
    
    [self setVolume:videoVolume forVideoAssets:videoAssets];
    AWELogToolInfo(AWELogToolTagEdit, @"Volume Info setVolumeForVideo:%@, videoAssets:%@ ,lv is on", @(volume), videoData.videoAssets ? : @"");
}

- (void)acc_setVolumeForVideoSubTrack:(float)volume videoData:(HTSVideoData *)videoData
{
    [self setVolume:volume forVideoAssets:videoData.subTrackVideoAssets];
}

- (void)acc_setVolumeForAudio:(float)volume videoData:(HTSVideoData *)videoData
{
    if (self.acc_bgmAsset) {
        [self setVolume:volume forAudioAssets:@[self.acc_bgmAsset]];
    }
    AWELogToolInfo(AWELogToolTagEdit, @"Volume Info setVolumeForAudio:%@, bgmAsset:%@ ,lv is on", @(volume), self.acc_bgmAsset ? : @"");
}

#pragma mark - AssociatedObject

- (void)setAcc_bgmAsset:(AVAsset *)bgmAsset
{
    objc_setAssociatedObject(self, @selector(acc_bgmAsset), bgmAsset, OBJC_ASSOCIATION_RETAIN);
}

- (AVAsset *)acc_bgmAsset
{
    return objc_getAssociatedObject(self, @selector(acc_bgmAsset));
}

- (void)setAcc_isEffectPreprocessing:(BOOL)acc_isEffectPreprocessing
{
    objc_setAssociatedObject(self, @selector(acc_isEffectPreprocessing), @(acc_isEffectPreprocessing), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)acc_isEffectPreprocessing
{
    return [objc_getAssociatedObject(self, @selector(acc_isEffectPreprocessing)) boolValue];
}

- (void)setAcc_hadRecoveredVoiceEffect:(BOOL)acc_hadRecoveredVoiceEffect
{
    objc_setAssociatedObject(self, @selector(acc_hadRecoveredVoiceEffect), @(acc_hadRecoveredVoiceEffect), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)acc_hadRecoveredVoiceEffect
{
    return [objc_getAssociatedObject(self, @selector(acc_hadRecoveredVoiceEffect)) boolValue];
}

@end

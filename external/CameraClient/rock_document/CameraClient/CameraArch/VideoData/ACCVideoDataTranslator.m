//
//  ACCVideoDataTranslator.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/26.
//

#import "ACCVideoDataTranslator.h"
#import <NLEPlatform/NLEModel+iOS.h>
#import <NLEPlatform/NLEInterface.h>

@implementation ACCVideoDataTranslator

+ (ACCNLEEditVideoData *)translateWithVEModel:(ACCVEVideoData *)videoData nle:(NLEInterface_OC *)nle
{
    NLEModel_OC *model = [[NLEModel_OC alloc] initWithCanvasSize:videoData.canvasSize];
    [nle.editor setModel:model];
    ACCNLEEditVideoData *nleVideoData = [[ACCNLEEditVideoData alloc] initWithNLEModel:model nle:nle];
    [self p_copyVideoData:videoData toVideoData:nleVideoData];
    if (videoData.bgAudioAssets.count == 0) {
        // 非 K 歌模式，首次会剪裁一下音频时长，防止音频超过主轨视频度
        [nleVideoData acc_fixAudioClipRange];
    }
    return nleVideoData;
}

+ (ACCVEVideoData *)translateWithNLEModel:(ACCNLEEditVideoData *)videoData
{
    ACCVEVideoData *veVideoData = [[ACCVEVideoData alloc] initWithVideoData:[HTSVideoData videoData] draftFolder:videoData.draftFolder];
    [self p_copyVideoData:videoData toVideoData:veVideoData];
    return veVideoData;
}

+ (void)p_copyVideoData:(ACCEditVideoData *)l toVideoData:(ACCEditVideoData *)r
{
#define cp_property(property) r.property = l.property
    cp_property(identifier);
    cp_property(disableMetadataInfo);
    cp_property(dataInfo);
    cp_property(isFastImport);
    cp_property(isRecordFromCamera);
    cp_property(isMicMuted);
    cp_property(previewFrameRate);
    cp_property(maxTrackDuration);
    cp_property(importTransform);
    cp_property(metaRecordInfo);
    cp_property(movieInputFillType);
    cp_property(transParam);
    cp_property(importTransform);
    // 视频数据
    cp_property(photoAssetsInfo);
    cp_property(photoMovieAssets);
    cp_property(imageMovieInfo);
    cp_property(videoHeader);
    cp_property(videoAssets);
    cp_property(videoCurves);
    cp_property(subTrackVideoAssets);
    cp_property(videoTimeScaleInfo);
    cp_property(videoTimeClipInfo);
    cp_property(studio_videoClipResolveType);
    cp_property(videoSoundFilterInfo);
    // 音频数据
    cp_property(audioAssets);
    cp_property(bgAudioAssets);
    cp_property(musicID);
    cp_property(audioTimeClipInfo);
    cp_property(audioSoundFilterInfo);
    cp_property(assetRotationsInfo);
    cp_property(assetTransformInfo);
    cp_property(volumnInfo);
    cp_property(endingWaterMarkAudio);
    cp_property(bingoVideoKeys);
    cp_property(totalBGAudioDuration);
    cp_property(isDetectMode);
    //设置
    cp_property(notSupportCrossplat);
    cp_property(crossplatCompile);
    cp_property(crossplatInput);
    cp_property(enableVideoAnimation);
    cp_property(canvasConfigsMap);
    cp_property(canvasInfo);
    cp_property(canvasSize);
    cp_property(normalizeSize);
    cp_property(contentSource);
    cp_property(movieAnimationType);
    cp_property(effectFilterPathBlock);
    cp_property(effect_reverseAsset);
    cp_property(effect_operationTimeRange);
    cp_property(effect_timeMachineType);
    cp_property(effect_timeMachineBeginTime);
    cp_property(effect_newTimeMachineDuration);
    cp_property(extraMetaInfo);
    cp_property(extraInfo);
    cp_property(infoStickers);
    cp_property(infoStickerAddEdgeData);
#undef cp_property
}

@end

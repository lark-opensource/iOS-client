//
//  ACCEditVideoDataFactory.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/14.
//

#import "ACCEditVideoDataFactory.h"
#import "ACCVideoDataTranslator.h"
#import "ACCNLEEditVideoData.h"
#import "ACCConfigKeyDefines.h"
#import "NLEEditor_OC+Extension.h"

#import <NLEPlatform/NLEInterface.h>

@implementation ACCEditVideoDataFactory

+ (ACCEditVideoData *)videoDataWithCacheDirPath:(NSString *)cacheDirPath
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        ACCVEVideoData *veVideoData = [ACCVEVideoData videoDataWithDraftFolder:cacheDirPath];
        NLEInterface_OC *nle = [self p_tempNLEInterfaceWithDraftFolder:cacheDirPath];
        ACCNLEEditVideoData *nleVideoData = [ACCVideoDataTranslator translateWithVEModel:veVideoData nle:nle];
        nleVideoData.isTempVideoData = YES;
        return nleVideoData;
    } else {
        return [ACCVEVideoData videoDataWithVideoData:[HTSVideoData videoDataWithCacheDirPath:cacheDirPath] draftFolder:cacheDirPath];
    }
}

+ (ACCEditVideoData *)videoDataWithVideoAsset:(AVAsset *)asset cacheDirPath:(nonnull NSString *)cacheDirPath
{
    ACCEditVideoData *video = [ACCEditVideoDataFactory videoDataWithCacheDirPath:cacheDirPath];
    if (asset) {
        [video addVideoWithAsset:asset];
    }
    return video;
}

+ (ACCNLEEditVideoData *)tempNLEVideoDataWithDraftFolder:(NSString *)draftFolder
{
    NLEInterface_OC *nle = [self p_tempNLEInterfaceWithDraftFolder:draftFolder];
    NLEModel_OC *model = [[NLEModel_OC alloc] initWithCanvasSize:nle.canvasSize];
    ACCNLEEditVideoData *videoData = [[ACCNLEEditVideoData alloc] initWithNLEModel:model nle:nle];
    videoData.isTempVideoData = YES;
    [nle.editor setModel:model];
    return videoData;
}

+ (NLEInterface_OC *)p_tempNLEInterfaceWithDraftFolder:(NSString *)draftFolder
{
    NLEInterface_OC *nle = [[NLEInterface_OC alloc] init];
    
    NLEEditorConfiguration *configuration = [[NLEEditorConfiguration alloc] init];
    [nle CreateNLEEditorWithConfiguration:configuration];
    nle.draftFolder = draftFolder;
    return nle;
}

@end

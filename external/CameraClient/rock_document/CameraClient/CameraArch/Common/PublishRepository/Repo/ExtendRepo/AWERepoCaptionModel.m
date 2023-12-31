//
//  AWERepoCaptionModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/24.
//

#import "AWERepoCaptionModel.h"
#import <CreationKitArch/AWEStudioCaptionModel.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/ACCCaptionsNetServiceProtocol.h>
#import <CameraClient/ACCPublishNetServiceProtocol.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitInfra/NSString+ACCAdditions.h>
//#import <CameraClient/ACCFileUploadServiceBuilder.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

static NSInteger const kAWECaptionRequestCommitError = 2170;
static NSInteger const kAWECaptionRequestQueryError = 2171;
static NSInteger const kAWECaptionRequestFatalError = 2172;
static NSInteger const kAWECaptionRequestParamsFatalError = 5;

static NSInteger const kCaptionWordsPerLine = 20;
static NSInteger const kCaptionMaxLines = 1;

@interface AWEVideoPublishViewModel (AWERepoCaption) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoCaption)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoCaptionModel.class];
	return info;
}

- (AWERepoCaptionModel *)repoCaption
{
    AWERepoCaptionModel *captionModel = [self extensionModelOfClass:AWERepoCaptionModel.class];
    NSAssert(captionModel, @"extension model should not be nil");
    return captionModel;
}

@end

@interface AWERepoCaptionModel()<ACCRepositoryRequestParamsProtocol>

//@property (nonatomic, strong) id<ACCFileUploadServiceProtocol> videoUploadService;

@end

@implementation AWERepoCaptionModel
@synthesize repository;

- (id)copyWithZone:(NSZone *)zone
{
    AWERepoCaptionModel *model = [super copyWithZone:zone];
    model.captionInfo = self.captionInfo;
    model.captionPath = self.captionPath;
    return model;
}

- (void)resetAudioChangeFlag
{
    self.mixAudioInfoMd5 = self.currentMixAudioInfoMd5;
}

- (NSString *)captionWordsForCheck
{
    if (!self.captionInfo) {
        return @"";
    }
    
    NSMutableString *checkStr = [[NSMutableString alloc] init];
    for (AWEStudioCaptionModel *model in self.captionInfo.captions) {
        if (model.text) {
            [checkStr appendString:model.text];
        }
    }
    
    return [checkStr copy];
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel {
    NSMutableDictionary *params = @{}.mutableCopy;
    // 字幕
    if ([self.captionInfo.captions count] > 0) {
        params[@"is_subtitled"] = @(YES);
    }
    return params;
}

#pragma mark - Public


- (NSString *)currentMixAudioInfoMd5
{
#define ACC_PVM_MD5_APPEND_STRING(_var_) [str appendFormat:@""#_var_"\n%@\n\n", (_var_?: @" ")]
    
#define ACC_PVM_MD5_APPEND_AVASSET_ARRAY_STRING(_var_) \
ACC_PVM_MD5_APPEND_STRING(@#_var_); \
[_var_ enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) { \
    if ([obj isKindOfClass:AVURLAsset.class]) { \
        ACC_PVM_MD5_APPEND_STRING([(AVURLAsset *)obj URL].description); \
    } else { \
        ACC_PVM_MD5_APPEND_STRING(obj.description); \
    } \
}];
    
    NSMutableString *str = [[NSMutableString alloc] init];
    ACCRepoReshootModel *resoot = [self.repository extensionModelOfClass:[ACCRepoReshootModel class]];
    ACC_PVM_MD5_APPEND_STRING(resoot.recordVideoClipRange.description);
    
    ACCRepoMusicModel *music = [self.repository extensionModelOfClass:[ACCRepoMusicModel class]];
    ACC_PVM_MD5_APPEND_STRING(@"self.bgmAsset");
    if ([music.bgmAsset isKindOfClass:AVURLAsset.class]) {
        ACC_PVM_MD5_APPEND_STRING([(AVURLAsset *)(music.bgmAsset) URL].description);
    } else {
        ACC_PVM_MD5_APPEND_STRING(music.bgmAsset.description);
    }
    
    ACC_PVM_MD5_APPEND_STRING(music.bgmClipRange.description);
    ACC_PVM_MD5_APPEND_STRING(@(music.voiceVolume).stringValue);
    ACC_PVM_MD5_APPEND_STRING(@(music.musicVolume).stringValue);
    
    AWERepoVideoInfoModel *video = [self.repository extensionModelOfClass:[AWERepoVideoInfoModel class]];
    // Video
    ACC_PVM_MD5_APPEND_AVASSET_ARRAY_STRING(video.video.audioAssets);
    if (video.video.audioAssets.firstObject) {
        ACC_PVM_MD5_APPEND_STRING([video.video.audioTimeClipInfo[video.video.audioAssets.firstObject] description]);
    }
    
    return [str acc_md5String];
}

- (void)feedbackCaptionWithAwemeId:(NSString *)awemeId
{
    if (ACC_isEmptyString(awemeId) || ACC_isEmptyArray(self.captions) || ACC_isEmptyString(self.taskId)) {
        return;
    }
    NSMutableArray *utterances = [NSMutableArray array];
    [self.captions enumerateObjectsUsingBlock:^(AWEStudioCaptionModel * _Nonnull oneCaption, NSUInteger idx, BOOL * _Nonnull stop) {
        [utterances addObjectsFromArray:oneCaption.words];
    }];
    utterances = [[utterances.copy acc_mapObjectsUsingBlock:^NSDictionary  * _Nonnull(AWEStudioCaptionModel * _Nonnull obj, NSUInteger idex) {
        NSError *jsonError = nil;
        NSDictionary *wordJson = [MTLJSONAdapter JSONDictionaryFromModel:obj error:&jsonError];
        if (jsonError) {
            AWELogToolError2(@"caption", AWELogToolTagEdit, @"word to json error: %@", jsonError);
        }
        return wordJson;
    }] mutableCopy];
    
    let captionsNetService = IESAutoInline(ACCBaseServiceProvider(), ACCCaptionsNetServiceProtocol);
    [captionsNetService feedbackCaptionWithAwemeId:awemeId
                                            taskID:self.taskId
                                               vid:self.vid
                                        utterances:utterances];
}

//- (void)queryCaptionsWithUrl:(NSURL *)audioUrl completion:(AudioQueryCompletion)completion
//{
//    self.vid = @"";
//    if (self.taskId.length == 0) {
//        self.currentStatus = AWEStudioCaptionQueryStatusCommit;
//    }
//
//    if (self.tosKey.length == 0) {
//        self.currentStatus = AWEStudioCaptionQueryStatusUpload;
//    }
//
//    switch (self.currentStatus) {
//        case AWEStudioCaptionQueryStatusUpload: {
//            [self uploadAudioWithUrl:audioUrl completion:completion];
//        }
//            break;
//
//
//        case AWEStudioCaptionQueryStatusCommit: {
//            [self commitAudioWithMaterialId:self.tosKey completion:completion];
//        }
//            break;
//
//        case AWEStudioCaptionQueryStatusQuery: {
//            [self queryCaptionWithTaskId:self.taskId completion:completion];
//        }
//            break;
//    }
//}

// 上传字幕
//- (void)uploadAudioWithUrl:(NSURL *)audioUrl completion:(AudioQueryCompletion)completion
//{
//    self.currentStatus = AWEStudioCaptionQueryStatusCommit;
//    if (self.tosKey) {
//        [self commitAudioWithMaterialId:self.tosKey completion:completion];
//    } else {
//         @weakify(self);
//        [IESAutoInline(ACCBaseServiceProvider(), ACCPublishNetServiceProtocol) requestUploadParametersWithCompletion:^(AWEResourceUploadParametersResponseModel *response, NSError *error) {
//            @strongify(self);
//            if (!error && audioUrl) {
//                // 获取字幕使用字幕的tos
//                if (response.videoUploadParameters.captionAppKey.length > 0 && response.videoUploadParameters.captionAuthorization.length > 0 &&
//                    response.videoUploadParameters.captionAuthorization2) {
//                    response.videoUploadParameters.appKey = response.videoUploadParameters.captionAppKey;
//                    response.videoUploadParameters.authorization = response.videoUploadParameters.captionAuthorization;
//                    response.videoUploadParameters.authorization2 = response.videoUploadParameters.captionAuthorization2;
//                }
//
//                ACCFileUploadServiceBuilder *uploadBuilder = [[ACCFileUploadServiceBuilder alloc] init];
//                self.videoUploadService = [uploadBuilder createUploadServiceWithParams:response filePath:[audioUrl path] fileType:ACCUploadFileTypeAudio];
//                NSProgress *progress = nil;
//
//                [self.videoUploadService uploadFileWithProgress:&progress completion:^(ACCFileUploadResponseInfoModel *uploadInfoModel, NSError * _Nullable error) {
//                    @strongify(self);
//                    self.tosKey = uploadInfoModel.tosKey;
//                    self.videoUploadService = nil;
//                    if (uploadInfoModel.tosKey) {
//                        [self finishWithError:nil];
//                        [self commitAudioWithMaterialId:uploadInfoModel.tosKey completion:completion];
//                    } else {
//                        [self finishWithError:error];
//                        ACCBLOCK_INVOKE(completion, nil, error ?: [NSError new]);
//                    }
//                }];
//            } else {
//                [self finishWithError:error];
//                ACCBLOCK_INVOKE(completion, nil, error ?: [NSError new]);
//            }
//        }];
//    }
//}

// 提交字幕
//- (void)commitAudioWithMaterialId:(NSString *)materialId completion:(AudioQueryCompletion)completion
//{
//    self.currentStatus = AWEStudioCaptionQueryStatusCommit;
//    let captionsNetService = IESAutoInline(ACCBaseServiceProvider(), ACCCaptionsNetServiceProtocol);
//    [captionsNetService commitAudioWithMaterialId:materialId maxLines:@(kCaptionMaxLines) wordsPerLine:@(kCaptionWordsPerLine) completion:^(AWEStudioCaptionCommitModel * _Nullable model, NSError * _Nullable error) {
//            if (error) {
//               [self finishWithError:error];
//               ACCBLOCK_INVOKE(completion, nil, error);
//            } else {
//               self.taskId = model.videoCaption.captionId;
//               [self finishWithError:nil];
//               [self queryCaptionWithTaskId:self.taskId completion:completion];
//            }
//    }];
//}

// 查询字幕
//- (void)queryCaptionWithTaskId:(NSString *)taskId completion:(AudioQueryCompletion)completion
//{
//    self.currentStatus = AWEStudioCaptionQueryStatusQuery;
//    let captionsNetService = IESAutoInline(ACCBaseServiceProvider(), ACCCaptionsNetServiceProtocol);
//    [captionsNetService queryCaptionWithTaskId:taskId completion:^(AWEStudioCaptionCommitModel * _Nullable model, NSError * _Nullable error) {
//        if (self.deleted) {
//           return;
//        }
//
//        if (error) {
//           ACCBLOCK_INVOKE(completion, nil, error);
//        } else {
//           ACCBLOCK_INVOKE(completion, model.videoCaption.captions, nil);
//        }
//        [self finishWithError:error];
//    }];
//}

//- (void)finishWithError:(NSError *)error
//{
//    NSString *tag = [NSString stringWithFormat:@"caption.status(%@)",@(self.currentStatus)];
//    if (!error) {
//        AWELogToolInfo2(tag,AWELogToolTagEdit,@"tosKey: %@, taskId: %@", self.tosKey, self.taskId);
//    } else {
//        AWELogToolError2(tag,AWELogToolTagEdit,@"tosKey: %@, taskId: %@, error: %@", self.tosKey, self.taskId, error);
//    }
//
//    [self resetQueryStatusWithErrorCode:error.code];
//}

//- (void)resetQueryStatusWithErrorCode:(NSInteger)code
//{
//    if (kAWECaptionRequestCommitError == code) {
//        self.currentStatus = AWEStudioCaptionQueryStatusCommit;
//    }
//
//    if (kAWECaptionRequestQueryError == code) {
//        self.currentStatus = AWEStudioCaptionQueryStatusQuery;
//    }
//
//    if (kAWECaptionRequestFatalError == code) {
//        self.currentStatus = AWEStudioCaptionQueryStatusUpload;
//    }
//
//    if (kAWECaptionRequestParamsFatalError == code) {
//        self.currentStatus = AWEStudioCaptionQueryStatusUpload;
//    }
//}

@end

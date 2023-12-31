//
//  AWEAudioExport.m
//  AWEStudio
//
//  Created by liubing on 2018/7/6.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWERepoVoiceChangerModel.h"
#import "AWERepoDraftModel.h"
#import "AWEAudioExport.h"
#import <TTVideoEditor/VEAudioResampler.h>
#import <TTVideoEditor/HTSAudioExport.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CameraClient/ACCPublishNetServiceProtocol.h>
#import <CameraClient/ACCAudioNetServiceProtocol.h>
#import <CameraClient/ACCFileUploadServiceBuilder.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import "ACCPublishAudioAuditManager.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CameraClient/ACCAudioExport.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "ACCEditVideoDataDowngrading.h"
#import "ACCRepoKaraokeModelProtocol.h"
#import "ACCConfigKeyDefines.h"

static NSMutableArray *array = nil;

@interface AWEAudioExport ()

@property (nonatomic, strong) VEAudioResampler *audioResampler;
@property (nonatomic, strong) ACCAudioExport *audioExport;
@property (nonatomic, strong) ACCEditVideoData *videoData;
@property (nonatomic, strong) id<ACCFileUploadServiceProtocol> uploadService;
@property (nonatomic, strong) AWEResourceUploadParametersResponseModel *uploadParameters;
@property (nonatomic, strong) NSString *awemeId;
@property (nonatomic, strong) NSString *materialId;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;

@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) AWEAudioAuditStage stage;
@property (nonatomic, strong) NSDictionary *response;
@property (nonatomic, assign) BOOL success;
@property (nonatomic, copy) dispatch_block_t completion;
@property (nonatomic, assign) BOOL isOriSound;//使用了变声音效后导出原声

@property (nonatomic, strong) ACCPublishAudioAuditTask *auditTask;

@end

@implementation AWEAudioExport

+ (void)extractAudioAndUploadFromVideoData:(ACCEditVideoData * _Nullable)videoData
                              publishModel:(AWEVideoPublishViewModel * _Nullable)publishModel
                                isOriSound:(BOOL)enable
                               awemeItemId:(NSString * _Nullable)awemeId
                          uploadParameters:(AWEResourceUploadParametersResponseModel * _Nullable)uploadParameters
                                completion:(dispatch_block_t _Nullable)completion
{
    
    if (!array) {
        array = @[].mutableCopy;
    }
    
    if (videoData.videoAssets.count == 0) {
        ACCBLOCK_INVOKE(completion);
        return;
    }
    
    AWEAudioExport *export = [[AWEAudioExport alloc] init];
    export.isOriSound = enable;
    export.videoData = [videoData copy];
    export.awemeId = awemeId;
    export.uploadParameters = uploadParameters;
    export.completion = completion;
    export.publishModel = publishModel;
    [array addObject:export];
    [export start];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _audioExport = [[ACCAudioExport alloc] init];
        _audioResampler = [[VEAudioResampler alloc] init];
    }
    return self;
}

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel * _Nullable)publishModel
{
    self = [super init];
    if (self) {
        _audioExport = [[ACCAudioExport alloc] init];
        _audioResampler = [[VEAudioResampler alloc] init];
        _videoData = publishModel.repoVideoInfo.video;
        _publishModel = publishModel;
        _isOriSound = publishModel.repoVoiceChanger.voiceEffectType != ACCVoiceEffectTypeNone;
    }
    
    return self;
}

// 这部分是视频自动字幕抽音的逻辑
- (void)exportAudioWithCompletion:(ExportCompletion _Nullable)completion
{
    void (^processExportBlock)(NSURL *_Nonnull, NSError *_Nonnull, AVAssetExportSessionStatus) = ^(NSURL * _Nonnull url, NSError * _Nonnull error, AVAssetExportSessionStatus status) {
        if (!url || error) {
            ACCBLOCK_INVOKE(completion, url, error, status);
        } else {
            NSString *draftFolder = [AWEDraftUtils generateDraftFolderFromTaskId:self.publishModel.repoDraft.taskID];
            NSString *path = [draftFolder stringByAppendingPathComponent:[url lastPathComponent]];
            NSError *copyError;
            
            [[NSFileManager defaultManager] moveItemAtPath:url.path toPath:path error:&copyError];
            if (copyError) {
                ACCBLOCK_INVOKE(completion, url, error, status);
            } else {
                ACCBLOCK_INVOKE(completion, [NSURL URLWithString:path], error, status);
            }
        }
    };
    
    // lv音频框架需要自己处理音乐和变声移除的操作，自动字幕的话需要视频原声+配音+配乐去做识别
    ACCEditVideoData *newVideoData = acc_videodata_take_ve(self.videoData).copy;
    newVideoData = [self removePitchFilterAndBGMForVideoData:newVideoData removeBGM:NO removeTextRead:YES];
    @weakify(self);
    [self.audioExport exportAllAudioSoundInVideoData:newVideoData completion:^(NSURL * _Nullable url, NSError * _Nullable error) {
        @strongify(self);
        // 新接口无status返回，手动设定。看了下AutoCaptionsViewController中，并没有使用到status，但是还是保持和老的设计统一。
        AVAssetExportSessionStatus status = AVAssetExportSessionStatusCompleted;
        if (!url || error) {
            status = AVAssetExportSessionStatusFailed;
            ACCBLOCK_INVOKE(processExportBlock, url, error, status);
        } else {
            int samplerate = (int)ACCConfigInt(kConfigInt_autocaption_samplerate_config);
            int bitrate = (int)ACCConfigInt(kConfigInt_autocaption_bitrate_config);
            [self.audioResampler resampleAudioWithURL:url resampleRate:samplerate*1000 bitRate:bitrate*1000 completion:^(NSURL *url, NSError *error) {
                // Resampler failed
                AVAssetExportSessionStatus status = AVAssetExportSessionStatusCompleted;
                if (!url || error) {
                    status = AVAssetExportSessionStatusFailed;
                }
                ACCBLOCK_INVOKE(processExportBlock, url, error, status);
            }];
        }
    }];
}

- (void)didFinish
{
    ACCBLOCK_INVOKE(self.completion);
    self.completion = nil;
    
    if (![array containsObject:self]) {
        return;
    }
    
    NSMutableDictionary *logData = @{@"materialId" :[self materialId]?:@"",
                                     @"aweme_id"    :self.awemeId?:@"",
                                     @"stage" : @(self.stage),
                                     @"backup_upload" : @(0)
                                     }.mutableCopy;
    
    if (!self.success) {
        [logData addEntriesFromDictionary:@{@"errorCode"    : @(self.error.code).description,
                                            @"errorDesc"    : self.error.localizedDescription?:@"null",
                                            @"errorDomain"  : self.error.domain?:@"null",
                                            @"response"     : self.response.description?:@"null",
                                            @"url"          : self.url.absoluteString?:@"null",
                                            }];
    }

    [ACCMonitor() trackService:@"aweme_publish_upload_audio_rate" status:self.success?0:1 extra:logData.copy];
    
    [logData addEntriesFromDictionary:@{@"success" : @(self.success ? 0 : 1)}];
    [ACCTracker() trackEvent:@"upload_original_audio_end" params:logData.copy];
    
    [array removeObject:self];
}

// 这部分是视频上传音频送审的逻辑
- (void)start
{
    [ACCTracker() trackEvent:@"upload_original_audio_start" params:[self commontParams]];
    
    self.stage = AWEAudioAuditStageExtract;
    // 新（LV）音频框架的抽帧处理
    ACCEditVideoData *newVideoData = acc_videodata_take_ve(self.videoData).copy;
    
    newVideoData = [self removePitchFilterAndBGMForVideoData:newVideoData removeBGM:YES removeTextRead:NO];

    // 如果当前是duet模式，需要移除掉duet的原声，因为duet的原声肯定已经被审核过一次了
    if (self.publishModel.repoDuet.isDuet) {
        __block AVAsset *duetOriginalAsset = nil;
        [newVideoData.audioAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           if ([obj isKindOfClass:[AVURLAsset class]]) {
               if ([((AVURLAsset *)obj).URL.path.lastPathComponent hasSuffix:@".mp4"]) {
                   duetOriginalAsset = obj;
                   *stop = YES;
               }
           }
        }];
        [newVideoData removeAudioAsset:duetOriginalAsset];
    }
    
    if (self.publishModel.repoContext.videoType == AWEVideoTypeKaraoke) {
        id<ACCRepoKaraokeModelProtocol> repoModel = [self.publishModel extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
        NSString *accompanyPath = repoModel.accompanyTrack.localPath;
        NSString *originalSongPath = repoModel.originalSongTrack.localPath;
        __block AVAsset *accompanyAsset = nil;
        __block AVAsset *originalAsset = nil;
        [newVideoData.audioAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:AVURLAsset.class]) {
                NSString *lastComponent = [(AVURLAsset *)obj URL].lastPathComponent;
                if ([accompanyPath.lastPathComponent isEqualToString:lastComponent] && idx == repoModel.editModel.accompanyIndex) {
                    accompanyAsset = obj;
                }
                if ([originalSongPath.lastPathComponent isEqualToString:lastComponent] && idx == repoModel.editModel.originalSongIndex) {
                    originalAsset = obj;
                }
            }
        }];
        if (accompanyAsset) {
            [newVideoData removeAudioAsset:accompanyAsset];
        }
        if (originalAsset) {
            [newVideoData removeAudioAsset:originalAsset];
        }
    }

    // 抽音
    @weakify(self);
    [self.audioExport exportAllAudioSoundInVideoData:newVideoData completion:^(NSURL * _Nullable url, NSError * _Nullable error) {
        @strongify(self);
        [self p_hasExportAudioWithURL:url error:error];
    }];
}


/// 移除video中的变声效果以及背景音乐
/// @param newVideoData 传入的video
- (ACCEditVideoData *)removePitchFilterAndBGMForVideoData:(ACCEditVideoData *)newVideoData removeBGM:(BOOL)removeBGM removeTextRead:(BOOL)removeTextRead
{
    NSDictionary<AVAsset *, NSArray<IESMMAudioFilter *> *> *newAudioSoundFilterInfo = newVideoData.audioSoundFilterInfo.copy;
    // 1. 针对每个audioAssets应用的变声filter都予以移除
    [newAudioSoundFilterInfo enumerateKeysAndObjectsUsingBlock:^(AVAsset * _Nonnull key, NSArray<IESMMAudioFilter *> * _Nonnull obj, BOOL * _Nonnull stop) {
        NSArray<IESMMAudioFilter *> *audioFilters = obj.copy;
        [audioFilters enumerateObjectsUsingBlock:^(IESMMAudioFilter * _Nonnull innerObj, NSUInteger innerIdx, BOOL * _Nonnull innerStop) {
            // 变声filter
            if (innerObj.type == IESAudioFilterTypePitch) {
                [newVideoData removeSoundFilterWithFilter:innerObj asset:key];
            }
            if (innerObj.type == IESAudioFilterTypeDSP) {
                [newVideoData removeSoundFilterWithFilter:innerObj asset:key];
            }
        }];
    }];

    // 2. 针对每个videoAssets应用的变声和混响filter都予以移除
    NSMutableDictionary<AVAsset *, NSMutableArray<IESMMAudioFilter *> *> *newVideoSoundFilterInfo = newVideoData.videoSoundFilterInfo.copy;
    [newVideoSoundFilterInfo enumerateKeysAndObjectsUsingBlock:^(AVAsset * _Nonnull key, NSMutableArray<IESMMAudioFilter *> * _Nonnull obj, BOOL * _Nonnull stop) {
        NSArray<IESMMAudioFilter *> *audioFilters = obj.copy;
        [audioFilters enumerateObjectsUsingBlock:^(IESMMAudioFilter * _Nonnull innerObj, NSUInteger innerIdx, BOOL * _Nonnull innerStop) {
            // 变声filter
            if (innerObj.type == IESAudioFilterTypePitch) {
                [newVideoData removeVideoSoundFilterWithFilter:innerObj asset:key];
            }
            if (innerObj.type == IESAudioFilterTypeDSP) {
                [newVideoData removeVideoSoundFilterWithFilter:innerObj asset:key];
            }
        }];
    }];

    // 3. 移除背景音乐，需要找到path相同的对应实例
    if (removeBGM) {
        __block AVAsset *bgmAsset = self.publishModel.repoMusic.bgmAsset;
        [newVideoData.audioAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
          if ([obj isKindOfClass:[AVURLAsset class]] &&
              [bgmAsset isKindOfClass:[AVURLAsset class]]) {
              if ([((AVURLAsset *)obj).URL.path isEqualToString:((AVURLAsset *)bgmAsset).URL.path]) {
                  bgmAsset = obj;
                  *stop = YES;
              }
          }
        }];
        [newVideoData removeAudioAsset:bgmAsset];
    }
    
    // 4. remove Text Readings
    if(removeTextRead) {
        NSMutableArray<AVAsset *> *assetsToRemoved = @[].mutableCopy;
        [newVideoData.audioAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[AVURLAsset class]]) {
                BOOL isTextReadAsset = [((AVURLAsset *)obj).URL.path.lastPathComponent hasSuffix:@"readtext.mp3"];
                if (isTextReadAsset) {
                    [assetsToRemoved addObject:obj];
                    [newVideoData removeAudioTimeClipInfoWithAsset:obj];
                }
            }
        }];
        [newVideoData removeAudioWithAssets:assetsToRemoved];
    }

    return newVideoData;
}

- (void)uploadAudioWithUrl:(NSURL *)audioUrl
{
    self.stage = AWEAudioAuditStageUpload;
    ACCFileUploadServiceBuilder *uploadBuilder= [[ACCFileUploadServiceBuilder alloc] init];
    self.uploadService = [uploadBuilder createUploadServiceWithParams:self.uploadParameters filePath:[audioUrl path] fileType:ACCUploadFileTypeAudio];
    NSProgress *progress = nil;
    
    @weakify(self);
    [self.uploadService uploadFileWithProgress:&progress completion:^(ACCFileUploadResponseInfoModel *uploadInfoModel, NSError *error) {
        @strongify(self);
        self.materialId = uploadInfoModel.materialId;
        self.error = error;
        
        if (uploadInfoModel.materialId) {
            NSMutableDictionary *parameter = @{}.mutableCopy;
            parameter[@"aweme_id"] = self.awemeId;
            parameter[@"audiotrack_uri"] = uploadInfoModel.materialId;
            parameter[@"aweme_draft_id"] = self.publishModel.repoDraft.adminDraftId;
            let audioNetService = IESAutoInline(ACCBaseServiceProvider(), ACCAudioNetServiceProtocol);
            self.stage = AWEAudioAuditStageTrack;
            [audioNetService updateAudioTrackWithId:self.awemeId audiotrackUri:uploadInfoModel.materialId completion:^(id  _Nullable model, NSError * _Nullable error) {
                @strongify(self);
                self.error = error;
                if ([model isKindOfClass:[NSDictionary class]]) {
                  self.response = model;
                  if (model[@"status_code"] && [model[@"status_code"] integerValue] == 0) {
                      self.success = YES;
                      [ACCPublishAudioAuditManager.sharedInstance removeAudioAuditTask:self.auditTask];
                  }
                }
                if (error) {
                    AWELogToolError2(@"audioAudit", AWELogToolTagPublish, @"track awemeid error: %@", error);
                }
                [self didFinish];
            }];
        } else {
            AWELogToolError2(@"audioAudit", AWELogToolTagPublish, @"upload audio error: %@", error);
            [self didFinish];
        }
    }];
}

#pragma mark - Track

- (NSDictionary *)commontParams
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:@(self.publishModel.repoContext.feedType) forKey:@"aweme_type"];
    [params setObject:self.publishModel.repoDraft.taskID ?: @"" forKey:@"task_id"];
    NSString *contentType = ACCDynamicCast([self.publishModel.repoTrack.referExtra acc_objectForKey:@"content_type"], NSString);
    if (contentType) {
        [params setObject:contentType forKey:@"content_type"];
    }
    
    return [params copy];
}

#pragma mark -

- (void)p_hasExportAudioWithURL:(NSURL *)url error:(NSError *)error
{
    self.url = url;
    self.error = error;
    
    if (error || !url) {
        AWELogToolError2(@"audioAudit", AWELogToolTagPublish, @"extra audio error: %@", error);
        [self didFinish];
    } else {
        // add to mgr for retry next time if needed.
        self.auditTask = [ACCPublishAudioAuditTask new];
        self.auditTask.createTimeInterval = [[NSDate new] timeIntervalSince1970];
        self.auditTask.awemeId = self.awemeId;
        self.auditTask.audioFilePath = url.path;
        self.auditTask.useTmpPath = YES;
        [ACCPublishAudioAuditManager.sharedInstance addAudioAuditTask:self.auditTask];
        
        self.stage = AWEAudioAuditStageRequestUploadParams;
        if (self.uploadParameters.videoUploadParameters) {
            [self uploadAudioWithUrl:url];
        } else {
            [IESAutoInline(ACCBaseServiceProvider(), ACCPublishNetServiceProtocol) requestUploadParametersWithCompletion:^(AWEResourceUploadParametersResponseModel *parameters, NSError *error) {
                if (parameters.videoUploadParameters && !error) {
                    self.uploadParameters = parameters;
                    [self uploadAudioWithUrl:url];
                } else {
                    self.error = error;
                    [self didFinish];
                }
            }];
        }
    }
}


@end


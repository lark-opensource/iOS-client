//
//  ACCEditCompileSession.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/14.
//

#import "ACCEditCompileSession.h"
#import <TTVideoEditor/VECompileSession.h>
#import <TTVideoEditor/VEEffectProcess.h>
#import <TTVideoEditor/VEEffectProcess+VideoData.h>
#import <TTVideoEditor/VECompileTaskManagerSession.h>

#import "ACCEditVideoDataDowngrading.h"
#import "ACCVEVideoData.h"
#import "ACCVideoDataTranslator.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import <KVOController/KVOController.h>
#import <NLEPlatform/NLEExportSession.h>
#import "AWERepoVideoInfoModel.h"

static NSString * const kACCVETransStatusKey = @"transStatus";

@interface ACCEditCompileSession()

@property (nonatomic, strong) VECompileSession *veCompileSession;
@property (nonatomic, strong) NLEExportSession *nleExportSession;
@property (nonatomic, strong) ACCEditVideoData *videoData;

@end
@implementation ACCEditCompileSession

+ (void)checkCompileSessionReady:(void (^)(void))completion
{
    VECompileTaskManagerSession *compiler = VECompileTaskManagerSession.sharedInstance;
    if ([compiler respondsToSelector:NSSelectorFromString(kACCVETransStatusKey)]) {
        id value = [compiler valueForKey:kACCVETransStatusKey];
        if ([value isKindOfClass:NSNumber.class]) {
            IESMMTransStatus status = [value integerValue];
            if (status == IESMMTransStatusProcess) { // incorrect status
                // observe first
                __block NSObject *blockObject = [NSObject new];
                [blockObject.KVOController observe:compiler keyPath:kACCVETransStatusKey options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
                    
                    id value = change[NSKeyValueChangeNewKey];
                    if ([@(IESMMTransStatusIdle) isEqualToNumber:value]) {
                        // idle is correct trans status
                        AWELogToolInfo(AWELogToolTagPublish|AWELogToolTagCompose,
                        @"ve compiler status reset successful.");
                    } else {
                        AWELogToolError(AWELogToolTagPublish|AWELogToolTagCompose,
                        @"ve compiler status reset failed. current status: %@", value);
                    }
                    // 先取消observe，以免completion执行的时候会再次回调
                    [blockObject.KVOController unobserve:compiler keyPath:kACCVETransStatusKey];
                    blockObject = nil;
                    
                    !completion ?: completion();
                }];
                
                // cancelTranscode second
                AWELogToolWarn(AWELogToolTagPublish|AWELogToolTagCompose,
                               @"ve compiler status error."
                               @"we manually cancel compile process");
                [[VECompileTaskManagerSession sharedInstance] cancelTranscode];

                return;
            }
        }
    }
    !completion ?: completion();
}



+ (id)transcodeWithVideoData:(ACCEditVideoData *)videoData
                        size:(CGSize)targetSize
                     bitrate:(int)bitrate
             completionBlock:(void (^)(IESMMTranscodeRes * _Nullable))completionBlock
{
    videoData.canvasSize = targetSize;
    videoData.transParam.videoSize = targetSize;
    
    videoData.transParam.writerType = IESMMWriterTypeImportCompile;
    videoData.transParam.useUserBitrate = YES;
    videoData.transParam.bitrate = bitrate;
    
    IESMMTransProcessData *config = [[IESMMTransProcessData alloc] init];
    __block ACCEditCompileSession *transcoder = [[ACCEditCompileSession alloc] initWithVideoData:videoData
                                                                                          config:config
                                                                                      effectUnit:nil];
    [transcoder transcodeWithCompleteBlock:^(IESMMTranscodeRes * _Nullable result) {
        !completionBlock ?: completionBlock(result);
        transcoder = nil;
    }];
    return transcoder;
}

+ (void)transcodeWithVideoData:(ACCEditVideoData *)videoData
               completionBlock:(void (^)(IESMMTranscodeRes * _Nullable))completionBlock
{
    IESMMTransProcessData *config = [[IESMMTransProcessData alloc] init];

    id<IVEEffectProcess> effect = [self effectProcessWithVideoData:videoData];
    __block ACCEditCompileSession *transcoder = [[ACCEditCompileSession alloc] initWithVideoData:videoData
                                                                                          config:config
                                                                                      effectUnit:effect];

    [transcoder transcodeWithCompleteBlock:^(IESMMTranscodeRes * _Nullable result) {
        !completionBlock ?: completionBlock(result);
        transcoder = nil;
    }];
}

+ (void)transWithVideoData:(ACCVEVideoData *)videoData
               transConfig:(IESMMTransProcessData *)transConfig
              videoProcess:(id<IVEEffectProcess>)videoProcess
             completeBlock:(nonnull void (^)(IESMMTranscodeRes * _Nullable))completeBlock
{
    // 使用 VECompileTaskManagerSession 实现的转码目前不能使用 NLE 实现
    NSAssert([videoData isKindOfClass:[ACCVEVideoData class]], @"transWithVideoData must use ve data");
    [[VECompileTaskManagerSession sharedInstance] transWithVideoData:videoData.videoData
                                                         transConfig:transConfig
                                                        videoProcess:videoProcess
                                                       completeBlock:completeBlock];
}

+ (id<IVEEffectProcess>)effectProcessWithVideoData:(ACCEditVideoData *)videoData
{
    return acc_videodata_downgrading_ret(videoData, ^id(HTSVideoData *videoData) {
        return [VEEffectProcess effectProcessWithVideoData:videoData];
    }, ^id (ACCNLEEditVideoData *videoData) {
        return [videoData.nle.exportSession effectProcess];
    });
}

+ (ACCVEVideoData *)getMVExportData:(id<IVEEffectProcess>)effectProcess publishModel:(AWEVideoPublishViewModel *)publishModel
{
    return [ACCVEVideoData videoDataWithVideoData:[effectProcess getMVExportData]
                                      draftFolder:publishModel.repoVideoInfo.video.draftFolder];
}

+ (void)setProgressBlock:(void (^ _Nullable)(CGFloat))progressBlock
{
    [VECompileTaskManagerSession sharedInstance].progressBlock = progressBlock;
}

+ (void (^ _Nullable)(CGFloat))progressBlock
{
    return [VECompileTaskManagerSession sharedInstance].progressBlock;
}

+ (void)setEncodeDataCallback:(void (^)(NSData * _Nonnull, int64_t, int, BOOL))encodeDataCallback
{
    [VECompileTaskManagerSession sharedInstance].encodeDataCB = encodeDataCallback;
}

+ (void (^)(NSData * _Nonnull, int64_t, int, BOOL))encodeDataCallback
{
    return [VECompileTaskManagerSession sharedInstance].encodeDataCB;
}

+ (void)pause
{
    [[VECompileTaskManagerSession sharedInstance] pause];
}

+ (void)resume
{
    [[VECompileTaskManagerSession sharedInstance] resume];
}

+ (void)enableDynamicSpeed:(BOOL)constrainedMode
{
    [[VECompileTaskManagerSession sharedInstance] enableDynamicSpeed:constrainedMode];
}

+ (void)postTrack
{
    [[VECompileTaskManagerSession sharedInstance] postTrack];
}

+ (void)cancelTranscode
{
    [[VECompileTaskManagerSession sharedInstance] cancelTranscode];
}

- (instancetype)initWithVideoData:(ACCEditVideoData *)videoData
                           config:(IESMMTransProcessData *)config
{
    self = [super init];
    if (self) {
        // 需要持有 videoData，否则 videoData 可能会被释放
        _videoData = videoData;
        acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
            self.veCompileSession = [[VECompileSession alloc] initWithVideoData:videoData
                                                                         config:config
                                                                     effectUnit:nil];
        }, ^(ACCNLEEditVideoData *videoData) {
            [videoData.nle.editor setModel:videoData.nleModel];
            self.nleExportSession = videoData.nle.exportSession;
            [self.nleExportSession setupTranscodeConfig:config effectUnit:nil];
        });
    }
    return self;
}

- (instancetype)initWithVideoData:(ACCEditVideoData *)videoData
                           config:(IESMMTransProcessData *)config
                       effectUnit:(id<IVEEffectProcess>)effectUnit
{
    self = [super init];
    if (self) {
        acc_videodata_downgrading(videoData, ^(HTSVideoData *videoData) {
            self.veCompileSession = [[VECompileSession alloc] initWithVideoData:videoData
                                                                         config:config
                                                                     effectUnit:effectUnit];
        }, ^(ACCNLEEditVideoData *videoData) {
            [videoData.nle.editor setModel:videoData.nleModel];
            self.nleExportSession = videoData.nle.exportSession;
            [self.nleExportSession setupTranscodeConfig:config effectUnit:effectUnit];
        });
    }
    return self;
}

- (void)setProgressBlock:(void (^)(CGFloat))progressBlock
{
    if (self.nleExportSession) {
        self.nleExportSession.progressBlock = progressBlock;
    } else {
        self.veCompileSession.progressBlock = progressBlock;
    }
}

- (void (^)(CGFloat))progressBlock
{
    if (self.nleExportSession) {
        return self.nleExportSession.progressBlock;
    } else {
        return self.veCompileSession.progressBlock;
    }
}

- (void)transcodeWithCompleteBlock:(void (^)(IESMMTranscodeRes * _Nullable))completeBlock
{
    if (self.nleExportSession) {
        [self.nleExportSession transcodeWithCompleteBlock:completeBlock];
    } else {
        [self.veCompileSession transcodeWithCompleteBlock:completeBlock];
    }
}

- (void)cancel:(void (^)(void))completion
{
    if (self.nleExportSession) {
        [self.nleExportSession cancel:completion];
    } else {
        [self.veCompileSession cancel:completion];
    }
}

- (void)cancelTranscode
{
    if (self.nleExportSession) {
        [self.nleExportSession cancelTranscode];
    } else {
        [self.veCompileSession cancelTranscode];
    }
}

+ (BOOL)isPreUploadable:(ACCVEVideoData *)videoData transConfig:(IESMMTransProcessData *)transConfig videoProcess:(id<IVEEffectProcess>)videoProcess {
    // 使用 VECompileTaskManagerSession 实现的转码目前不能使用 NLE 实现
    NSAssert([videoData isKindOfClass:[ACCVEVideoData class]], @"transWithVideoData must use ve data"); 
    return [[VECompileTaskManagerSession sharedInstance] isPreUploadable:videoData.videoData transConfig:transConfig videoProcess:videoProcess];
}

@end

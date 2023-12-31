//
//  BDUGVideoImageShare.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/16.
//

static NSString *const kBDUGShareVideoResource = @"kBDUGShareVideoResource";

#define BDUG_SHARE_VIDEO_LOCAL_PATH_FOLDER [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingString:@"/"] stringByAppendingString:kBDUGShareVideoResource]

//目前写死的后缀 .mp4
#define BDUG_SHARE_VIDEO_LOCAL_PATH(fileName) [[[BDUG_SHARE_VIDEO_LOCAL_PATH_FOLDER stringByAppendingString:@"/"] stringByAppendingString:fileName] stringByAppendingString:@".mp4"]

#import "BDUGVideoImageShare.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "BDUGFileDownloader.h"

#import <Photos/Photos.h>
#import "BDUGVideoImageShareModel.h"
#import "BDUGVideoImageShareDialogManager.h"
#import <BDWebImage/BDWebImageManager.h>
#import "BDUGShareEvent.h"

@implementation BDUGVideoImageShareInfo

@end

@interface BDUGVideoImageShare ()

@property(nonatomic, strong) BDUGVideoImageShareInfo *shareInfo;

@end

BOOL shareProcessShut;

@implementation BDUGVideoImageShare

#pragma mark - life cycle

+ (void)shareVideoWithInfo:(BDUGVideoImageShareInfo *)info {
    shareProcessShut = NO;
    BDUGVideoShareBlock continueBlock = ^() {
        BDUGVideoImageShare *share = [[BDUGVideoImageShare alloc] initWithVideoInfo:info];
        [share checkAuthorization];
    };
    if (info.needPreviewDialog) {
        [BDUGVideoImageShareDialogManager invokeVideoPreviewDialogBlock:info continueBlock:continueBlock];
    } else {
        continueBlock();
    }
}

+ (void)cancelShareProcess
{
    shareProcessShut = YES;
    [BDUGVideoImageShareDialogManager invokeDownloadCompletion];
    [[BDUGFileDownloader sharedInstance] cancelAllTask];
}

- (instancetype)initWithVideoInfo:(BDUGVideoImageShareInfo *)info{
    if (self = [super init]) {
        _shareInfo = info;
    }
    return self;
}

#pragma mark - data process

- (void)checkAuthorization
{
    if (self.shareInfo.shareStrategy == BDUGVideoImageShareStrategyResponseSaveSandbox ||
        self.shareInfo.shareStrategy == BDUGVideoImageShareStrategyResponseMemory) {
        //只保存沙盒，直接handle resource
        [self handleShareResource];
    } else {
        //otherwise， request authorization
        PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
        [BDUGShareEventManager event:kShareAuthorizeRequest params:@{
            @"had_authorize" : (authStatus == PHAuthorizationStatusAuthorized ? @(1) : @(0)),
            @"panel_type" : (self.shareInfo.panelType ?: @""),
            @"panel_id" : (self.shareInfo.panelID ?: @""),
            @"resource_id" : (self.shareInfo.resourceID ?: @""),
        }];
        if (authStatus == PHAuthorizationStatusNotDetermined) {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *showSuccess = @"cancel";
                    if (status == PHAuthorizationStatusAuthorized) {
                        [self handleShareResource];
                        showSuccess = @"submit";
                    } else {
                        [self handleNoAuthorization];
                    }
                    [BDUGShareEventManager event:kShareAuthorizeClick params:@{
                        @"channel_type" : (self.shareInfo.channelStringForEvent ?: @""),
                        @"is_first_request" : @"yes",
                        @"click_result" : showSuccess,
                        @"share_type" : @"video",
                        @"panel_type" : (self.shareInfo.panelType ?: @""),
                        @"panel_id" : (self.shareInfo.panelID ?: @""),
                        @"resource_id" : (self.shareInfo.resourceID ?: @""),
                    }];
                });
            }];
            [BDUGShareEventManager event:kShareAuthorizeShow params:@{
                @"is_first_request" : @"yes",
                @"channel_type" : (self.shareInfo.channelStringForEvent ?: @""),
                @"share_type" : @"video",
                @"panel_type" : (self.shareInfo.panelType ?: @""),
                @"panel_id" : (self.shareInfo.panelID ?: @""),
                @"resource_id" : (self.shareInfo.resourceID ?: @""),
            }];
        } else if (authStatus == PHAuthorizationStatusAuthorized) {
            [self handleShareResource];
        } else {
            [self handleNoAuthorization];
            [BDUGShareEventManager event:kShareAuthorizeShow params:@{
                @"is_first_request" : @"no",
                @"channel_type" : (self.shareInfo.channelStringForEvent ?: @""),
                @"share_type" : @"video",
                @"panel_type" : (self.shareInfo.panelType ?: @""),
                @"panel_id" : (self.shareInfo.panelID ?: @""),
                @"resource_id" : (self.shareInfo.resourceID ?: @""),
            }];
        }
    }
}

- (void)handleNoAuthorization
{
    [BDUGVideoImageShareDialogManager invokeAlbumAuthorizationDialogBlock:self.shareInfo continueBlock:^{
        [[UIApplication sharedApplication]openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        !self.shareInfo.completeBlock ?: self.shareInfo.completeBlock(BDUGVideoShareStatusCodeSaveVideoToAlbumPermissionDenied, @"没有相册权限", nil);
    }];
}

- (void)handleShareResource
{
    switch (self.shareInfo.shareType) {
        case BDUGVideoImageShareTypeImage: {
            if (self.shareInfo.resourceURLString.length > 0) {
                //优先使用url图片。
                [self processDownloadImage];
            } else if (self.shareInfo.shareImage){
                //没有网络图片，使用本地图。
                [self processMemoryImage:self.shareInfo.shareImage];
            } else {
                !self.shareInfo.completeBlock ?: self.shareInfo.completeBlock(BDUGVideoShareStatusCodeInvalidContent, @"There is no valid image", nil);
            }
        }
            break;
        case BDUGVideoImageShareTypeVideo: {
            if (self.shareInfo.sandboxPath.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:self.shareInfo.sandboxPath]) {
                [self processLocalVideo:self.shareInfo.sandboxPath];
            } else if (self.shareInfo.resourceURLString.length > 0) {
                [self processDownloadVideo];
            } else {
                !self.shareInfo.completeBlock ?: self.shareInfo.completeBlock(BDUGVideoShareStatusCodeInvalidContent, @"There is no video", nil);
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - process

- (void)processDownloadImage {
    [[BDWebImageManager sharedManager] requestImage:[NSURL URLWithString:self.shareInfo.resourceURLString] options:BDImageRequestDefaultPriority complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            [BDUGVideoImageShareDialogManager invokeDownloadCompletion];
            BOOL downloadSucceed = image && !error;
            if (downloadSucceed) {
                [self processMemoryImage:image];
            } else {
                !self.shareInfo.completeBlock ?: self.shareInfo.completeBlock(BDUGVideoShareStatusCodeVideoDownloadFailed, @"图片下载失败", nil);
            }
            [BDUGShareEventManager trackService:kShareMonitorImageDownload
                               metric:nil
                             category:@{@"status" : (downloadSucceed ? @(0) : @(1)),
                                        @"url" : (self.shareInfo.resourceURLString ?: @"")
                             }
                                          extra:nil];
        });
    }];
}

- (void)processDownloadVideo {
    if (![[NSFileManager defaultManager] fileExistsAtPath:BDUG_SHARE_VIDEO_LOCAL_PATH_FOLDER]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:BDUG_SHARE_VIDEO_LOCAL_PATH_FOLDER withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *localPath = BDUG_SHARE_VIDEO_LOCAL_PATH([self.shareInfo.resourceURLString btd_md5String]);
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        //如果已经下载过，直接使用。
        [self processLocalVideo:localPath];
    } else {
    //立刻调用progress，展示loading，避免出现弱网loading展示慢的问题。
        [BDUGVideoImageShareDialogManager invokeDownloadProgress:0];
        NSTimeInterval currentTime = CACurrentMediaTime();
        [[BDUGFileDownloader sharedInstance] downloadFileWithURLs:@[self.shareInfo.resourceURLString] downloadPath:localPath downloadProgress:^(CGFloat progress) {
            if (shareProcessShut) {
                return;
            }
            [BDUGVideoImageShareDialogManager invokeDownloadProgress:progress];
        } completion:^(NSError *error, NSString *filePath) {
            if (shareProcessShut) {
                [BDUGShareEventManager trackService:kShareMonitorVideoDownload
                                   metric:nil
                                 category:@{@"status" : @(2),
                                            @"url" : (self.shareInfo.resourceURLString ?: @"")
                                 }
                                              extra:nil];
                return ;
            }
            NSInteger duration = (NSInteger)((CACurrentMediaTime() - currentTime) * 1000);
            [BDUGVideoImageShareDialogManager invokeDownloadCompletion];
            BOOL downloadSucceed = !error && filePath.length > 0;
            if (downloadSucceed) {
                [self processLocalVideo:filePath];
            } else {
                //下载视频失败。
                !self.shareInfo.completeBlock ?: self.shareInfo.completeBlock(BDUGVideoShareStatusCodeVideoDownloadFailed, @"视频下载失败", nil);
            }
            [BDUGShareEventManager trackService:kShareMonitorVideoDownload
                               metric:nil
                             category:@{
                                 @"status" : (downloadSucceed ? @(0) : @(1)),
                                 @"url" : (self.shareInfo.resourceURLString ?: @"")
                             }
                                          extra:nil];
            [BDUGShareEventManager trackService:kShareMonitorVideoDownloadDuration
                                         metric:nil
                                       category:@{
                                           @"status" : (downloadSucceed ? @(0) : @(1)),
                                           @"duration" : @(duration)
                                       }
                                          extra:nil];
        }];
    }
}

- (void)processMemoryImage:(UIImage *)image {
    switch (self.shareInfo.shareStrategy) {
        case BDUGVideoImageShareStrategyResponseSaveSandbox: {
            NSString *sandboxPath = [[BDUG_SHARE_VIDEO_LOCAL_PATH_FOLDER stringByAppendingString:@"/"] stringByAppendingString:@"image.png"];
            [UIImageJPEGRepresentation(image, 1.0) writeToFile:sandboxPath atomically:YES];
            [self taskCompletionSaveStatus:YES sandboxPath:sandboxPath albumIdentifier:nil image:image];
        }
            break;
        case BDUGVideoImageShareStrategyResponseMemory: {
            [self taskCompletionSaveStatus:YES sandboxPath:nil albumIdentifier:nil image:image];
        }
            break;
        default: {
            //请求相册权限之后调用。
            __block NSString *identifier;
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetChangeRequest *req = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                identifier = req.placeholderForCreatedAsset.localIdentifier;
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self taskCompletionSaveStatus:success sandboxPath:nil albumIdentifier:identifier image:image];
                });
            }];
        }
            break;
    }
}

- (void)processLocalVideo:(NSString *)localPath
{
    if (self.shareInfo.shareStrategy == BDUGVideoImageShareStrategyResponseSaveSandbox) {
        [self taskCompletionSaveStatus:YES sandboxPath:localPath albumIdentifier:nil image:nil];
    } else {
        //请求相册权限之后调用。
        __block NSString *identifier;
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetChangeRequest *req = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:localPath]];
            identifier = req.placeholderForCreatedAsset.localIdentifier;
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self taskCompletionSaveStatus:success sandboxPath:localPath albumIdentifier:identifier image:nil];
            });
        }];
    }
}

#pragma mark - completion

- (void)taskCompletionSaveStatus:(BOOL)success sandboxPath:(NSString *)localPath albumIdentifier:(NSString *)identifier image:(UIImage *)image {
    if (success) {
        BDUGVideoImageShareContentModel *contentModel = [[BDUGVideoImageShareContentModel alloc] init];
        contentModel.originShareInfo = self.shareInfo;
        contentModel.sandboxPath = localPath;
        contentModel.albumIdentifier = identifier;
        if (identifier) {
            PHFetchResult* assetResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
            PHAsset *asset = [assetResult firstObject];
            contentModel.albumAsset = asset;
        }
        contentModel.resultImage = image;
        BDUGVideoShareBlock continueBlock = ^() {
            switch (self.shareInfo.shareStrategy) {
                case BDUGVideoImageShareStrategyOpenThirdApp: {
                    //这里打开三方应用并且返回结果给activity
                    BDUGVideoShareStatusCode status;
                    NSString *desc;
                    if (self.shareInfo.openThirdPlatformBlock) {
                        BOOL openPlatformSuccess = self.shareInfo.openThirdPlatformBlock();
                        if (openPlatformSuccess) {
                            status = BDUGVideoShareStatusCodeSuccess;
                            desc = @"分享成功";
                        } else {
                            status = BDUGVideoShareStatusCodePlatformOpenFailed;
                            desc = @"打开三方应用失败";
                        }
                    } else {
                        status = BDUGVideoShareStatusCodePlatformOpenFailed;
                        desc = @"打开三方应用失败";
                    }
                    !self.shareInfo.completeBlock ?: self.shareInfo.completeBlock(status, desc, contentModel);
                }
                    break;
                case BDUGVideoImageShareStrategyResponseSaveAlbum:
                case BDUGVideoImageShareStrategyResponseSaveSandbox:
                case BDUGVideoImageShareStrategyResponseMemory: {
                    //这里直接返回相册内容给activity
                    !self.shareInfo.completeBlock ?: self.shareInfo.completeBlock(BDUGVideoShareStatusCodeSuccess, @"分享成功", contentModel);
                }
                    break;
                default:
                    break;
            }
        };
        if (self.shareInfo.needPreviewDialog) {
            [BDUGVideoImageShareDialogManager invokeVideoSaveSucceedDialogBlock:contentModel continueBlock:continueBlock];
        } else {
            continueBlock();
        }
    } else {
        !self.shareInfo.completeBlock ?: self.shareInfo.completeBlock(BDUGVideoShareStatusCodeSaveVideoToAlbumFailed, @"视频保存失败", nil);
    }
}

@end

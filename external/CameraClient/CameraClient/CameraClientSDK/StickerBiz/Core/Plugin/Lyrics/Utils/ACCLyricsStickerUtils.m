//
//  ACCLyricsStickerUtils.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2020/12/2.
//

#import "ACCLyricsStickerUtils.h"
#import "ACCLyricsStickerContentView.h"
#import <CreationKitInfra/ACCPathUtils.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreationKitInfra/ACCLogProtocol.h>

#import <TTVideoEditor/IESInfoSticker.h>
#import <EffectPlatformSDK/IESFileDownloader.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKitSticker/ACCStickerProtocol.h>
#import <CreativeKit/ACCMacros.h>

@implementation ACCLyricsStickerUtils

+ (void)updateFrameForLyricsStickerWrapperView:(ACCStickerViewType)wrapperView
                            editStickerService:(id<ACCEditStickerProtocol>)editStickerService
{
    if (![wrapperView.contentView isKindOfClass:ACCLyricsStickerContentView.class]) {
        return;
    }
    
    ACCLyricsStickerContentView *lyricsStickerView = (ACCLyricsStickerContentView *)wrapperView.contentView;
    IESInfoStickerProps *props = [IESInfoStickerProps new];
    [editStickerService getStickerId:lyricsStickerView.stickerId props:props];
    props.scale = (isnan(props.scale) || isinf(props.scale) || props.scale == 0) ? 1.0 : props.scale;
    lyricsStickerView.stickerInfos = props;
    
    // 恢复歌词贴纸大小
    CGRect boundingbox = [editStickerService getstickerEditBoundBox:lyricsStickerView.stickerId];
    // !!!FIXME: 最小大小设置为 (1,1)，勿删除。
    // 原因是如果大小设置太小比如 `(0,0)` 会触发删除 Plugin 的逻辑导致歌词贴纸被自动删除，如果设置为更大则会影响后续坐标的计算。
    [lyricsStickerView updateSize:CGSizeMake(MAX(1, boundingbox.size.width/props.scale), MAX(1, boundingbox.size.height/props.scale))];
    lyricsStickerView.beginOrigin = boundingbox.origin;
    
    // 恢复歌词贴纸位置
    ACCStickerGeometryModel *geoModel = [wrapperView.stickerGeometry copy];
    geoModel.x = [[NSDecimalNumber alloc] initWithFloat:props.offsetX + CGRectGetMinX(boundingbox)];
    geoModel.y = [[NSDecimalNumber alloc] initWithFloat:-props.offsetY - CGRectGetMinY(boundingbox)];
    geoModel.rotation = [[NSDecimalNumber alloc] initWithFloat:props.angle];
    geoModel.scale = [[NSDecimalNumber alloc] initWithFloat:props.scale];

    [wrapperView recoverWithGeometryModel:geoModel];
}

+ (NSString *)formatLyricWithFilePath:(NSString *)filePath musicModel:(id<ACCMusicModelProtocol>)musicModel
{
    NSError *jsonError = nil;
    NSData *fileJSONData = [NSData dataWithContentsOfFile:filePath];
    NSDictionary *lyricContent = [NSJSONSerialization JSONObjectWithData:fileJSONData
                                                                 options:NSJSONReadingMutableContainers
                                                                   error:&jsonError];
    
    if (jsonError) {
        AWELogToolError(AWELogToolTagEdit, @"deserialize lyrics file content failed: %@, musicId: %@", jsonError, musicModel.musicID);
    }
    
    if (!lyricContent) {
        return nil;
    }
    
    NSDictionary *extraData = @{
        @"title" : musicModel.musicName ? : @"",
        @"artist" : musicModel.authorName ? : @""
    };
    
    NSDictionary *reWritterContent = @{
        @"header" : extraData,
        @"content" : lyricContent ? : @""
    };
    
    NSError *jsonError1 = nil;
    NSData *formatJSONData = [NSJSONSerialization dataWithJSONObject:reWritterContent
                                                             options:0
                                                               error:&jsonError1];
    
    if (jsonError1) {
        AWELogToolError(AWELogToolTagEdit, @"serialize lyrics sticker failed: %@, musicId: %@", jsonError1, musicModel.musicID);
    }
    
    NSString *formatLyricString = [[NSString alloc] initWithData:formatJSONData
                                                        encoding:NSUTF8StringEncoding];
    return formatLyricString;
}

+ (void)formatMusicLyricWithACCMusicModel:(id<ACCMusicModelProtocol>)musicModel
                               completion:(void (^)(NSString *lyricStr, NSError *error))completion
{
    if (!musicModel || !musicModel.lyricUrl) {
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:nil];
        ACCBLOCK_INVOKE(completion, nil, error);
        return;
    }
    
    NSString *lyricUrl = musicModel.lyricUrl;
    NSString *cachesDir = [ACCTemporaryDirectory() stringByAppendingPathComponent:@"LyricCache"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachesDir]) {
        NSError *createDirectoryError = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:cachesDir
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:&createDirectoryError];
        
        if (createDirectoryError) {
            AWELogToolError(AWELogToolTagEdit, @"lyrics sticker create directory failed: %@, musicId: %@", createDirectoryError, musicModel.musicID);
        }
    }
    
    NSString *downloadPath = [cachesDir stringByAppendingPathComponent:[musicModel.lyricUrl acc_md5String]];
    
    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:downloadPath];
    if (fileExist) {
        NSString *formatLyricString = [self formatLyricWithFilePath:downloadPath musicModel:musicModel];
        ACCBLOCK_INVOKE(completion, formatLyricString, nil);
    } else {
        CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
        
        [[IESFileDownloader sharedInstance] delegateDownloadFileWithURLs:@[lyricUrl]
                                                            downloadPath:downloadPath
                                                        downloadProgress:nil
                                                              completion:^(NSError *error, NSString *filePath, NSDictionary *extraInfoDict) {
            NSDictionary *extraInfo = @{
                @"music_id" : musicModel.musicID ?: @"",
                @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
            };
            
            if (error || !filePath) {
                [ACCMonitor() trackService:@"aweme_type_download_lyric_rate"
                                         status:1
                                          extra:extraInfo];
                [ACCToast() showError: ACCLocalizedCurrentString(@"error_retry")];
                ACCBLOCK_INVOKE(completion, nil, error);
            } else {
                [ACCMonitor() trackService:@"aweme_type_download_lyric_rate"
                                         status:0
                                          extra:extraInfo];
                NSString *formatLyricString = [self formatLyricWithFilePath:filePath musicModel:musicModel];
                ACCBLOCK_INVOKE(completion, formatLyricString, nil);
            }
        }];
    }
}

@end

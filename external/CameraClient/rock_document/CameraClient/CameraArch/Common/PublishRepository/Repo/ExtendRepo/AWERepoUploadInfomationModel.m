//
//  AWERepoUploadInfomationModel.m
//  CameraClient
//
//  Created by haoyipeng on 2020/10/22.
//

#import "AWERepoUploadInfomationModel.h"
#import <CreativeKit/ACCMacros.h>

#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/ACCPublishRepository.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CreationKitArch/ACCRepoCutSameModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "AWERepoVideoInfoModel.h"
#import "ACCRepoCanvasBusinessModel.h"
#import <CameraClient/AWEAssetModel.h>
#import <CameraClientModel/ACCVideoCanvasType.h>
#import "AWERepoMusicModel.h"
#import "ACCExifUtil.h"

@interface AWEVideoPublishViewModel (AWERepoUploadInfo) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoUploadInfo)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoUploadInfomationModel.class];
	return info;
}

- (AWERepoUploadInfomationModel *)repoUploadInfo
{
    AWERepoUploadInfomationModel *uploadInfoModel = [self extensionModelOfClass:AWERepoUploadInfomationModel.class];
    NSAssert(uploadInfoModel, @"extension model should not be nil");
    return uploadInfoModel;
}

@end

@implementation AWERepoUploadInfomationModel

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    AWERepoUploadInfomationModel *copy = [super copyWithZone:zone];
    copy.sourceInfoJson = self.sourceInfoJson;
    copy.extraDictData = self.extraDictData;
    copy.uploadImagePath = self.uploadImagePath;
    copy.uploadImagePathRelative = self.uploadImagePathRelative;
    copy.reactID = self.reactID.copy;
    
    return copy;
}

- (BOOL)isShootEnterFromGroot {
    NSString *shootEnterFrom = self.extraDict[@"shoot_enter_from"] ?: @"";
    if ([shootEnterFrom isEqualToString:@"groot_page"]) {
        return YES;
    }
    return NO;
}

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    if (contextModel.feedType == ACCFeedTypeAIMusicVideo) {
        result[@"mixed_type"] = @(self.clipSourceType);
    }
    result[@"is_multi_video_upload"] = @(self.isMultiVideoUpload);
    
    ACCRepoMusicModel *musicModel = [self.repository extensionModelOfClass:ACCRepoMusicModel.class];
    ACCRepoCutSameModel *cutSameModel = [self.repository extensionModelOfClass:ACCRepoCutSameModel.class];
    __block NSString *musicID = musicModel.music.musicID;
    if (musicID == nil || musicID.length == 0) {
        musicID = cutSameModel.cutSameMusicID;
    }
    if (ACC_isEmptyString(musicID) && [self.sourceInfos count] > 0) {
        void (^updateMusicID)(void) = ^ {
            NSString *musicIdFromFaceu = [self p_getMusicIdFromFaceuMetaData];
            if ([musicIdFromFaceu length] != 0 && [self p_isValidWithMusicIdFromFaceu:musicIdFromFaceu]) {
                musicID = musicIdFromFaceu;
            }
        };
        if (!self.isMultiVideoUpload) {
            updateMusicID();
        }
    }
    if (ACC_isEmptyString(musicID)) {
        AWERepoVideoInfoModel *videoInfo = [self.repository extensionModelOfClass:[AWERepoVideoInfoModel class]];
        ACCRepoCanvasBusinessModel *canvasBusinessModel = [self.repository extensionModelOfClass:[ACCRepoCanvasBusinessModel class]];
        if (videoInfo.canvasType == ACCVideoCanvasTypeRePostVideo || videoInfo.canvasType == ACCVideoCanvasTypeShareAsStory) {
            musicID = canvasBusinessModel.musicID;
        }
    }
    
    if (ACC_isEmptyString(musicID)) {
        AWERepoMusicModel *repoMusic = [self.repository extensionModelOfClass:AWERepoMusicModel.class];
        musicID = repoMusic.passthroughMusicID;
    }

    result[@"music_id"] = musicID;
    [self p_uploadSourceInfo:result];
    
    result[@"shoot_enter_from"] = self.extraDict[@"shoot_enter_from"];

    return result;
}

- (NSString *)p_getMusicIdFromFaceuMetaData
{
    NSArray *sourceInfo = [self sourceInfosArray];
    if (sourceInfo != nil) {
        AWEVideoPublishSourceInfo *info = self.sourceInfos.firstObject;
        NSDictionary *data = (NSDictionary *)info.descriptionInfo[@"data"];
        id musicIdValue = data[@"musicId"];
        if (musicIdValue != nil && [musicIdValue isKindOfClass:[NSString class]]) {
            NSString *musicIdString = (NSString *)musicIdValue;
            return musicIdString;
        }
    }
    return nil;
}

- (void)p_uploadSourceInfo:(NSMutableDictionary *)mutableParameter
{
    NSArray *sourceInfo = [self sourceInfosArray];
    if (sourceInfo != nil) {
        @weakify(self);
        void (^addMutableParameterSourceInfo)(void) = ^{
            @strongify(self);
            NSString *musicIdFromFaceu = [self p_getMusicIdFromFaceuMetaData];
            if ([self p_isValidWithMusicIdFromFaceu:musicIdFromFaceu]) {
                NSError *error = nil;
                NSData *data = [NSJSONSerialization dataWithJSONObject:sourceInfo.firstObject options:0 error:&error];
                if (data != nil) {
                    mutableParameter[@"source_info"] = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                }
                
                if (error) {
                    AWELogToolError(AWELogToolTagPublish, @"%s %@", __PRETTY_FUNCTION__, error);
                }
            }
        };
        if (!self.isMultiVideoUpload) {
            addMutableParameterSourceInfo();
        } else if (self.isFaceuVideoFirst) {
            addMutableParameterSourceInfo();
        } else {
            
        }
    }
}

- (BOOL)p_isValidWithMusicIdFromFaceu:(NSString *)musicId
{
    // if there are many musicId, it is separated with ","
    if ([musicId containsString:@","]) {
        return NO;
    } else {
        return YES;
    }
}

+ (AWEVideoPublishSourceInfo *)p_sourceInfoWithImageData:(NSData *)data
{
    if (data.length == 0) {
        return nil;
    }
    
    NSDictionary *properties = [data acc_imageProperties];
    NSDictionary *exif = [properties acc_dictionaryValueForKey:(NSString *)kCGImagePropertyExifDictionary];
    NSString *userComment = [exif acc_stringValueForKey:(NSString *)kCGImagePropertyExifUserComment];
    AWELogToolInfo(AWELogToolTagUpload, @"imageSourceInfo: userComment = %@", userComment);

    AWEVideoPublishSourceInfo *sourceInfo = nil;
    if (userComment.length) {
        NSData *commentData = [userComment dataUsingEncoding:NSUTF8StringEncoding];
        if (commentData.length) {
            NSError *error = nil;
            NSDictionary *descriptionInfo = [NSJSONSerialization JSONObjectWithData:commentData options:0 error:&error];
            if (error) {
                AWELogToolError(AWELogToolTagDraft, @"%s %@", __PRETTY_FUNCTION__, error);
            }
            if (!error && [self p_isValidImageDescriptionInfo:descriptionInfo]) {
                sourceInfo = [[AWEVideoPublishSourceInfo alloc] init];
                sourceInfo.descriptionInfo = descriptionInfo;
            }
        }
        if (!sourceInfo) {
            AWELogToolInfo(AWELogToolTagUpload, @"imageSourceInfo: userComment exists but invalid");
        }
    }
    return sourceInfo;
}

+ (BOOL)p_isValidImageDescriptionInfo:(NSDictionary *)descriptionInfo
{
    if ([descriptionInfo isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dataDictionary = [descriptionInfo acc_dictionaryValueForKey:@"data"];
        NSString *product = [dataDictionary acc_stringValueForKey:@"product"];
        if ([product isEqualToString:@"retouch"] || [product isEqualToString:@"beautyme"]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Public

- (void)updateImageSourceInfoIfNeeded
{
    if (self.sourceInfos.count) {
        AWELogToolInfo(AWELogToolTagUpload, @"imageSourceInfo count = %@", @(self.sourceInfos.count));
        return;
    }

    AWELogToolInfo(AWELogToolTagUpload, @"imageSourceInfo start: count = %@", @(self.sourceInfos.count));

    NSArray<AWEAssetModel *> *totalAssets = [self.selectedUploadAssets copy];
    AWERepoContextModel *contextModel = [self.repository extensionModelOfClass:[AWERepoContextModel class]];
    PHAsset *shareImageAsset = contextModel.shareImageAsset;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray<PHAsset *> *imageAssets = [NSMutableArray array];
        if (shareImageAsset) {
            [imageAssets acc_addObject:shareImageAsset];
        } else {
            for (AWEAssetModel *model in totalAssets) {
                if (model.asset && model.asset.mediaType == PHAssetMediaTypeImage) {
                    [imageAssets acc_addObject:model.asset];
                }
            }
            if (imageAssets.count != totalAssets.count) {
                AWELogToolInfo(AWELogToolTagUpload, @"imageSourceInfo finish: total=%@ image=%@)", @(totalAssets.count), @(imageAssets.count));
                return;
            }
            if (imageAssets.count == 0) {
                AWELogToolInfo(AWELogToolTagUpload, @"imageSourceInfo finish: no image");
                return;
            }
        }

        AWELogToolInfo(AWELogToolTagUpload, @"imageSourceInfo: image count = %@", @(imageAssets.count));

        NSInteger currentIndex = 0;
        __block AWEVideoPublishSourceInfo *sourceInfo = nil;

        for (currentIndex = 0; currentIndex < imageAssets.count; ++currentIndex) {
            @autoreleasepool {
                AWELogToolInfo(AWELogToolTagUpload, @"imageSourceInfo: fetch index = %@", @(currentIndex));
                PHAsset *asset = imageAssets[currentIndex];
                PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                options.resizeMode = PHImageRequestOptionsResizeModeFast;
                options.synchronous = YES;
                options.networkAccessAllowed = YES;

                [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                    sourceInfo = [AWERepoUploadInfomationModel p_sourceInfoWithImageData:imageData];
                }];
                if (sourceInfo) {
                    break;
                }
            }
        }

        if (sourceInfo) {
            AWELogToolInfo(AWELogToolTagUpload, @"imageSourceInfo finish: success index = %@", @(currentIndex));
            acc_infra_main_async_safe(^{
                if (!self.sourceInfos) {
                    self.sourceInfos = [NSMutableArray array];
                }
                if (self.sourceInfos.count == 0) {
                    [self.sourceInfos acc_addObject:sourceInfo];
                }
            });
        } else {
            AWELogToolInfo(AWELogToolTagUpload, @"imageSourceInfo finish: fail");
        }
    });
}

- (BOOL)isAIVideoClipMode
{
    ACCRepoContextModel *contextModel = [self.repository extensionModelOfClass:[ACCRepoContextModel class]];
    return contextModel.videoType != AWEVideoTypeOneClickFilming  && self.videoClipMode == AWEVideoClipModeAI;
}

- (NSArray *)sourceInfosArray
{
    if (self.sourceInfos.count > 0) {
        NSMutableArray *result = [NSMutableArray new];
        for (AWEVideoPublishSourceInfo *info in self.sourceInfos) {
            NSDictionary *item = [info jsonInfo];
            if (item != nil) {
                [result addObject:item];
            }
        }
        return result;
    }
    return nil;
}


#pragma mark - ACCRepositoryTrackContextProtocol

- (NSDictionary *)acc_referExtraParams
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"original_resolution"] = [self firstValidOriginalResolution];
    
    return dict;
}

- (NSString *)firstValidOriginalResolution
{
    __block NSString *resolution = @"";
    id resolutions = [self.extraDict objectForKey:@"original_resolution"];
    if (resolutions && [resolutions isKindOfClass:[NSArray class]] && !ACC_isEmptyArray(resolutions)) {
        [((NSArray *)resolutions) enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!ACC_isEmptyString(obj)) {
                resolution = obj;
                *stop = YES;
            }
        }];
    } else {
        [self.selectedUploadAssets enumerateObjectsUsingBlock:^(AWEAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!ACC_isEmptyString(obj.originalResolution)) {
                resolution = obj.originalResolution;
                *stop = YES;
            }
        }];
    }
    
    return resolution;
}

@end

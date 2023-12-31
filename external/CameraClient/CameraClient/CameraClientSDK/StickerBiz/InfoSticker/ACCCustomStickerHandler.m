//
//  ACCCustomStickerHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/4/19.
//

#import "ACCCustomStickerHandler.h"
#import "AWECustomStickerImageProcessor.h"
#import "AWECustomPhotoStickerEditConfig.h"
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <YYImage/YYImage.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "ACCAddInfoStickerContext.h"
#import <TTVideoEditor/IESInfoSticker.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import "ACCInfoStickerConfig.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import "AWERepoVideoInfoModel.h"
#import "AWERepoStickerModel.h"

@implementation ACCCustomStickerHandler

- (BOOL)canExpressSticker:(ACCEditorStickerConfig *)stickerConfig
{
    if ([stickerConfig isKindOfClass:[ACCEditorCustomStickerConfig class]]) {
        ACCEditorCustomStickerConfig *customStickerConfig = (ACCEditorCustomStickerConfig *)stickerConfig;
        if (customStickerConfig.dataUIT != nil && (customStickerConfig.image != nil || customStickerConfig.imageData != nil)) {
            return YES;
        }
    }
    return NO;
}

- (IESInfoStickerProps *)infoStickerPropsFromLocation:(AWEInteractionStickerLocationModel *)locationModel
{
    if (locationModel != nil) {
        IESInfoStickerProps *props = [[IESInfoStickerProps alloc] init];
        props.offsetX = ([locationModel.x floatValue] - 0.5) * self.repository.repoVideoInfo.playerFrame.size.width;
        props.offsetY = (0.5 - [locationModel.y floatValue]) * self.repository.repoVideoInfo.playerFrame.size.height;
        props.angle = [locationModel.rotation floatValue];
        props.scale = [locationModel.scale floatValue];
        return props;
    };
    return nil;
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig
{
    [self expressSticker:stickerConfig onCompletion:^{
        
    }];
}

- (void)expressSticker:(ACCEditorStickerConfig *)stickerConfig onCompletion:(void (^)(void))completionHandler
{
    if ([self canExpressSticker:stickerConfig]) {
        ACCEditorCustomStickerConfig *customStickerConfig = (ACCEditorCustomStickerConfig *)stickerConfig;
        AWEInteractionStickerLocationModel *locationModel = [stickerConfig locationModel];
        IESEffectModel *sticker = [[IESEffectModel alloc] init];
        NSString *filePrefix = [[AWEDraftUtils generateDraftFolderFromTaskId:self.repository.repoDraft.taskID] stringByAppendingPathComponent:[NSUUID UUID].UUIDString];
        AWECustomPhotoStickerEditConfig *customPhototStickerConfig = [[AWECustomPhotoStickerEditConfig alloc] initWithUTI:customStickerConfig.dataUIT limit:nil];
        if (customStickerConfig.image) {
            customPhototStickerConfig.inputImage = customStickerConfig.image;
            @weakify(self);
            [self saveAndApplySticker:sticker config:customPhototStickerConfig draftFilePrefix:filePrefix completionBlock:^(ACCAddInfoStickerContext * _Nullable context) {
                if (context != nil) {
                    @strongify(self);
                    NSInteger stickerID = [self.infoStickerHandler addInfoSticker:context.stickerModel stickerProps:[self infoStickerPropsFromLocation:locationModel] targetMaxEdgeNumber:customStickerConfig.maxEdgeNumber path:context.path tabName:context.tabName userInfoConstructor:^(NSMutableDictionary * _Nonnull userInfo) {
                        userInfo[ACCStickerDeleteableKey] = @(customStickerConfig.deleteable);
                        userInfo[kACCStickerGroupIDKey] = customStickerConfig.groupId;
                        userInfo[kACCStickerSupportedGestureTypeKey] = @(customStickerConfig.supportedGestureType);
                        userInfo[kACCStickerMinimumScaleKey] = @(customStickerConfig.minimumScale);
                    } constructor:^(ACCInfoStickerConfig * _Nonnull config, CGSize size) {
                        config.deleteable = @(customStickerConfig.deleteable);
                        config.groupId = stickerConfig.groupId;
                        config.supportedGestureType = stickerConfig.supportedGestureType;
                        config.minimumScale = stickerConfig.minimumScale;
                        config.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id  _Nullable contextId, UIGestureRecognizer * _Nonnull gestureRecognizer) {
                            return stickerConfig.supportedGestureType & gestureType;
                        };
                    } onCompletion:completionHandler];
                    
                    if (stickerConfig.layerIndex != 0) {
                        [self.player setStickerLayer:stickerID layer:stickerConfig.layerIndex];
                    }
                } else {
                    if (completionHandler) {
                        completionHandler();
                    }
                }
            }];
        } else {
            @weakify(self);
            [self compressImageData:customStickerConfig.imageData config:customPhototStickerConfig onCompletion:^(BOOL result) {
                if (result) {
                    @strongify(self);
                    [self saveAndApplySticker:sticker config:customPhototStickerConfig draftFilePrefix:filePrefix completionBlock:^(ACCAddInfoStickerContext * _Nullable context) {
                        if (context != nil) {
                            @strongify(self);
                            [self.infoStickerHandler addInfoSticker:context.stickerModel stickerProps:[self infoStickerPropsFromLocation:locationModel] targetMaxEdgeNumber:customStickerConfig.maxEdgeNumber path:context.path tabName:context.tabName userInfoConstructor:^(NSMutableDictionary * _Nonnull userInfo) {
                                userInfo[ACCStickerDeleteableKey] = @(customStickerConfig.deleteable);
                            } constructor:^(ACCInfoStickerConfig * _Nonnull config, CGSize size) {
                                config.deleteable = @(customStickerConfig.deleteable);
                                config.groupId = stickerConfig.groupId;
                                config.supportedGestureType = stickerConfig.supportedGestureType;
                            } onCompletion:completionHandler];
                        } else {
                            if (completionHandler) {
                                completionHandler();
                            }
                        }
                    }];
                } else {
                    if (completionHandler) {
                        completionHandler();
                    }
                    AWELogToolError(AWELogToolTagEdit, @"express custom sticker failed with compress data, data size:%@", @(customStickerConfig.imageData.length));
                }
            }];
        }
    } else {
        if (completionHandler) {
            completionHandler();
        }
    }
}

- (void)compressImageData:(NSData *)imageData config:(AWECustomPhotoStickerEditConfig *)config onCompletion:(void (^)(BOOL result))completionBlock
{
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970] * 1000;
    [AWECustomStickerImageProcessor compressInputStickerOriginData:imageData isGIF:config.isGIF limitConfig:config.configs completionBlock:^(BOOL success, YYImage *animatedImage, UIImage *inputImage) {
        BOOL compressSuccess = (inputImage.size.width && inputImage.size.height) || (animatedImage.size.width && animatedImage.size.height);
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970] * 1000;
        [ACCMonitor() trackService:@"custom_sticker_image_compress" status:compressSuccess ? 0 : 1 extra:@{@"isGIF":@(config.isGIF?1:2),@"duration":@(endTime-startTime)}];
        
        if (compressSuccess) {
            config.animatedImage = animatedImage;
            config.inputImage = inputImage;
        }
        
        if (completionBlock) {
            completionBlock(compressSuccess);
        };
    }];
}

- (void)saveAndApplySticker:(IESEffectModel *)sticker config:(AWECustomPhotoStickerEditConfig *)config draftFilePrefix:(NSString *)draftFilePrefix completionBlock:(void (^)(ACCAddInfoStickerContext * _Nullable context))completionBlock
{
    BOOL usePNG = [config shouldUsePNGRepresentation] || (config.useProcessedData && config.processedImage);
    UIImage *outputImage = nil;
    if (config.isGIF) {
        outputImage = config.animatedImage;
    } else {
        outputImage = (config.useProcessedData && config.processedImage) ? config.processedImage : config.inputImage;
    }
    
    @weakify(self);
    [AWECustomStickerImageProcessor saveAndSampleStickerImage:outputImage usePNG:usePNG filePrefix:draftFilePrefix completionBlock:^(BOOL success, NSString *filePath, NSArray *framePaths) {
        @strongify(self);
        if (success) {
            sticker.uploadFramePaths = framePaths;
            sticker.useRemoveBg = config.useProcessedData;
            ACCAddInfoStickerContext *context = [self contextFromCustomSticker:sticker path:filePath tabName:@""];
            if (completionBlock) {
                completionBlock(context);
            }
        } else {
            if (completionBlock) {
                completionBlock(nil);
            }
        }
    }];
}

- (ACCAddInfoStickerContext *)contextFromCustomSticker:(IESEffectModel *)sticker path:(NSString *)path tabName:(NSString *)tabName
{
    ACCAddInfoStickerContext *context = [[ACCAddInfoStickerContext alloc] init];
    context.stickerModel = sticker;
    context.path = path;
    context.tabName = tabName;
    context.source = ACCInfoStickerSourceCustom;
    return context;
}

@end

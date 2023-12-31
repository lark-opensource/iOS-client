//
//  ACCCustomStickerComponent.m
//  CameraClient
//
//  Created by 卜旭阳 on 2020/6/25.
//

#import "ACCCustomStickerComponent.h"
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import "IESEffectModel+CustomSticker.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import "ACCSelectAlbumAssetsProtocol.h"
#import "ACCAlbumInputData.h"
#import <CameraClient/AWEAssetModel.h>
#import "ACCViewControllerProtocol.h"
#import "ACCCustomStickerViewModel.h"
#import "AWEEditPageProtocol.h"
#import "AWECustomPhotoStickerEditViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import "AWECustomStickerImageProcessor.h"
#import "AWECustomPhotoStickerEditConfig.h"
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <YYImage/YYImage.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import "ACCStickerPanelServiceProtocol.h"
#import "ACCStickerServiceProtocol.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>

#import "ACCTransitioningDelegateProtocol.h"
#import "ACCInfoStickerServiceProtocol.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>

#import <CreativeAlbumKit/CAKAlbumViewController.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import "ACCSecurityFramesExporter.h"

NSString *const AWECustomStickerAlbumLoadTimingKey = @"custom_sticker_imageload_duration_timing";

@interface ACCCustomStickerComponent() <ACCStickerPannelObserver>

@property (nonatomic, strong) id <UIViewControllerTransitioningDelegate, ACCInteractiveTransitionProtocol> transitionDelegate;
@property (nonatomic, strong) id <UIViewControllerTransitioningDelegate> nextTranslationTransitionDelegate;

@property (nonatomic, copy) NSString *tabName;
@property (nonatomic, copy) NSString *pickId;
@property (nonatomic, assign) PHImageRequestID currentId;
@property (nonatomic, strong) AWECustomPhotoStickerEditConfig *currentConfig;

@property (nonatomic, weak) UIView<ACCLoadingViewProtocol> *loadingView;
@property (nonatomic, weak) UINavigationController *customStickerEditNavVc;
@property (nonatomic, weak) AWECustomPhotoStickerEditViewController *editVC;
@property (nonatomic, weak) CAKAlbumViewController *resourcePickerViewController;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCInfoStickerServiceProtocol> infoStickerService;
@property (nonatomic, weak) id<ACCStickerPanelServiceProtocol> stickerPanelService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, strong) ACCCustomStickerViewModel *viewModel;

@property (nonatomic, copy, nullable) void (^dismissPanelHandle)(ACCStickerType, BOOL);

@end

@implementation ACCCustomStickerComponent

IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, infoStickerService, ACCInfoStickerServiceProtocol)
IESAutoInject(self.serviceProvider, stickerPanelService, ACCStickerPanelServiceProtocol)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)

- (void)componentDidMount {
    [self.stickerPanelService registObserver:self];
    
    @weakify(self);
    [self.infoStickerService.addStickerFinishedSignal subscribeNext:^(ACCAddInfoStickerContext * _Nullable context) {
        @strongify(self);
        if (context.source != ACCInfoStickerSourceCustom) {
            return ;
        }
        BOOL addSuccess = (context.stickerID >= 0);
        if(addSuccess) {
            if([self.currentConfig isGIF]) {
                [self.editService.preview seekToTime:kCMTimeZero];
            }
            [self.editService.preview play];
            [self.editVC saveImageCompleted];
            [self.controller.root dismissViewControllerAnimated:NO completion:nil];
            [self trackForEnterCustomStickerEvent:@"click_diy_prop_confirm" extraParams:@{@"remove_background":@(self.currentConfig.useProcessedData)}];
            ACCBLOCK_INVOKE(context.completion);
        } else {
            [self.editVC saveImageCompleted];
            [ACCToast() showError:ACCLocalizedString(@"creation_edit_sticker_upload_toast2",@"To continue, use an image that meets our guidelines")];
        }
    }];
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCCustomStickerServiceProtocol), self.viewModel);
}

#pragma mark - ACCComponentProtocol

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

//1.Present Select VC
- (void)selectCustomSticker:(IESEffectModel *)sticker fromTab:(NSString *)tabName completionBlock:(void(^)(void))completionBlock cancelBlock:(void(^)(void))cancelBlock
{
    ACCAlbumInputData *inputData = [[ACCAlbumInputData alloc] init];
    inputData.originUploadPublishModel = self.publishModel;
    inputData.vcType = ACCAlbumVCTypeForCustomSticker;
    self.tabName = tabName;
    [self.editService.preview pause];
    [self trackForEnterCustomStickerEvent:@"click_diy_prop_entrance" extraParams:nil];
    @weakify(self);
    inputData.selectPhotoCompletion = ^(AWEAssetModel * _Nullable asset) {
        @strongify(self);
        [self.loadingView dismiss];
        [self trackForEnterCustomStickerEvent:@"choose_diy_prop_material" extraParams:nil];
        if([self checkErrorMsgWithFetchedAsset:asset]) {
            return;
        }
        [self loadAlbumCustomSticker:sticker asset:asset.asset completionBlock:^{
            @strongify(self);
            self.pickId = nil;
            ACCBLOCK_INVOKE(completionBlock);
        } cancelBlock:^{
            @strongify(self);
            self.pickId = nil;
            ACCBLOCK_INVOKE(cancelBlock);
        }];
    };
    
    inputData.dismissBlock = ^{
        @strongify(self);
        self.pickId = nil;
        [self.editService.preview play];
        [ACCToast() dismissToast];
        [[PHImageManager defaultManager] cancelImageRequest:self.currentId];
        ACCBLOCK_INVOKE(cancelBlock);
    };
    
    CAKAlbumViewController * resourcePickerViewController  = [IESAutoInline(ACCBaseServiceProvider(), ACCSelectAlbumAssetsProtocol) albumViewControllerWithInputData:inputData];

    self.resourcePickerViewController = resourcePickerViewController;
    self.customStickerEditNavVc = [ACCViewControllerService() createCornerBarNaviControllerWithRootVC:resourcePickerViewController];
    self.customStickerEditNavVc.navigationBar.translucent = NO;
    self.customStickerEditNavVc.modalPresentationStyle = UIModalPresentationCustom;
    self.customStickerEditNavVc.transitioningDelegate = self.transitionDelegate;
    self.customStickerEditNavVc.modalPresentationCapturesStatusBarAppearance = YES;
    self.transitionDelegate.swipeInteractionController.forbidSimultaneousScrollViewPanGesture = YES;
    [self.controller.root presentViewController:self.customStickerEditNavVc animated:YES completion:nil];
}

//2.Get image data from album
- (void)loadAlbumCustomSticker:(IESEffectModel *)sticker asset:(PHAsset *)photo completionBlock:(void (^)(void))completionBlock cancelBlock:(void (^)(void))cancelBlock
{
    NSString *pickId = [NSUUID UUID].UUIDString;
    self.pickId = pickId;
    self.loadingView = [ACCLoading() showLoadingOnView:self.customStickerEditNavVc.view];
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    //Duration import from album
    [ACCMonitor() startTimingForKey:AWECustomStickerAlbumLoadTimingKey];
    //resultHandler will be called in main thread
    @weakify(self);
    self.currentId = [[PHImageManager defaultManager] requestImageDataForAsset:photo options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            if([[info objectForKey:PHImageResultIsInCloudKey] boolValue] && [pickId isEqualToString:self.pickId]) {
                PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
                option.networkAccessAllowed = YES;
                option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                self.currentId = [[PHImageManager defaultManager] requestImageDataForAsset:photo options:option resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                    @strongify(self);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ACCToast() dismissToast];
                        [self showCustomStickerPreview:sticker pickerId:pickId imageData:imageData dataUTI:dataUTI info:info completionBlock:completionBlock cancelBlock:cancelBlock];
                        [ACCMonitor() trackService:@"custom_sticker_imageload_duration" status:0 extra:@{@"duration":@([ACCMonitor() timeIntervalForKey:AWECustomStickerAlbumLoadTimingKey])}];
                        [ACCMonitor() cancelTimingForKey:AWECustomStickerAlbumLoadTimingKey];
                    });
                }];
                [ACCToast() show:ACCLocalizedString(@"creation_icloud_download", @"正在从iCloud同步内容")];
            } else {
                [self showCustomStickerPreview:sticker pickerId:pickId imageData:imageData dataUTI:dataUTI info:info completionBlock:completionBlock cancelBlock:cancelBlock];
                [ACCMonitor() trackService:@"custom_sticker_imageload_duration" status:0 extra:@{@"duration":@([ACCMonitor() timeIntervalForKey:AWECustomStickerAlbumLoadTimingKey])}];
                [ACCMonitor() cancelTimingForKey:AWECustomStickerAlbumLoadTimingKey];
            }
        });
    }];
}

//3.Compress image data and present edit vc
- (void)showCustomStickerPreview:(IESEffectModel *)sticker pickerId:(NSString *)pickId imageData:(NSData *)imageData dataUTI:dataUTI info:info completionBlock:(void (^)(void))completionBlock cancelBlock:(void (^)(void))cancelBlock
{
    if(![pickId isEqualToString:self.pickId] || [self checkErrorMsgWithFetchedImageData:imageData dataUTI:dataUTI info:info limitConfig:sticker.limitConfig]) {
        return;
    }
    
    AWECustomPhotoStickerEditConfig *config = [[AWECustomPhotoStickerEditConfig alloc] initWithUTI:dataUTI limit:sticker.limitConfig];
    //Duration for compress
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970] * 1000;
    @weakify(self);
    [AWECustomStickerImageProcessor compressInputStickerOriginData:imageData isGIF:config.isGIF limitConfig:config.configs completionBlock:^(BOOL success, YYImage *animatedImage, UIImage *inputImage) {
        @strongify(self);
        if(![pickId isEqualToString:self.pickId]) {
            return;
        }
        [self.loadingView dismiss];
        
        BOOL compressSuccess = (inputImage.size.width && inputImage.size.height) || (animatedImage.size.width && animatedImage.size.height);
        NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970] * 1000;
        [ACCMonitor() trackService:@"custom_sticker_image_compress" status:compressSuccess ? 0 : 1 extra:@{@"isGIF":@(config.isGIF?1:2),@"duration":@(endTime-startTime)}];
        
        if(!compressSuccess) {
            ACCBLOCK_INVOKE(cancelBlock);
            return;
        }
        
        config.animatedImage = animatedImage;
        config.inputImage = inputImage;
        
        AWECustomPhotoStickerEditViewController *editVC = [[AWECustomPhotoStickerEditViewController alloc] initWithConfig:config];
        editVC.completionBlock = ^{
            @strongify(self);
            !self.dismissPanelHandle ?: self.dismissPanelHandle(ACCStickerTypeCustomSticker, YES);
            self.dismissPanelHandle = nil;
            
            [self saveAndApplySticker:sticker config:config pickId:pickId completionBlock:completionBlock];
        };
        editVC.clickOnRemoveBgBlock = ^{
            @strongify(self);
            [self trackForEnterCustomStickerEvent:@"click_remove_background" extraParams:nil];
        };
        editVC.cancelBlock = ^{
            @strongify(self);
            [self.resourcePickerViewController dismissViewControllerAnimated:YES completion:nil];
            ACCBLOCK_INVOKE(cancelBlock);
        };
        self.editVC = editVC;
        editVC.modalPresentationStyle = UIModalPresentationCustom;
        editVC.transitioningDelegate = self.nextTranslationTransitionDelegate;
        editVC.modalPresentationCapturesStatusBarAppearance = YES;
        [self.resourcePickerViewController presentViewController:editVC animated:YES completion:nil];
    }];
}

// 将贴纸保存至本地，如果保存本地失败，现在应该是会应用不上贴纸
- (void)saveAndApplySticker:(IESEffectModel *)sticker
                     config:(AWECustomPhotoStickerEditConfig *)config
                     pickId:(NSString *)pickId
            completionBlock:(void (^)(void))completionBlock
{
    acc_dispatch_queue_async_safe(dispatch_get_global_queue(0, 0), ^{
        self.currentConfig = config;

        BOOL usePNG = [config shouldUsePNGRepresentation] || (config.useProcessedData && config.processedImage);
        UIImage *outputImage = nil;
        if(config.isGIF) {
            outputImage = config.animatedImage;
        } else {
            outputImage = (config.useProcessedData && config.processedImage) ? config.processedImage : config.inputImage;
        }

        NSError *writeError = nil;
        NSData *resultData = nil;
        NSString *suffix = @"";
        
        if(config.isGIF) {
            YYImage *animatedImage = (YYImage *)outputImage;
            if(animatedImage.animatedImageData && [animatedImage animatedImageFrameCount] > 1) {
                resultData = animatedImage.animatedImageData;
                suffix = @"gif";
            } else {
                if (animatedImage.images.count == 1) {
                    resultData = usePNG ? UIImagePNGRepresentation(outputImage.images.firstObject) : UIImageJPEGRepresentation(animatedImage.images.firstObject, 0.9);
                    suffix = usePNG ? @"png" : @"jpg";
                }
            }
        } else {
            resultData = usePNG ? UIImagePNGRepresentation(outputImage) : UIImageJPEGRepresentation(outputImage, 0.9);
            suffix = usePNG ? @"png" : @"jpg";
        }
        
        if (resultData.length > 0) {
            NSString *filePrefix = [[AWEDraftUtils generateDraftFolderFromTaskId:self.publishModel.repoDraft.taskID] stringByAppendingPathComponent:pickId];
            NSString *stickerPath = [NSString stringWithFormat:@"%@.%@",filePrefix,suffix];
            
            BOOL OK = [resultData acc_writeToFile:stickerPath options:NSDataWritingAtomic error:&writeError];
            if (OK && !writeError) {
                sticker.customStickerFilePath = stickerPath;
                sticker.useRemoveBg = config.useProcessedData;
            } else {
                sticker.customStickerFilePath = @"";
                AWELogToolError(AWELogToolTagEdit, @"添加自定义贴纸失败，保存到自定义贴纸图片到磁盘失败: %@", writeError);
            }
        } else {
            sticker.customStickerFilePath = @"";
            AWELogToolError(AWELogToolTagEdit, @"添加自定义贴纸失败，图片格式异常");
        }

        acc_dispatch_main_async_safe(^{
            [self.viewModel addCustomSticker:sticker
                                        path:sticker.customStickerFilePath
                                     tabName:self.tabName
                                  completion:completionBlock];
        });
    });
}

#pragma mark - ACCStickerPannelObserver

- (BOOL)handleSelectSticker:(IESEffectModel *)sticker fromTab:(NSString *)tabName
           willSelectHandle:(dispatch_block_t)willSelectHandle
         dismissPanelHandle:(void (^)(ACCStickerType type, BOOL animated))dismissPanelHandle
{
    self.dismissPanelHandle = dismissPanelHandle;

    if (self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
        if (self.stickerService.stickerCount >= ACCConfigInt(kConfigInt_album_image_max_sticker_count)) {
            return NO;
        }
    } else if (self.stickerService.infoStickerCount >= ACCConfigInt(kConfigInt_info_sticker_max_count)) {
        return NO;
    }
    
    if (![sticker isUploadSticker]) {
        return NO;
    }
    if ([ACCDeviceAuth isiOS14PhotoNotDetermined]) {
        // If photo library authorization is not determined on iOS 14, we directly show gallery VC and request for authorization in that VC.
        [self selectCustomSticker:sticker fromTab:tabName completionBlock:willSelectHandle cancelBlock:willSelectHandle];
    } else {
        @weakify(self);
        [ACCDeviceAuth requestPhotoLibraryPermission:^(BOOL success) {
            @strongify(self);
            if (success) {
                [self selectCustomSticker:sticker fromTab:tabName completionBlock:willSelectHandle cancelBlock:willSelectHandle];
            } else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:ACCLocalizedCurrentString(@"tip") message:ACCLocalizedCurrentString( @"com_mig_failed_to_access_photos_please_go_to_the_settings_to_enable_access") preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"go_to_settings",@"go_to_settings") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    acc_dispatch_main_async_safe(^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    });
                    ACCBLOCK_INVOKE(willSelectHandle);
                }]];
                [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    ACCBLOCK_INVOKE(willSelectHandle);
                }]];
                [ACCAlert() showAlertController:alertController animated:YES];
            }
        }];
    }
    return YES;
}

- (ACCStickerPannelObserverPriority)stikerPriority {
    return ACCStickerPannelObserverPriorityCustom;
}

#pragma mark - private

- (BOOL)checkErrorMsgWithFetchedAsset:(AWEAssetModel *)asset
{
    PHAsset *photo = asset.asset;
    BOOL hasError = NO;
    //Judge source size
    if(asset.mediaType != AWEAssetModelMediaTypePhoto || photo.pixelWidth <= 0 || photo.pixelHeight <= 0) {
        hasError = YES;
        [ACCToast() showError:ACCLocalizedString(@"creation_edit_sticker_upload_toast2",@"To continue, use an image that meets our guidelines")];
    }
    return hasError;
}

- (BOOL)checkErrorMsgWithFetchedImageData:(NSData *)imageData dataUTI:(NSString *)dataUTI info:(NSDictionary *)info limitConfig:(AWECustomStickerLimitConfig *)limitConfig
{
    BOOL hasError = NO;
    if(!imageData || [info objectForKey:PHImageErrorKey] || ![AWECustomStickerImageProcessor supportCustomStickerForDataUTI:dataUTI isImageAlbumEdit:self.repository.repoImageAlbumInfo.isImageAlbumEdit]) {
        hasError = YES;
        [ACCToast() showError:ACCLocalizedString(@"creation_edit_sticker_upload_toast6",@"To continue, use images that match the format")];
        [self.loadingView dismiss];
    }

    if([dataUTI isEqualToString:(id)kUTTypeGIF]) {
        CGFloat size = (CGFloat)imageData.length/(CGFloat)(1024*1024);
        if(size > limitConfig.gifMaxLimit || size > limitConfig.gifSizeLimit) {
            hasError = YES;
            NSString *format = ACCLocalizedString(@"creation_edit_sticker_upload_toast",@"Select image up to %@ MB");
            [ACCToast() showError:[NSString stringWithFormat:format,@(limitConfig.gifSizeLimit).stringValue]];
            [self.loadingView dismiss];
        }
    }
    return hasError;
}

#pragma mark - Track
- (void)trackForEnterCustomStickerEvent:(NSString *)event extraParams:(NSDictionary *)extraParams
{
    NSMutableDictionary *params = @{
        @"enter_from":@"video_edit_page",
        @"shoot_way":self.publishModel.repoTrack.referString?:@"",
        @"creation_id":self.publishModel.repoContext.createId ?:@"",
        @"content_source":self.publishModel.repoTrack.referExtra[@"content_source"]?:@"",
        @"content_type":self.publishModel.repoTrack.referExtra[@"content_type"]?:@"",
    }.mutableCopy;
    if(extraParams) {
        [params addEntriesFromDictionary:extraParams];
    }
    [ACCTracker() trackEvent:event params:params.copy needStagingFlag:NO];
}

#pragma mark - getter,should optimize

-(id <UIViewControllerTransitioningDelegate,ACCInteractiveTransitionProtocol>)transitionDelegate
{
    if (!_transitionDelegate) {
        _transitionDelegate = [IESAutoInline(self.serviceProvider, ACCTransitioningDelegateProtocol) modalTransitionDelegate];
    }
    return _transitionDelegate;
}

- (id <UIViewControllerTransitioningDelegate>)nextTranslationTransitionDelegate
{
    if (!_nextTranslationTransitionDelegate) {
        _nextTranslationTransitionDelegate = [IESAutoInline(self.serviceProvider, ACCTransitioningDelegateProtocol) modalLikePushTransitionDelegate];
    }
    return _nextTranslationTransitionDelegate;
}

- (AWEVideoPublishViewModel *)publishModel
{
    return self.viewModel.inputData.publishModel;
}

- (ACCCustomStickerViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCCustomStickerViewModel.class];
    }
    return _viewModel;
}

#pragma mark - ACCDraftResourceRecoverProtocol

+ (NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    return @[];
}

+ (void)regenerateTheNecessaryResourcesForPublishViewModel:(AWEVideoPublishViewModel *)publishModel completion:(ACCDraftRecoverCompletion)completion
{
    ACCBLOCK_INVOKE(completion, nil, NO);
}

@end

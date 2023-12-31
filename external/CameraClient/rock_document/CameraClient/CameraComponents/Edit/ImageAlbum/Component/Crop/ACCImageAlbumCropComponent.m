//
//  ACCImageAlbumCropComponent.m
//  Indexer
//
//  Created by admin on 2021/11/8.
//

#import "ACCImageAlbumCropComponent.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitInfra/ACCResponder.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

#import "ACCEditImageAlbumMixedProtocolD.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCEditBarItemExtraData.h"
#import "ACCEditTRToolBarContainer.h"
#import "ACCBarItem+Adapter.h"
#import "ACCVideoEditToolBarDefinition.h"
#import "ACCImageAlbumCropViewController.h"
#import "ACCImageAlbumData.h"
#import "ACCImageAlbumCropViewModel.h"
#import "ACCImageAlbumCropServiceProtocol.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCImageAlbumItemBaseResourceModel.h"
#import "AWERepoPublishConfigModel.h"

@interface ACCImageAlbumCropComponent () <ACCEditImageAlbumMixedMessageProtocolD>

@property (nonatomic, strong) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, strong) ACCImageAlbumCropViewModel *viewModel;

@property (nonatomic, strong) ACCImageAlbumItemModel *currentImageItemModel;
@property (nonatomic, assign) NSInteger currentImageEditorIndex;

@property (nonatomic, copy) NSDictionary *commonTrackParams;

@end

@implementation ACCImageAlbumCropComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)

- (void)componentDidMount
{
    if (!self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
        NSAssert(NO, @"should not added for video edit mode");
        return;
    }
    [self.viewContainer addToolBarBarItem:[self p_cropBarItem]];
    
    self.currentImageItemModel = self.editService.imageAlbumMixed.currentImageItemModel;
    self.currentImageEditorIndex = self.editService.imageAlbumMixed.currentImageEditorIndex;
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCImageAlbumCropServiceProtocol),
                                   self.viewModel);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.editService.imageAlbumMixed addSubscriber:self];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - Private

- (ACCBarItem<ACCEditBarItemExtraData *> *)p_cropBarItem
{
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarCropImageContext];
    if (!config) return nil;
    ACCBarItem<ACCEditBarItemExtraData*>* barItem = [[ACCBarItem alloc] init];
    barItem.title = config.title;
    barItem.imageName = config.imageName;
    barItem.location = config.location;
    barItem.itemId = ACCEditToolBarCropImageContext;
    barItem.type = ACCBarItemFunctionTypeCover;
    
    @weakify(self);
    barItem.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        [self p_clickedCropBarItem];
    };
    barItem.needShowBlock = ^BOOL{
        return YES;
    };
    barItem.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeCrop];
    return barItem;
}

- (void)p_clickedCropBarItem
{
    [self p_trackClickCropBarItem];
    
    // 进入裁切页面会自动触发 stopAutoPlayWithKey:@"viewAppear"，退出裁切页面会自动 startAutoPlayWithKey:@"viewAppear"（但点击对话框的继续按钮进入裁切页再出来时 start 没生效）
    BOOL noStickers = self.stickerService.stickerCount == 0;
    BOOL noTagStickers = self.stickerService.independentStickersCount == 0;
    // 如果到发布页更改了封面信息，则要先清除封面信息后才能再裁切
    BOOL hasCoverInfo = self.repository.repoPublishConfig.coverTextModel != nil || self.repository.repoPublishConfig.coverTextImage != nil;
    
    if (noStickers && noTagStickers && !hasCoverInfo) {
        [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) stopAutoPlayWithKey:@"cropAlertOrPage"];
        [self p_jumpToCropVC];
        return;
    }
    
    [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) stopAutoPlayWithKey:@"cropAlertOrPage"];
    @weakify(self);
    [ACCAlert() showAlertWithTitle:nil
                       description:@"已添加的效果和封面会被清除，是否继续裁切图片？"
                             image:nil
                 actionButtonTitle:@"继续"
                 cancelButtonTitle:@"取消"
                       actionBlock:^{
        @strongify(self);
        [self p_removeStickers];
        [self p_jumpToCropVC];
    } cancelBlock:^{
        @strongify(self);
        [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) startAutoPlayWithKey:@"cropAlertOrPage"];
    }];
}

- (void)p_removeStickers
{
    [self.stickerService.stickerContainer removeAllStickerViews];
    [self.currentImageItemModel.stickerInfo removeAllStickers];
    
    // 清空封面信息
    self.repository.repoImageAlbumInfo.dynamicCoverIndex = 0;
    self.repository.repoPublishConfig.coverTextModel = nil;
    self.repository.repoPublishConfig.coverTextImage = nil;
}

- (void)p_jumpToCropVC
{
    @weakify(self);
    ACCImageAlbumCropViewController *cropVC = [ACCImageAlbumCropViewController.alloc initWithData:self.currentImageItemModel
                                                                                commonTrackParams:self.commonTrackParams
                                                                                     confirmBlock:^(ACCImageAlbumItemCropInfo *cropInfo) {
        @strongify(self);
        [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) startAutoPlayWithKey:@"cropAlertOrPage"];
        [self p_confirmCrop:cropInfo forData:self.currentImageItemModel];
    } cancelBlock:^{
        @strongify(self);
        [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) startAutoPlayWithKey:@"cropAlertOrPage"];
        [self p_reloadCurrentImage:self.currentImageItemModel];
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:cropVC];
    nav.modalPresentationStyle = UIModalPresentationCustom;
    nav.modalPresentationCapturesStatusBarAppearance = YES;
    [[ACCResponder topViewController] presentViewController:nav animated:YES completion:nil];
}
/**
 1、命中进编辑页默认裁切：
    a、进入编辑页前，就会存储一份儿备份图 backupImageInfo，图片资源和图片路径都是独立的；
    b、确认裁切时，直接将裁切后的图片更新掉 originalImageInfo 即可（图片资源、图片宽高）；
 2、没命中进编辑页默认裁切：
    a、进入编辑页前，不会单独保存一份儿备份图，backupImageInfo 的信息和 originalImageInfo 一致（图片资源、图片路径、图片宽高）；
    b、进入裁切页时实际上取到的就是原图；
    3、确认裁切时先把原图备份（即更新 backupImageInfo，包括图片资源、图片路径），然后把裁切图更新到 originalImageInfo；
 */
// 没命中进编辑页默认裁切：没有提前存备份图（二次裁切时已经备份过了）
- (void)p_confirmCrop:(ACCImageAlbumItemCropInfo *)cropInfo forData:(ACCImageAlbumItemModel *)imageAlbumItem
{
    // 1、拿到原图准备裁切；
    NSString *backupImageFilePath = [self p_backupImageFilePath];
    UIImage *backupImage = [UIImage imageWithContentsOfFile:backupImageFilePath];
    
    // 2、如果备份图不存在（没有命中进编辑页默认裁切 或 没有裁切过），则将原图进行备份；
    NSString *originalImageFilePath = [self p_originalImageFilePath];
    if (!backupImage) {
        UIImage *originalImage = [UIImage imageWithContentsOfFile:originalImageFilePath];
        backupImage = originalImage;
        
        [self p_saveImage:originalImage toFile:backupImageFilePath];
        [imageAlbumItem.backupImageInfo setAbsoluteFilePath:backupImageFilePath];
        imageAlbumItem.backupImageInfo.width = imageAlbumItem.originalImageInfo.width;
        imageAlbumItem.backupImageInfo.height = imageAlbumItem.originalImageInfo.height;
    }
    
    // 3、对原图（备份图肯定是原图）进行裁切；
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(cropInfo.cropRect.size.width, cropInfo.cropRect.size.height), NO, backupImage.scale);
    [backupImage drawAtPoint:CGPointMake(-cropInfo.cropRect.origin.x, -cropInfo.cropRect.origin.y)];
    UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 4、将裁切后的图片资源保存到 originalImageInfo，并更新宽高信息；
    [self p_saveImage:croppedImage toFile:originalImageFilePath];
    imageAlbumItem.originalImageInfo.width = cropInfo.cropRect.size.width;
    imageAlbumItem.originalImageInfo.height = cropInfo.cropRect.size.height;
    
    // 5、刷新；
    [self p_reloadCurrentImage:imageAlbumItem];
}

/**
 1、命中进编辑页默认裁切，会提前保存一份备份图，路径也是独立的，可以通过 backupImageInfo.getAbsoluteFilePath 直接取出（但是从旧版本升级过来后从草稿恢复，则无法取到）
 2、没命中进编辑页默认裁切，确认裁切时要存一份备份图；
 */
- (NSString *)p_backupImageFilePath
{
    NSInteger index = self.currentImageEditorIndex;
    NSString *rootOutputFolderPath =  [AWEDraftUtils generateDraftFolderFromTaskId:self.repository.repoDraft.taskID];
    NSString *backupImageFilePath = [rootOutputFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"imageAlbum-backup-images-%@", @(index)]];
    return backupImageFilePath;
}

- (NSString *)p_originalImageFilePath
{
    NSString *filePath = [self.currentImageItemModel.originalImageInfo getAbsoluteFilePath];
    if (ACC_isEmptyString(filePath) || ![NSFileManager.defaultManager fileExistsAtPath:filePath]) {
        AWELogToolError(AWELogToolTagEdit, @"ACCImageAlbumCropComponent: get original image failed");
    }
    return filePath;
}

- (void)p_saveImage:(UIImage *)image toFile:(NSString *)filePath
{
    NSInteger index = self.currentImageEditorIndex;
    NSError *writeError = nil;
    NSData *imageData = UIImagePNGRepresentation(image);
    BOOL writeSuccess = [imageData acc_writeToFile:filePath options:NSDataWritingAtomic error:&writeError];
    if (writeSuccess) {
        AWELogToolInfo(AWELogToolTagImport, @"ACCImageAlbumCropComponent: save image succeed at index:%@", @(index));
    } else {
        AWELogToolError(AWELogToolTagImport, @"ACCImageAlbumCropComponent: save image faild at index:%@", @(index));
    }
}

- (void)p_reloadCurrentImage:(ACCImageAlbumItemModel *)imageAlbumItem
{
    [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) markCurrentImageNeedReload];
    [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) reloadData];
}

#pragma mark - ACCEditImageAlbumMixedMessageProtocolD

- (void)onImagePlayerWillScrollToIndex:(NSInteger)targetIndex
                         withAnimation:(BOOL)withAnimation
                         isByAutoTimer:(BOOL)isByAutoTimer
{
    // 刚自动划到下一张图片时，currentImageItemModel 是在 didUpdateCurrentIndex 时才会更新，此时进入裁切页拿到的图片还是原来的，不符合预期
    // 所以在 willScrollToIndex 时就提前更新好，等 didUpdateCurrentIndex 时再次更新是因为如果手动滑动的话，willScrollToIndex 不回调的话 currentImageItemModel 就得不到更新
    ACCImageAlbumItemModel *currentImageItemModel = [self.repository.repoImageAlbumInfo.imageAlbumData.imageAlbumItems acc_objectAtIndex:targetIndex];
    if (currentImageItemModel) {
        self.currentImageEditorIndex = targetIndex;
        self.currentImageItemModel = currentImageItemModel;
    }
}

- (void)onCurrentImageEditorChanged:(NSInteger)currentIndex isByAutoTimer:(BOOL)isByAutoTimer
{
    self.currentImageItemModel = self.editService.imageAlbumMixed.currentImageItemModel;
    self.currentImageEditorIndex = self.editService.imageAlbumMixed.currentImageEditorIndex;
}

#pragma mark - Track

- (void)p_trackClickCropBarItem
{
    [ACCTracker() trackEvent:@"click_cut_entrance" params:self.commonTrackParams];
}

- (NSDictionary *)commonTrackParams
{
    return @{@"shoot_way": self.repository.repoTrack.referString ?: @"",
             @"creation_id": self.repository.repoContext.createId ?: @"",
             @"content_source": self.repository.repoTrack.contentSource ?: @"",
             @"content_type": self.repository.repoTrack.referExtra[@"content_type"] ?: @"",
             @"is_multi_content": @"1",
             @"pic_cnt": @(self.editService.imageAlbumMixed.totalImagePlayerImageCount),
             @"pic_location": @(self.currentImageEditorIndex + 1)};
}

#pragma mark - Getter

- (ACCImageAlbumCropViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCImageAlbumCropViewModel.class];
        NSAssert(_viewModel, @"should not be nil");
    }
    return _viewModel;
}

@end

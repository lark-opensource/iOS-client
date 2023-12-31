//
//  ACCNewYearWishModuleEditView.m
//  Aweme
//
//  Created by 卜旭阳 on 2021/11/2.
//

#import "ACCNewYearWishModuleEditView.h"
#import "ACCStickerPreviewCollectionViewCell.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCColorNameDefines.h>
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import <CreativeAlbumKit/CAKAlbumViewController.h>

#import <EffectPlatformSDK/EffectPlatform+Additions.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/UIImage+BTDAdditions.h>
#import <ByteDanceKit/BTDResponder.h>

#import "ACCSelectAlbumAssetsProtocol.h"
#import "ACCAlbumInputData.h"
#import "ACCViewControllerProtocol.h"
#import "AWEVideoRecordOutputParameter.h"
#import "ACCConfigKeyDefines.h"
#import "ACCTransitioningDelegateProtocol.h"
#import "ACCEditActivityDataHelperProtocol.h"
#import "ACCStickerPlayerApplying.h"

#import "ACCRepoActivityModel.h"
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoMVModel.h>
#import <CreativeKit/ACCMonitorProtocol.h>

@interface ACCNewYearWishCoverView : UIView

@property (nonatomic, strong) UIImageView *addIcon;
@property (nonatomic, strong) UIImageView *mainImageView;
@property (nonatomic, strong) UIView *coverView;

@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation ACCNewYearWishCoverView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    UIImageView *mainImageView = [[UIImageView alloc] init];
    mainImageView.contentMode = UIViewContentModeScaleAspectFill;
    mainImageView.backgroundColor = ACCResourceColor(ACCColorConstBGContainer5);
    mainImageView.layer.masksToBounds = YES;
    mainImageView.layer.cornerRadius = 2.f;
    [self addSubview:mainImageView];
    ACCMasMaker(mainImageView, {
        make.left.right.top.equalTo(self);
        make.height.equalTo(@(86.f));
    });
    self.mainImageView = mainImageView;
    
    UIImageView *addIcon = [[UIImageView alloc] init];
    addIcon.image = ACCResourceImage(@"pixaloop_icon_upload");
    addIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:addIcon];
    ACCMasMaker(addIcon, {
        make.center.equalTo(mainImageView);
        make.width.height.equalTo(@(20.f));
    });
    self.addIcon = addIcon;
    
    UIView *coverView = [[UIView alloc] init];
    coverView.backgroundColor = ACCResourceColor(ACCColorConstBGInverse2);
    coverView.layer.masksToBounds = YES;
    coverView.layer.cornerRadius = 2.f;
    coverView.layer.borderWidth = 2.f;
    [self addSubview:coverView];
    ACCMasMaker(coverView, {
        make.left.right.top.equalTo(self);
        make.height.equalTo(@(86.f));
    });
    coverView.hidden = YES;
    self.coverView = coverView;
    
    UIImageView *coverImageView = [[UIImageView alloc] init];
    coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    coverImageView.image = ACCResourceImage(@"beauty_primary_edit_mode");
    [coverView addSubview:coverImageView];
    ACCMasMaker(coverImageView, {
        make.center.equalTo(coverView);
        make.width.height.equalTo(@(40.f));
    });
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"上传背景";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont acc_systemFontOfSize:12.f weight:ACCFontWeightRegular];
    titleLabel.textColor = [UIColor whiteColor];
    [self addSubview:titleLabel];
    ACCMasMaker(titleLabel, {
        make.height.equalTo(@(17.f));
        make.bottom.equalTo(self);
        make.left.right.equalTo(self);
    });
    self.titleLabel = titleLabel;
}

- (void)updateWithImage:(UIImage *)image
{
    if (image) {
        self.addIcon.hidden = YES;
        self.coverView.hidden = NO;
        self.mainImageView.image = image;
        self.titleLabel.text = @"点击编辑";
        self.coverView.layer.borderColor = ACCResourceColor(ACCColorPrimary).CGColor;
    } else {
        self.addIcon.hidden = NO;
        self.coverView.hidden = YES;
        self.mainImageView.image = nil;
        self.titleLabel.text = @"上传背景";
        self.coverView.layer.borderColor = [UIColor clearColor].CGColor;
    }
}

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return @"上传背景";
}

@end

@interface ACCNewYearWishPreviewCollectionViewCell : ACCStickerPreviewCollectionViewCell

@end

@implementation ACCNewYearWishPreviewCollectionViewCell

- (void)setupUI
{
    [super setupUI];
    ACCMasReMaker(self.iconImageView, {
        make.centerX.equalTo(self);
        make.top.equalTo(@0);
        make.width.equalTo(@(64.f));
        make.height.equalTo(@(86.f));
    });
    self.iconImageView.layer.cornerRadius = 2.f;
}

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.titleLabel.text;
}

@end

/************************************************************/

@interface ACCNewYearWishModuleEditView()<UICollectionViewDelegate, UICollectionViewDataSource>
// Basic View
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIVisualEffectView *panelView;
@property (nonatomic, strong) ACCNewYearWishCoverView *coverView;
@property (nonatomic, strong) UICollectionView *collectionView;
// Edit
@property (nonatomic, weak) CAKAlbumViewController *albumVC;
@property (nonatomic, weak) UIView<ACCLoadingViewProtocol> *loadingView;
@property (nonatomic, weak) id<UIViewControllerTransitioningDelegate, ACCInteractiveTransitionProtocol> transitionDelegate;
// Data
@property (nonatomic, copy) NSArray<IESEffectModel *> *models;
@property (nonatomic, strong) ACCEditMVModel *mvModel;
@property (nonatomic, strong) ACCNewYearWishEditModel *wishModel;
// Temp Status
@property (nonatomic, copy) NSString *currentPickerId;
@property (nonatomic, copy) NSString *downloadingEffectId;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) BOOL enableSwitch;

@property (nonatomic, assign) BOOL moduleChanged;

@end

@implementation ACCNewYearWishModuleEditView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        _currentIndex = NSNotFound;
        _enableSwitch = YES;
    }
    return self;
}

- (void)setupUI
{
    UIView *backView = [[UIView alloc] init];
    [self addSubview:backView];
    [backView acc_addSingleTapRecognizerWithTarget:self action:@selector(p_dismiss)];
    ACCMasMaker(backView, {
        make.edges.equalTo(self);
    });
    self.backView = backView;
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *panelView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    panelView.clipsToBounds = YES;
    panelView.frame = CGRectMake(0.f, self.acc_height, ACC_SCREEN_WIDTH, 225.f);
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.f, 0.f, ACC_SCREEN_WIDTH, 225.f) byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(12.f, 12.f)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.path = bezierPath.CGPath;
    panelView.layer.mask = maskLayer;
    [self addSubview:panelView];
    self.panelView = panelView;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"热门模板";
    titleLabel.font = [UIFont acc_systemFontOfSize:15.f weight:ACCFontWeightMedium];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [panelView.contentView addSubview:titleLabel];
    ACCMasMaker(titleLabel, {
        make.top.equalTo(@20.f);
        make.left.right.equalTo(self);
        make.height.equalTo(@18.f);
    });
    
    ACCNewYearWishCoverView *coverView = [[ACCNewYearWishCoverView alloc] init];
    [ACCAccessibility() enableAccessibility:coverView traits:UIAccessibilityTraitButton label:@"上传背景"];
    coverView.userInteractionEnabled = YES;
    [coverView acc_addSingleTapRecognizerWithTarget:self action:@selector(p_checkAlbum)];
    [panelView.contentView addSubview:coverView];
    ACCMasMaker(coverView, {
        make.left.equalTo(@16.f);
        make.top.equalTo(titleLabel.mas_bottom).offset(32.5);
        make.width.equalTo(@64.f);
        make.height.equalTo(@111.f);
    });
    self.coverView = coverView;
    
    UIView *splitView = [[UIView alloc] init];
    splitView.backgroundColor = ACCResourceColor(ACCColorConstLineInverse);
    [panelView.contentView addSubview:splitView];
    ACCMasMaker(splitView, {
        make.left.equalTo(coverView.mas_right).offset(15.f);
        make.centerY.equalTo(coverView).offset(-12.f);
        make.width.equalTo(@1.f);
        make.height.equalTo(@72.f);
    });
    
    // Content scrollview
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 12.f;
    layout.itemSize = CGSizeMake(64.f, 110.f);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.delegate = self;
    collectionView.dataSource = self;
    [panelView.contentView addSubview:collectionView];
    ACCMasMaker(collectionView, {
        make.left.equalTo(splitView.mas_right).offset(15.f);
        make.right.equalTo(@0);
        make.top.equalTo(coverView.mas_top);
        make.height.equalTo(@111.f);
    });
    self.collectionView = collectionView;

    [collectionView registerClass:[ACCNewYearWishPreviewCollectionViewCell class] forCellWithReuseIdentifier:[ACCNewYearWishPreviewCollectionViewCell identifier]];
    
    [self layoutIfNeeded];
}

- (void)performAnimation:(BOOL)show
{
    if (show) {
        self.panelView.acc_top = self.acc_height;
        self.backView.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.panelView.acc_bottom = self.acc_height;
        } completion:^(BOOL finished) {
            self.backView.userInteractionEnabled = YES;
        }];
        [self p_configCoverImage];
        [self fetchBGVideoEffects];
    } else {
        self.enableSwitch = NO;
        self.backView.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.panelView.acc_top = self.acc_height;
        } completion:^(BOOL finished) {
            ACCBLOCK_INVOKE(self.dismissBlock);
        }];
    }
}

- (void)setPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    _publishModel = publishModel;
    _wishModel = publishModel.repoActivity.wishModel;
}

#pragma mark - Private
- (void)fetchBGVideoEffects
{
    @weakify(self);
    EffectPlatformFetchListCompletionBlock completionBlock = ^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
        @strongify(self);
        if (!error && response.effects.count) {
            self.models = response.effects;
            self.collectionView.hidden = NO;
            [self.collectionView reloadData];
        } else {
            self.models = nil;
            self.collectionView.hidden = YES;
            [self.collectionView reloadData];
        }
        [self.models enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.effectIdentifier isEqualToString:self.wishModel.effectId]) {
                self.currentIndex = idx;
                *stop = YES;
            }
        }];
        if (self.currentIndex < self.models.count) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        }
    };

    IESEffectPlatformResponseModel *responseModel = [EffectPlatform cachedEffectsOfPanel:ACCNewYearWishModuleLokiKey];
    BOOL hasValidCache = responseModel.effects.count > 0;
    [EffectPlatform checkEffectUpdateWithPanel:ACCNewYearWishModuleLokiKey effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        if (!needUpdate && hasValidCache) {
            ACCBLOCK_INVOKE(completionBlock, nil, responseModel);
        } else {
            [EffectPlatform downloadEffectListWithPanel:ACCNewYearWishModuleLokiKey completion:completionBlock];
        }
    }];
}

- (void)p_checkAlbum
{
    if ([ACCDeviceAuth isiOS14PhotoNotDetermined]) {
        [self p_showAlbum];
    } else {
        [ACCDeviceAuth requestPhotoLibraryPermission:^(BOOL success) {
            if (success) {
                [self p_showAlbum];
            } else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message: @"相册权限被禁用，请到设置中授予抖音允许访问相册权限" preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    });
                }]];
                [alertController addAction:[UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil]];
                [ACCAlert() showAlertController:alertController animated:YES];
            }
        }];
    }
    ACCBLOCK_INVOKE(self.onTrackEvent, @"click_yd_upload_wish_background", @{
        @"enter_method" : @"click_add_button"
    });
}

- (void)p_showAlbum
{
    ACCAlbumInputData *inputData = [[ACCAlbumInputData alloc] init];
    inputData.originUploadPublishModel = self.publishModel;
    inputData.vcType = ACCAlbumVCTypeForWish;
    inputData.minAssetsSelectionCount = 1;
    inputData.maxAssetsSelectionCount = 1;
    inputData.enableMultiSelect = NO;
    inputData.enablePreview = NO;
    inputData.shouldHideSelectedAssetsViewWhenNotSelect = NO;
    @weakify(self);
    inputData.selectAssetsCompletion = ^(NSArray<AWEAssetModel *> * _Nullable assets) {
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            [self p_processSelectedImages:assets];
        });
    };
    inputData.dismissBlock = ^{
        @strongify(self);
        [self.player play];
    };
    
    CAKAlbumViewController *resourcePickerViewController  = [IESAutoInline(ACCBaseServiceProvider(), ACCSelectAlbumAssetsProtocol) albumViewControllerWithInputData:inputData];
    UINavigationController *navigationController = [ACCViewControllerService() createCornerBarNaviControllerWithRootVC:resourcePickerViewController];
    navigationController.navigationBar.translucent = NO;
    navigationController.modalPresentationCapturesStatusBarAppearance = YES;
    navigationController.modalPresentationStyle = UIModalPresentationCustom;
    navigationController.transitioningDelegate = self.transitionDelegate;
    self.transitionDelegate.swipeInteractionController.forbidSimultaneousScrollViewPanGesture = YES;
    [self.transitionDelegate.swipeInteractionController wireToViewController:navigationController.topViewController];
    [[BTDResponder topViewController] presentViewController:navigationController animated:YES completion:nil];
    self.albumVC = resourcePickerViewController;
    [self.player pause];
}

- (void)p_processSelectedImages:(NSArray<AWEAssetModel *> *)assets
{
    const CGSize imageSize = [AWEVideoRecordOutputParameter maximumImportCompositionSize];
    NSDictionary *karaokeConfigs = ACCConfigDict(kConfigDict_karaoke_basic_configs);
    CGFloat maxWidth = [karaokeConfigs btd_floatValueForKey:@"image_max_width"];
    CGFloat maxHeight = [karaokeConfigs btd_floatValueForKey:@"image_max_height"];
    CGSize maxExportSize = maxWidth > 0 && maxHeight > 0 ? CGSizeMake(maxWidth, maxHeight) : CGSizeMake(1080, 1920);
    
    NSString *pickId = [NSUUID UUID].UUIDString;
    NSString *folderPath = [AWEDraftUtils generatePathFromTaskId:self.publishModel.repoDraft.taskID name:pickId];
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    self.loadingView = [ACCLoading() showLoadingOnView:self.albumVC.view];
    
    @weakify(self);
    AWEAssetModel *assetModel = assets.firstObject;
    [CAKPhotoManager getUIImageWithPHAsset:assetModel.asset imageSize:imageSize networkAccessAllowed:YES progressHandler:^(CGFloat progress, NSError *error, BOOL *stop, NSDictionary *info) {
        
        } completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if (isDegraded) {
                return;
            }
            NSString *filePath = [folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"wishimage.png"]];// 绝对路径
            CGSize maxSize = (photo.size.width > photo.size.height) ? CGSizeMake(maxExportSize.height, maxExportSize.width) : maxExportSize;
            if (photo.size.width > maxSize.width || photo.size.height > maxSize.height) {
                CGFloat compressRatio = MAX(photo.size.width / maxSize.width, photo.size.height / maxSize.height);
                photo = [UIImage btd_compressImage:photo withTargetSize:CGSizeMake(photo.size.width / compressRatio, photo.size.height / compressRatio)];
            }
            NSData *imageData = UIImagePNGRepresentation(photo);
            [imageData writeToFile:filePath atomically:YES];
            acc_dispatch_main_async_safe(^{
                @strongify(self);
                [self.loadingView dismiss];
                [self p_removeImagesForPickerId:self.currentPickerId];
                self.currentPickerId = pickId;
                [self.albumVC.currentListViewController dismissViewControllerAnimated:NO completion:nil];
                [self.albumVC dismissViewControllerAnimated:YES completion:nil];
                if (filePath) {
                    NSString *relativePath = [NSString stringWithFormat:@"%@/wishimage.png",pickId];
                    [self p_audioBGDidEdit:nil image:relativePath asset:assetModel index:NSNotFound];
                }
            });
    }];
    ACCBLOCK_INVOKE(self.onTrackEvent, @"choose_yd_upload_wish_background", @{
        @"enter_method" : @"click_next_button"
    });
}

- (void)p_audioBGDidEdit:(IESEffectModel *)effect image:(NSString *)imagePath asset:(AWEAssetModel *)asset index:(NSInteger)index
{
    NSString *resourcePath = nil;
    BOOL isImage = imagePath.length && asset;
    let dataHelper = [IESAutoInline(ACCBaseServiceProvider(), ACCNewYearWishDataHelperProtocol) class];
    if (effect) {
        resourcePath = [dataHelper fetchVideoFileInFolder:effect.filePath];
    } else if (isImage) {
        resourcePath = [AWEDraftUtils generatePathFromTaskId:self.publishModel.repoDraft.taskID name:imagePath];
    } else {
        [ACCToast() show:@"背景切换失败，请重试" onView:self];
        return;
    }
    
    @weakify(self);
    self.mvModel = [dataHelper generateWishMVDataWithResource:resourcePath repository:self.publishModel videoData:self.player.videoData isImage:isImage completion:^(BOOL success, NSError *error, ACCEditVideoData *result) {
        @strongify(self);
        if (!error && result && success) {
            self.wishModel.effectId = isImage ? nil : effect.effectIdentifier;
            self.wishModel.imageModels = asset ? @[asset] : nil;
            self.wishModel.images = imagePath ? @[imagePath] : nil;
            self.currentIndex = index;
            self.moduleChanged = !isImage;
            [self p_configCoverImage];
            [self.player updateVideoData:result mvModel:self.mvModel completeBlock:^(NSError * _Nullable error) {
                @strongify(self);
                if (!error) {
                    [self.player seekToTimeAndRender:kCMTimeZero completionHandler:^(BOOL finished) {
                        @strongify(self);
                        [self.player play];
                    }];
                    [self.publishModel.repoVideoInfo updateVideoData:result];
                    self.publishModel.repoActivity.mvModel = self.mvModel;
                    self.publishModel.repoMV.templateMaterials = self.wishModel.images;
                    ACCBLOCK_INVOKE(self.onModuleSelected, effect.effectIdentifier, index);
                }
            }];
            [self.collectionView reloadData];
            if (self.currentIndex < self.models.count) {
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
            }
        } else {
            [ACCToast() show:@"背景切换失败，请重试" onView:self];
        }
    }];
}

- (void)p_removeImagesForPickerId:(NSString *)pickerId
{
    if (!pickerId.length) {
        return;
    }
    NSString *oldFolderPath = [AWEDraftUtils generatePathFromTaskId:self.publishModel.repoDraft.taskID name:pickerId];
    [[NSFileManager defaultManager] removeItemAtPath:oldFolderPath error:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSFileManager defaultManager] removeItemAtPath:oldFolderPath error:nil];
    });
}

- (void)p_configCoverImage
{
    NSString *coverImagePath = [AWEDraftUtils generatePathFromTaskId:self.publishModel.repoDraft.taskID name:self.wishModel.images.firstObject];
    UIImage *coverImage = [UIImage imageWithContentsOfFile:coverImagePath];
    [self.coverView updateWithImage:coverImage];
}

- (void)p_dismiss
{
    if (self.moduleChanged) {
        ACCBLOCK_INVOKE(self.onTrackEvent, @"choose_yd_wish_background_confirm", @{
            @"background_type" : @"system",
            @"enter_method" : @"click_outside",
            @"background_id" : self.wishModel.effectId ? : @""
        });
    }
    [self performAnimation:NO];
}

#pragma mark - Getter
- (id <UIViewControllerTransitioningDelegate,ACCInteractiveTransitionProtocol>)transitionDelegate
{
    if (!_transitionDelegate) {
        _transitionDelegate = [IESAutoInline(ACCBaseServiceProvider(), ACCTransitioningDelegateProtocol) modalTransitionDelegate];
    }
    return _transitionDelegate;
}

#pragma mark - Delegate & Datasource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCNewYearWishPreviewCollectionViewCell *wishCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:[ACCNewYearWishPreviewCollectionViewCell identifier] forIndexPath:indexPath];
    IESEffectModel *effect = [self.models btd_objectAtIndex:indexPath.row];
    if (effect.downloaded) {
        effect.downloadStatus = AWEEffectDownloadStatusDownloaded;
    }
    [wishCell configCellWithEffect:effect];
    BOOL currentSelected = [effect.effectIdentifier isEqualToString:self.wishModel.effectId];
    [wishCell showCurrentTag:currentSelected];
    [wishCell updateDownloadStatus:effect.downloadStatus];
    return wishCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    IESEffectModel *effect = [self.models btd_objectAtIndex:indexPath.row];
    // 正在下载或者重复选择
    if ([effect.effectIdentifier isEqualToString:self.wishModel.effectId] || effect.downloadStatus == AWEEffectDownloadStatusDownloading) {
        return;
    }
    
    self.downloadingEffectId = effect.effectIdentifier;
    ACCStickerPreviewCollectionViewCell *wishCell = (ACCStickerPreviewCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [wishCell updateDownloadStatus:AWEEffectDownloadStatusDownloading];
    NSString *wishLoadTimeKey = @"aweme_wish_background_success_rate";
    
    [ACCMonitor() startTimingForKey:wishLoadTimeKey];
    @weakify(self);
    [EffectPlatform downloadEffect:effect downloadQueuePriority:NSOperationQueuePriorityHigh
          downloadQualityOfService:NSQualityOfServiceDefault progress:nil completion:^(NSError *error, NSString * filePath) {
        @strongify(self);
        if (![effect.effectIdentifier isEqualToString:self.downloadingEffectId] || !self.enableSwitch) {
            return;
        }
        self.downloadingEffectId = nil;
        if (!error && filePath) {
            [wishCell updateDownloadStatus:AWEEffectDownloadStatusDownloaded];
            [self p_audioBGDidEdit:effect image:nil asset:nil index:indexPath.row];
            [[EffectPlatform sharedInstance] saveCacheWithEffect:effect];
        } else {
            [wishCell updateDownloadStatus:AWEEffectDownloadStatusUndownloaded];
        }
        
        [ACCMonitor() trackService:wishLoadTimeKey status:error?1:0 extra:@{@"duration":@([ACCMonitor() timeIntervalForKey:wishLoadTimeKey]), @"error_desc":error.description?:@""}];
        [ACCMonitor() cancelTimingForKey:wishLoadTimeKey];
    }];
}

@end

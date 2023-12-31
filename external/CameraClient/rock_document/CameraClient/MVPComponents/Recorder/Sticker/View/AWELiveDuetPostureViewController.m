//
//  AWELiveDuetPostureViewController.m
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/1/14.
//

#import "AWELiveDuetPostureViewController.h"
#import <CreationKitArch/AWECameraContainerToolButtonWrapView.h>
#import "AWERecordDefaultCameraPositionUtils.h"
#import "AWELiveDuetPostureCollectionViewCell.h"
#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <CreativeKit/UIView+AWEStudioAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

const static CGFloat kAWELiveDuetPostureItemSpacing = 12;
const static CGFloat kAWELiveDuetPostureCollectionViewCellStandardHeight = 115;

@interface AWELiveDuetPostureViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *panelView;
@property (nonatomic, strong) UIVisualEffectView *blurView;

@property (nonatomic, strong) UIButton *swapCameraButton; // 摄像头按钮
@property (nonatomic, strong) AWECameraContainerToolButtonWrapView *cameraButtonWrapView;

@property (nonatomic, strong) NSString *renderImageKey;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, assign, readwrite) NSInteger selectedIndex;

// datasource
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, UIImage *> *imageDictionary;

@end

@implementation AWELiveDuetPostureViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _imageDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupUI];
    [self setupCameraButton];
}

- (void)setupUI
{
    self.view.backgroundColor = [UIColor clearColor];

    UIView *clearView = [[UIView alloc] init];
    [clearView setExclusiveTouch:YES];
    [self.view addSubview:clearView];

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClearBackgroundDidPressed:)];
    [clearView addGestureRecognizer:tapRecognizer];

    // Accessibility
    clearView.isAccessibilityElement = YES;
    clearView.accessibilityTraits = UIAccessibilityTraitButton;
    ACCMasMaker(clearView, {
        make.bottom.equalTo(self.view.mas_bottom).offset(-[self panelViewHeight]);
        make.top.equalTo(self.view.mas_top);
        make.left.equalTo(self.view.mas_left);
        make.width.equalTo(self.view.mas_width);
    });

    [self.view addSubview:self.panelView];
    [self.panelView setExclusiveTouch:YES];
    ACCMasMaker(self.panelView, {
        make.top.equalTo(clearView.mas_bottom);
        make.left.right.bottom.equalTo(self.view);
    });

    [self.panelView addSubview:self.blurView];
    ACCMasMaker(self.blurView, {
        make.edges.equalTo(self.panelView);
    });

    [self.panelView addSubview:self.titleLabel];
    ACCMasMaker(self.titleLabel, {
        make.height.equalTo(@(16));
        make.top.equalTo(self.panelView).offset(18);
        make.centerX.equalTo(self.panelView.mas_centerX);
    });

    UIView *lineView = [[UIView alloc] init];
    lineView.backgroundColor = ACCResourceColor(ACCColorLinePrimary);
    [self.panelView addSubview:lineView];
    ACCMasMaker(lineView, {
        make.left.right.equalTo(self.panelView);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(17.5);
        make.height.equalTo(@(0.5));
    });

    [self.panelView addSubview:self.collectionView];
    ACCMasMaker(self.collectionView, {
        make.top.equalTo(lineView);
        make.leading.equalTo(self.panelView.mas_leading);
        make.trailing.equalTo(self.panelView.mas_trailing);
        if (@available(iOS 11.0, *)) {
            make.bottom.lessThanOrEqualTo(self.view.mas_safeAreaLayoutGuideBottom);
        } else {
            make.bottom.lessThanOrEqualTo(self.view.mas_bottom);
        }
    });
}

- (void)setupCameraButton
{
    [self.view addSubview:self.cameraButtonWrapView];
    [self.swapCameraButton setExclusiveTouch:YES];
    CGFloat rightSpacing = 2;
    CGFloat featureViewHeight = 48;
    CGFloat featureViewWidth = [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5 ? 48.0 : 52;
    CGFloat buttonSpacing = [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5 ? 2.0 : 14.0;
    CGFloat buttonHeightWithSpacing = featureViewHeight + buttonSpacing;

    CGRect tempFrame = CGRectMake(6, 20, featureViewWidth, featureViewHeight);
    if ([UIDevice acc_isIPhoneX]) {
        if (@available(iOS 11.0, *)) {
            tempFrame = CGRectMake(6, ACC_STATUS_BAR_NORMAL_HEIGHT + 20, featureViewWidth, featureViewHeight);
        }
    }

    CGFloat topOffset = tempFrame.origin.y + 6.0; //6 is back button's image's edge
    CGFloat shift = [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5 ? 3 : 0;
    self.cameraButtonWrapView.frame = CGRectMake(ACC_SCREEN_WIDTH - rightSpacing - featureViewWidth + shift, topOffset, self.cameraButtonWrapView.acc_width, buttonHeightWithSpacing);
}

#pragma mark - Setup and Prepare UI Functions

- (void)showOnView:(UIView *)superview animated:(BOOL)animated completion:(void (^)(void))completion
{
    if (!superview) {
        ACCBLOCK_INVOKE(completion);
    }

    [superview addSubview:self.view];
    [superview bringSubviewToFront:self.view];

    if (animated) {
        [self p_moveToOffset:CGPointMake(0, superview.bounds.size.height)];
        [UIView animateWithDuration:0.49 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self p_moveToOffset:CGPointZero];
        } completion:^(BOOL finished) {
            // 让新增加的Camera按钮显示
            self.cameraButtonWrapView.hidden = NO;
            self.swapCameraButton.selected = [self defaultPosition] == AVCaptureDevicePositionFront;
            ACCBLOCK_INVOKE(completion);
        }];
    } else {
        [self p_moveToOffset:CGPointZero];
        ACCBLOCK_INVOKE(completion);
    }
}

- (void)onClearBackgroundDidPressed:(UITapGestureRecognizer *)gesture
{
    ACCBLOCK_INVOKE(self.dismissBlock);
    [self dismissWithAnimated:YES duration:0.25];
}

- (void)dismissWithAnimated:(BOOL)animated duration:(NSTimeInterval)duration {
    if (!self.view.superview) {
        return;
    }

    [self p_prepareForDismiss];
    @weakify(self)
    dispatch_block_t removeFromParentBlock = ^{
        @strongify(self)
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    };

    if (animated) {
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            [self p_moveToOffset:CGPointMake(0, [UIScreen mainScreen].bounds.size.height)];
        } completion:^(BOOL finished) {
            ACCBLOCK_INVOKE(removeFromParentBlock);
        }];
    } else {
        [self p_moveToOffset:CGPointMake(0, [UIScreen mainScreen].bounds.size.height)];
        ACCBLOCK_INVOKE(removeFromParentBlock);
    }
}

# pragma mark - Prepare Data

- (void)prepareForImageDataWithFolderPath:(NSString *)imagesFolderPath
{
    NSError *error = nil;
    NSArray<NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:imagesFolderPath error:&error];
    if (error) {
        AWELogToolError(AWELogToolTagRecord, @"AWELiveDuetPostureViewController contentsOfDirectoryAtPath failed: %@ %s %@", __PRETTY_FUNCTION__, error);
        return;
    }
    for (NSString *content in contents) {
        NSString *imagePath = [imagesFolderPath stringByAppendingPathComponent:content];
        if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
            UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
            if (image) {
                NSRange range = [content rangeOfString:@"lottery_"];
                if (range.location != NSNotFound) {
                    NSUInteger fromIndex = range.location + range.length;
                    NSString *key = [content substringFromIndex:fromIndex];
                    [self.imageDictionary btd_setObject:image forKey:key];
                }
            }
        }
    }
}

- (void)prepareForCameraService:(id<ACCCameraService>)cameraService
{
    self.cameraService = cameraService;
}

- (void)updateRenderImageKeyWithEffectModel:(IESEffectModel *)effectModel
{
    self.renderImageKey = [[effectModel pixaloopSDKExtra] acc_pixaloopImgK:@"pl"];
}

- (void)renderPicImageWithIndex:(NSInteger)selectedIndex
{
    self.selectedIndex = selectedIndex;
    self.swapCameraButton.selected = [self defaultPosition] == AVCaptureDevicePositionFront;
    NSString *key = [NSString stringWithFormat:@"%lu", (unsigned long)self.selectedIndex];
    [self.cameraService.effect renderPicImage:[self.imageDictionary acc_objectForKey:key] withKey:self.renderImageKey];
}

- (void)cameraButtonPressed:(UIButton *)button
{
    [button acc_counterClockwiseRotate];
    if( ACCConfigBool(kConfigInt_enable_camera_switch_haptic)){
        if(@available(ios 10.0, *)){
            UISelectionFeedbackGenerator *selection = [[UISelectionFeedbackGenerator alloc] init];
            [selection selectionChanged];
        }
    }
    [self.cameraService.cameraControl switchToOppositeCameraPosition];
}

- (AVCaptureDevicePosition)defaultPosition
{
    NSNumber *storedKey = [ACCCache() objectForKey:HTSVideoDefaultDevicePostionKey];
    if (storedKey != nil) {
        return [storedKey integerValue];
    } else {
        return AVCaptureDevicePositionFront;
    }
}

#pragma mark - UICollectionView

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    AWELiveDuetPostureCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[AWELiveDuetPostureCollectionViewCell identifier] forIndexPath:indexPath];

    NSString *key = [NSString stringWithFormat:@"%lu", (unsigned long)indexPath.item];
    [cell updateIconImage:[self.imageDictionary acc_objectForKey:key]];
    if (self.selectedIndex == indexPath.item) {
        [cell updateSelectedStatus:YES];
        NSString *key = [NSString stringWithFormat:@"%lu", (unsigned long)indexPath.item];
        [self.cameraService.effect renderPicImage:[self.imageDictionary acc_objectForKey:key] withKey:self.renderImageKey];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AWELiveDuetPostureCollectionViewCell *cell = (AWELiveDuetPostureCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    self.selectedIndex = indexPath.item;
    [self.delegate updateSelectedIndex:self.selectedIndex];

    UIImage *selectedImage = nil;
    if (cell.isCellSelected) {
        // 必须选择图片
        return;
    } else {
        [self p_clearSeletedCells];
        [cell updateSelectedStatus:YES];
        NSString *key = [NSString stringWithFormat:@"%lu", (unsigned long)indexPath.item];
        selectedImage = [self.imageDictionary acc_objectForKey:key];
    }
    [self.cameraService.effect renderPicImage:selectedImage withKey:self.renderImageKey];
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imageDictionary.count;
}

#pragma mark - Private Functions

- (void)p_moveToOffset:(CGPoint)offset {
    self.view.frame = CGRectMake(offset.x, offset.y, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)p_clearSeletedCells
{
    for (AWELiveDuetPostureCollectionViewCell *cell in [self.collectionView visibleCells]) {
        [cell updateSelectedStatus:NO];
    }
}

- (void)p_prepareForDismiss
{
    self.cameraButtonWrapView.hidden = YES;
}

#pragma mark - UI Size

- (CGFloat)panelViewHeight
{
    if ([UIDevice acc_isIPad]) {
        return 320;
    }
    // the image's size is taken into account when calculating the height of the panel view
    CGFloat diff = [self collectionViewCellHeight] - kAWELiveDuetPostureCollectionViewCellStandardHeight;
    return 207 + diff + ACC_IPHONE_X_BOTTOM_OFFSET;
}

- (CAShapeLayer *)topRoundCornerShapeLayerWithFrame:(CGRect)frame
{
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    CGFloat maskRadius = 8;
    shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:frame
                                            byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                  cornerRadii:CGSizeMake(maskRadius, maskRadius)].CGPath;
    return shapeLayer;
}

- (CGFloat)collectionViewCellHeight {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    if (screenWidth > 0) {
        return kAWELiveDuetPostureCollectionViewCellStandardHeight / 375.f * screenWidth;
    }
    return kAWELiveDuetPostureCollectionViewCellStandardHeight;
}

#pragma mark - UI

- (UIView *)panelView
{
    if (!_panelView) {
        _panelView = [[UIView alloc] init];
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGRect maskFrame = CGRectMake(0, 0, screenWidth, [self panelViewHeight]);
        _panelView.layer.mask = [self topRoundCornerShapeLayerWithFrame:maskFrame];
    }
    return _panelView;
}

- (UIVisualEffectView *)blurView
{
    if (!_blurView) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        _blurView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
    }
    return _blurView;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake([self collectionViewCellHeight], [self collectionViewCellHeight]);
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flowLayout.minimumLineSpacing = kAWELiveDuetPostureItemSpacing;

        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        [_collectionView registerClass:[AWELiveDuetPostureCollectionViewCell class] forCellWithReuseIdentifier: [AWELiveDuetPostureCollectionViewCell identifier]];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.alwaysBounceHorizontal = YES;
        _collectionView.contentInset = UIEdgeInsetsMake(16, 16, 24, 16);
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
    }
    return _collectionView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:15];
        _titleLabel.textColor = ACCResourceColor(ACCColorConstTextInverse2);
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"合拍背景";
    }
    return _titleLabel;
}

- (UIButton *)swapCameraButton {
    if (!_swapCameraButton) {
        _swapCameraButton = [[UIButton alloc] init];
        _swapCameraButton.exclusiveTouch = YES;
        _swapCameraButton.adjustsImageWhenHighlighted = NO;
        [_swapCameraButton setImage:[self swapCameraButtonImage] forState:UIControlStateNormal];
        [_swapCameraButton addTarget:self
                          action:@selector(cameraButtonPressed:)
                forControlEvents:UIControlEventTouchUpInside];
        _swapCameraButton.accessibilityLabel = ACCLocalizedCurrentString(@"reverse");
    }
    return _swapCameraButton;
}

- (UIImage *)swapCameraButtonImage
{
    return ACCResourceImage(@"ic_camera_filp");
}

- (AWECameraContainerToolButtonWrapView *)cameraButtonWrapView {
    if (!_cameraButtonWrapView) {
        UILabel *label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.font = [ACCFont() acc_boldSystemFontOfSize:10];
        label.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        label.textAlignment = NSTextAlignmentCenter;
        label.text = ACCLocalizedCurrentString(@"reverse");
        label.numberOfLines = 2;
        [label acc_addShadowWithShadowColor:ACCResourceColor(ACCUIColorConstLinePrimary) shadowOffset:CGSizeMake(0, 1) shadowRadius:2];
        label.isAccessibilityElement = NO;
        _cameraButtonWrapView = [[AWECameraContainerToolButtonWrapView alloc] initWithButton:self.swapCameraButton label:label itemID:ACCRecorderToolBarSwapContext];
        _cameraButtonWrapView.hidden = YES;
    }
    return _cameraButtonWrapView;
}

@end

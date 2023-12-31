//
//  ACCFlowerScrollPropPanelView.m
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/11/12.
//

#import "ACCFlowerScrollPropPanelView.h"
#import "ACCPropIndicatorView.h"
#import "ACCPropPickerViewDataSource.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCPropPickerView.h"
#import <KVOController/KVOController.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCCircleItemCell.h"
#import "ACCRecordPropService.h"
#import "AWERepoFlowerTrackModel.h"
#import <ReactiveObjC/RACEXTKeyPathCoding.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCTapticEngineManager.h>
#import "ACCRecognitionService.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreativeKit/ACCFontProtocol.h>

@interface ACCFlowerScrollPropPanelView () <UICollectionViewDataSource, ACCPropPickerViewDelegate>

@property (nonatomic, strong) ACCPropPickerView *pickerView;
@property (nonatomic, strong) ACCPropIndicatorView *indicatorView;
@property (nonatomic, strong) ACCPropPickerViewDataSource *pickerViewDataSource;

@property (nonatomic, strong) CAGradientLayer *indicatorGradientLayer;
@property (nonatomic, strong) CALayer *indicatorAlphaLayer;

@end

@implementation ACCFlowerScrollPropPanelView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.pickerView = [[ACCPropPickerView alloc] initWithFrame:CGRectZero];
    [self addSubview:self.pickerView];
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    self.indicatorView = [[ACCPropIndicatorView alloc] initWithFrame:CGRectZero];
    self.indicatorView.tipsView.backgroundColor = [UIColor clearColor];
    
    self.indicatorGradientLayer = [CAGradientLayer layer];
    self.indicatorGradientLayer.colors= @[
        (__bridge id)[ACCUIColorFromRGBA(0xFE2C55, 1.0) CGColor],
        (__bridge id)[ACCUIColorFromRGBA(0xFE2C55, 0.0) CGColor],
    ];
    self.indicatorGradientLayer.startPoint = CGPointMake(.5f, 1.0f);
    self.indicatorGradientLayer.startPoint = CGPointMake(.5f, 0.0f);
    self.indicatorGradientLayer.frame = CGRectMake(0, 0, 64, 64);

    self.indicatorAlphaLayer = [CALayer layer];
    self.indicatorAlphaLayer.frame = CGRectMake(0, 0, 64, 64);
    self.indicatorAlphaLayer.backgroundColor = [ACCUIColorFromRGBA(0xFF2C55, 0.30) CGColor];
    [self.indicatorView.tipsView.layer insertSublayer:self.indicatorAlphaLayer atIndex:0];
    [self.indicatorView.tipsView.layer insertSublayer:self.indicatorGradientLayer atIndex:0];
    
    self.indicatorView.ringBandWidth = 5; 
    self.indicatorView.ringTintColor = ACCUIColorFromRGBA(0xFFF9EE, 1.0);
    self.indicatorView.accessibilityLabel = @"indicatorView";
    self.indicatorView.captureLabel.text = @"正在加载";
    self.indicatorView.captureLabel.font = [ACCFont() systemFontOfSize:16.0f weight:ACCFontWeightMedium];
    self.indicatorView.captureLabel.textColor = ACCUIColorFromRGBA(0xFFE9D0, 1.0);
    [self.indicatorView showProgress:NO progress:0 animated:NO];
    [self addSubview:self.indicatorView];
    self.indicatorView.userInteractionEnabled = NO;
    [self acc_edgeFadingWithRatio:0.05];
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPhotoProp:)];
    [self.indicatorView addGestureRecognizer:tapGes];
}

- (void)setExposePanGestureRecognizer:(ACCExposePanGestureRecognizer *)exposePanGestureRecognizer
{
    _exposePanGestureRecognizer = exposePanGestureRecognizer;
    [self.pickerView.collectionView addGestureRecognizer:exposePanGestureRecognizer];
}

- (void)itemsDidChage:(NSDictionary *)change
{
    [self.pickerView reloadData];
}

- (void)setPanelViewMdoel:(ACCFlowerPropPanelViewModel *)panelViewModel
{
    [self.KVOController unobserve:_panelViewMdoel];
    _panelViewMdoel = panelViewModel;
    [self.KVOController observe:panelViewModel keyPath:@keypath(_panelViewMdoel, items) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial action:@selector(itemsDidChage:)];
    [self.KVOController observe:panelViewModel keyPath:@keypath(_panelViewMdoel, selectedItem) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial action:@selector(selectedItemDidChange:)];
    [self.KVOController observe:panelViewModel keyPath:@keypath(_panelViewMdoel, downloadProgressPack) options:NSKeyValueObservingOptionNew action:@selector(downloadProgressPackDidChange:)];
}

- (void)setRecognitionService:(id<ACCRecognitionService>)recognitionService
{
    [self.KVOController unobserve:_recognitionService];
    _recognitionService = recognitionService;
    @weakify(self);
    [self.KVOController observe:recognitionService keyPath:@keypath(_recognitionService, recognitionState) options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        acc_dispatch_main_async_safe(^{
            [self enableCaptureIfNeeded];
        });
    }];
}

- (void)selectedItemDidChange:(NSDictionary *)change
{
    [self enableCaptureIfNeeded];
    ACCFlowerEffectType type = self.panelViewMdoel.selectedItem.dType;
    if (type == ACCFlowerEffectTypeProp || type == ACCFlowerEffectTypeRecognition) {
        self.indicatorView.captureLabel.text = @"点击拍摄";
    } else if (type == ACCFlowerEffectTypePhoto) {
        self.indicatorView.captureLabel.text = @"点击拍照";
    } else {
        self.indicatorView.captureLabel.text = nil;
    }
    
    if (type != ACCFlowerEffectTypeProp) {
        [self.indicatorView showProgress:NO progress:0 animated:NO];
    }
    
    if (self.pickerView.selectedIndex != self.panelViewMdoel.selectedIndex) {
        [self updateSelectedIndex:self.panelViewMdoel.selectedIndex animated:NO]; // animated不要=YES，有bug
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(type == ACCFlowerEffectTypeScan){
            self.indicatorAlphaLayer.backgroundColor = [ACCUIColorFromRGBA(0xFF2C55, 1.0f) CGColor];
        }else{
            self.indicatorAlphaLayer.backgroundColor = [ACCUIColorFromRGBA(0xFF2C55, 0.3f) CGColor];
        }
    });
}

- (void)enableCaptureIfNeeded
{
    BOOL enable = NO;
    ACCFlowerPanelEffectModel *item = self.panelViewMdoel.selectedItem;
    if ([item.effect isFlowerPropAduit] && (item.dType == ACCFlowerEffectTypeProp)) {
        enable = YES;
    } else if (item.effect.downloaded && (item.dType == ACCFlowerEffectTypeProp)) {
        enable = YES;
    }
    ACCRecognitionState recognitionState = self.recognitionService.recognitionState;
    if (item.dType == ACCFlowerEffectTypeRecognition && (recognitionState != ACCRecognitionStateRecognizing)) {
        enable = YES;
    }
    if (item.dType == ACCFlowerEffectTypePhoto) {
        self.indicatorView.userInteractionEnabled = YES;
    } else {
        self.indicatorView.userInteractionEnabled = NO;
    }
    self.exposePanGestureRecognizer.enabled = enable;
}

- (void)downloadProgressPackDidChange:(NSDictionary *)change
{
    NSError *error = ACCDynamicCast([self.panelViewMdoel.downloadProgressPack acc_objectAtIndex:1], NSError);
    if (error) {
        [self.indicatorView showProgress:NO progress:0 animated:NO];
    }
    CGFloat progress = [ACCDynamicCast([self.panelViewMdoel.downloadProgressPack acc_objectAtIndex:1], NSNumber) doubleValue];
    if (progress >= 1.0){
        [self.indicatorView showProgress:NO progress:1.0 animated:YES];
        [self.indicatorView.captureLabel acc_fadeShow];
        [self enableCaptureIfNeeded];
    } else {
        [self.indicatorView showProgress:YES progress:progress animated:YES];
        self.indicatorView.captureLabel.alpha = 0;
    }
    
}

- (void)updateSelectedIndex:(NSInteger)index animated:(BOOL)animated
{
    if (index < 0 || index >= self.panelViewMdoel.items.count) {
        return;
    }
    [self.pickerView updateSelectedIndex:index animated:animated];
}

- (NSInteger)selectedIndex
{
    return self.pickerView.selectedIndex;
}

 
- (CGRect)indicatorFrame
{
    CGFloat h = 76;
    CGFloat w = 76;
    CGFloat x = self.bounds.size.width * 0.5 - w * 0.5;
    CGFloat y = self.bounds.size.height * 0.5 - h * 0.5;
    return CGRectMake(x, y, w, h);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.pickerView.frame = self.bounds;
    self.indicatorView.frame = [self indicatorFrame];
}

- (void)reloadScrollPanel
{
    [self.pickerView reloadData];
}

- (void)tapPhotoProp:(UITapGestureRecognizer *)tap
{
    ACCBLOCK_INVOKE(self.didTakePictureBlock);
}

#pragma mark - ACCPropPickerViewDelegate


- (void)pickerView:(nonnull ACCPropPickerView *)pickerView didChangeCenteredIndex:(NSInteger)index scrollReason:(ACCPropPickerViewScrollReason)reason {
    if (reason == ACCPropPickerViewScrollReasonDrag) {
        [ACCTapticEngineManager tap]; // light haptic feedback when scrolling across items by dragging
    }
}

- (void)pickerView:(nonnull ACCPropPickerView *)pickerView didEndAnimationAtIndex:(NSInteger)index {
    self.panelViewMdoel.selectedIndex = index; // 这个 didEndAnimation 和 didPickIndexByTap 应该只需要一个就可以了。
}

- (void)pickerView:(nonnull ACCPropPickerView *)pickerView didPickIndexByDragging:(NSInteger)index {
    self.panelViewMdoel.selectedIndex = index;
    [self.panelViewMdoel flowerTrackForPropClick:index enterMethod:@"sf_2022_activity_camera_slide"];
    self.panelViewMdoel.propService.repository.repoFlowerTrack.lastFlowerPropChooseMethod = @"sf_2022_activity_camera";
}

- (void)pickerView:(nonnull ACCPropPickerView *)pickerView didPickIndexByTap:(NSInteger)index
{
//    self.panelViewMdoel.selectedIndex = index;
    [self.panelViewMdoel flowerTrackForPropClick:index enterMethod:@"sf_2022_activity_camera_click"];
    self.panelViewMdoel.propService.repository.repoFlowerTrack.lastFlowerPropChooseMethod = @"sf_2022_activity_camera";
}

- (void)pickerView:(nonnull ACCPropPickerView *)pickerView willDisplayIndex:(NSInteger)index
{
    [self.panelViewMdoel flowerTrackForPropShow:index];
}

- (void)pickerViewWillBeginDragging:(nonnull ACCPropPickerView *)pickerView {
    
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.panelViewMdoel.items.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCCircleResourceItemCell *cell = (ACCCircleResourceItemCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(ACCCircleResourceItemCell.class) forIndexPath:indexPath];
    cell.overlay.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.6];
    cell.shadowRadius = 3;
    cell.borderWidth = 0.5;
    cell.borderColor = [UIColor.whiteColor colorWithAlphaComponent:0.12];
    cell.indexPath = indexPath;
    
    ACCFlowerPanelEffectModel *effect = [self.panelViewMdoel.items acc_objectAtIndex:indexPath.item];
    [ACCWebImage() imageView:cell.imageView
        setImageWithURLArray:effect.iconURL.URLList
             placeholder:nil
                  completion:nil];
    cell.name = effect.effect.effectName;
    return cell;
}

@end

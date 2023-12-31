//
//  ACCRecognitionScrollPropPanelView.m
//  CameraClient
//
//  Created by Shen Chen on 2020/4/1.
//

#import "ACCRecognitionScrollPropPanelView.h"
#import "ACCPropIndicatorView.h"
#import "ACCPropPickerViewDataSource.h"
#import "ACCFocusCollectionViewLayout.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

@interface ACCRecognitionScrollPropPanelView ()

@property (nonatomic, strong) ACCPropPickerView *pickerView;
@property (nonatomic, strong) ACCPropIndicatorView *indicatorView;
@property (nonatomic, strong) ACCPropPickerViewDataSource *pickerViewDataSource;
@property (nonatomic, strong) RACDisposable *dispose;
@end

@implementation ACCRecognitionScrollPropPanelView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.pickerView = [[ACCPropPickerView alloc] initWithFrame:self.bounds];
    [self addSubview:self.pickerView];
    self.pickerViewDataSource = [[ACCPropPickerViewDataSource alloc] init];
    self.pickerView.dataSource = self.pickerViewDataSource;
    self.indicatorView = [[ACCPropIndicatorView alloc] initWithFrame:[self indicatorFrame]];
    self.indicatorView.captureLabel.font = [UIFont systemFontOfSize:15];
    self.indicatorView.tipsView.backgroundColor = [ACCResourceColor(ACCUIColorConstPrimary) colorWithAlphaComponent:0.8];
    _indicatorView.ringBandWidth = 5;
    _indicatorView.ringTintColor = [UIColor whiteColor];
    _indicatorView.accessibilityLabel = @"indicatorView";
    [self addSubview:self.indicatorView];
    self.indicatorView.userInteractionEnabled = NO;
    [self acc_edgeFadingWithRatio:0.05];
}

- (void)setExposePanGestureRecognizer:(ACCExposePanGestureRecognizer *)exposePanGestureRecognizer
{
    _exposePanGestureRecognizer = exposePanGestureRecognizer;
    [self.pickerView.collectionView addGestureRecognizer:exposePanGestureRecognizer];
}

- (void)setPanelViewMdoel:(ACCRecognitionPropPanelViewModel *)panelViewModel
{
    _panelViewMdoel = panelViewModel;
    self.pickerView.delegate = panelViewModel;
    @weakify(self);

    [[[RACObserve(self.panelViewMdoel, propPickerDataList) takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(NSArray<ACCPropPickerItem *> * _Nullable items) {
        @strongify(self);
        self.pickerViewDataSource.items = items;
        [self.pickerView reloadData];
    }];
    
    [[[panelViewModel.downloadProgressSignal  takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(RACTwoTuple<NSNumber *, NSNumber *> * _Nullable x) {
        @strongify(self);

        BOOL show = x.second != nil;
        if ([x.second doubleValue] == 1.0){
            show = NO;
            self.indicatorView.captureLabel.transform = CGAffineTransformMakeScale(0.9, 0.9);
            self.indicatorView.captureLabel.alpha = 0;
            /// delay for ending of progressview disappear animation 
            [UIView animateWithDuration:0.3 delay:show? 0.5 : 0 options:UIViewAnimationOptionCurveLinear animations:^{
                self.indicatorView.captureLabel.alpha = 1;
                self.indicatorView.captureLabel.transform = CGAffineTransformMakeScale(1, 1);
            } completion:^(BOOL finished) {

            }];

        }else{
            show = self.panelViewMdoel.selectedItem.effect && !self.panelViewMdoel.selectedItem.effect.downloaded;
            self.indicatorView.captureLabel.alpha = self.panelViewMdoel.selectedItem.effect.downloaded?1:0;
        }

        [self.indicatorView showProgress:show progress:x.second.doubleValue];
    }];
    [[[panelViewModel.selectItemSignal takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(RACTwoTuple<ACCPropPickerItem *, NSNumber *> * _Nullable x) {
        @strongify(self);
        ACCPropPickerItem *item = x.first;
        BOOL animated = [x.second boolValue];
        [self selectedItem:item animated:animated];
    }];
    RAC(self.exposePanGestureRecognizer, enabled) = panelViewModel.enableCaptureSignal;

    [[RACObserve(self.panelViewMdoel, homeItem) takeUntil:self.rac_willDeallocSignal].deliverOnMainThread subscribeNext:^(ACCPropPickerItem * _Nullable x) {
        @strongify(self);
        if (!x) {
            [self.dispose dispose];
            self.dispose = nil;
            self.indicatorView.tipsView.alpha = 1;
            return ;
        }
        self.dispose = [[RACObserve(self.pickerView.collectionView, contentOffset) takeUntil:self.rac_willDeallocSignal].deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
            @strongify(self);
            if ([self.pickerView.collectionView.layer isKindOfClass:ACCFocusCollectionViewLayout.class]){
                return;
            }
            ACCFocusCollectionViewLayout *layout = (ACCFocusCollectionViewLayout *) self.pickerView.collectionView.collectionViewLayout;
            CGFloat ratio = fabs([layout currentCenterPosition]);
            self.indicatorView.tipsView.alpha = MIN(ratio, 1);
            self.pickerView.homeTintColor = ACCResourceColor(ACCUIColorConstPrimary);
        }];
    }];

}

- (void)selectedItem:(ACCPropPickerItem *)item animated:(BOOL)animated
{
    if (item != nil) {
        NSInteger index = [self.pickerViewDataSource.items indexOfObject:item];
        if (index != NSNotFound) {
            [self.pickerView updateSelectedIndex:index animated:animated];
        }
        if (item.type == ACCPropPickerItemTypeHome){
            [self.indicatorView showProgress:NO progress:0];
        }
    }
}

- (void)setHomeTintMode:(ACCScrollPropPickerHomeTintMode)homeTintMode
{
    _homeTintMode = homeTintMode;
    switch (homeTintMode) {
        case ACCScrollPropPickerHomeTintModeVideo:
            self.pickerView.homeTintColor = ACCResourceColor(ACCUIColorConstPrimary);
            self.pickerView.showHomeIcon = NO;
            break;
        case ACCScrollPropPickerHomeTintModePicture:
            self.pickerView.homeTintColor = ACCResourceColor(ACCUIColorBGContainer6);
            self.pickerView.showHomeIcon = NO;
            break;
        case ACCScrollPropPickerHomeTintModeStory:
            if (ACCConfigBool(kConfigBool_white_lightning_shoot_button)) {
                self.pickerView.homeTintColor = ACCResourceColor(ACCUIColorBGContainer6);
            } else {
                self.pickerView.homeTintColor = ACCResourceColor(ACCUIColorConstPrimary);
            }
            self.pickerView.showHomeIcon = YES;
            break;
        default:
            break;
    }
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

@end

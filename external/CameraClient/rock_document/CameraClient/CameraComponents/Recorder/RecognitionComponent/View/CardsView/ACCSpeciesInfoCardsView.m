//
//  ACCSpeciesInfoCardsView.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/17.
//

#import "ACCSpeciesInfoCardsView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

#import "ACCSpeciesInfoCardCollectionViewLayout.h"

@interface ACCSpeciesInfoCardsView ()<UICollectionViewDelegate>

@property (nonatomic, assign) CGFloat dragEndX;
@property (nonatomic, assign) CGFloat dragStartX;
@property (nonatomic, assign) NSInteger currentSelectedIndex;

@property (nonatomic, strong) UILabel *resultTipLabel;
@property (nonatomic, strong) UILabel *allowResearchTipLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UIButton *allowResearchButton;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, assign) CGSize maskSize;

@property (nonatomic, strong) ACCSpeciesInfoCardsViewConfig *config;
@property (nonatomic, assign) BOOL allowResearch;

@end

@implementation ACCSpeciesInfoCardsView

- (instancetype)initWithFrame:(CGRect)frame config:(ACCSpeciesInfoCardsViewConfig *)config
{
    if (self = [super initWithFrame:frame]) {
        self.config = config;
        self.allowResearch = config.allowResearch;
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    self.collectionView = ({
        CGSize size = [ACCSpeciesInfoCardsView collectionViewSize];
        ACCSpeciesInfoCardCollectionViewLayout *layout = [[ACCSpeciesInfoCardCollectionViewLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.minimumLineSpacing = 14;
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        collectionView.delegate = self;
        collectionView.pagingEnabled = NO;
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.backgroundColor = [UIColor whiteColor];
        collectionView.frame = CGRectMake(0, 52, ACC_SCREEN_WIDTH, size.height + 2);
        [self addSubview:collectionView];
        collectionView;
    });
    
    self.resultTipLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.font = [ACCFont() systemFontOfSize:17 weight:ACCFontWeightMedium];
        label.adjustsFontSizeToFitWidth = YES;
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
        [self addSubview:label];
        ACCMasMaker(label, {
            make.left.equalTo(@16);
            make.right.equalTo(self.mas_right).inset(40);
            make.height.equalTo(@24);
            make.top.equalTo(self.mas_top).inset(16);
        });
        label;
    });
    
    self.closeButton = ({
        UIButton *button = [[UIButton alloc] init];
        [button setImage:ACCResourceImage(@"icon_album_first_creative_close") forState:UIControlStateNormal];
        [button addTarget:self action:@selector(clickCloseButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        ACCMasMaker(button, {
            make.centerY.equalTo(self.resultTipLabel);
            make.right.equalTo(self).inset(8);
            make.height.width.mas_equalTo(32);
        });
        button;
    });
    
    self.confirmButton = ({
        ACCAnimatedButton *confirmButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        [self addSubview:confirmButton];
        confirmButton.layer.cornerRadius = 2.0;
        confirmButton.layer.masksToBounds = YES;
        [confirmButton.titleLabel setFont:[ACCFont() systemFontOfSize:15.f weight:ACCFontWeightMedium]];
        [confirmButton setTitle:self.config.confirmText forState:UIControlStateNormal];
        [confirmButton setBackgroundColor:ACCResourceColor(ACCColorPrimary)];
        [confirmButton addTarget:self action:@selector(clickConfirmButton:) forControlEvents:UIControlEventTouchUpInside];
        ACCMasMaker(confirmButton, {
            make.top.equalTo(self.collectionView.mas_bottom).offset(19);
            make.height.equalTo(@(44));
            make.left.equalTo(@(20));
            make.right.equalTo(@(-20));
        });
        confirmButton;
    });
    
    if (!ACC_isEmptyString(self.config.allowResearchTips)) {
        
        UIView *containerView = [[UIView alloc] init];
        [self addSubview:containerView];
        ACCMasMaker(containerView, {
            make.top.equalTo(self.confirmButton.mas_bottom).offset(16);
            make.centerX.equalTo(self);
            make.height.equalTo(@20);
        });
        
        self.allowResearchButton = ({
            UIButton *allowResearchButton = [[UIButton alloc] init];
            [allowResearchButton addTarget:self action:@selector(clickAllowResearchButton:) forControlEvents:UIControlEventTouchUpInside];
            UIImage *image = self.allowResearch ? ACCResourceImage(@"icon_filter_box_check") : ACCResourceImage(@"ic_checkbox_unselected");
            [allowResearchButton setImage:image forState:UIControlStateNormal];
            [containerView addSubview:allowResearchButton];
            ACCMasMaker(allowResearchButton, {
                make.left.equalTo(containerView).offset(0);
                make.centerY.equalTo(containerView);
                make.width.height.equalTo(@16);
            });
            allowResearchButton;
        });
        
        self.allowResearchTipLabel = ({
            UILabel *tipsLabel = [[UILabel alloc] init];
            tipsLabel.adjustsFontSizeToFitWidth = YES;
            tipsLabel.text = self.config.allowResearchTips;
            tipsLabel.font = [ACCFont() systemFontOfSize:14 weight:ACCFontWeightRegular];
            tipsLabel.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
            [containerView addSubview:tipsLabel];
            ACCMasMaker(tipsLabel, {
                make.left.equalTo(self.allowResearchButton.mas_right).offset(6);
                make.top.bottom.right.equalTo(containerView).offset(0);
            });
            tipsLabel;
        });
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!CGSizeEqualToSize(self.bounds.size, self.maskSize)) {
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(12, 12)];
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = self.bounds;
        maskLayer.path = maskPath.CGPath;
        self.layer.mask = maskLayer;
        self.maskSize = self.bounds.size;
    }
}

#pragma mark - Public Methods

- (void)registerCell:(Class)cellClass;
{
    if (cellClass) {
        [self.collectionView registerClass:cellClass forCellWithReuseIdentifier:NSStringFromClass(cellClass)];
    }
}

- (void)reloadData
{
    [self.collectionView reloadData];
    
    if ([self isOutOfBoundsCheck:self.defaultSelectionIndex]) {
        self.defaultSelectionIndex = 0;
    }
    
    self.currentSelectedIndex = self.defaultSelectionIndex;
    [self isScrollingBeforeMoveToCenter:NO];
    
    [self updateTipsForDataSource];
}

- (void)resetSelectedIndex:(NSUInteger)index
{
    if (self.currentSelectedIndex == index) {
        return;
    }
    
    if ([self isOutOfBoundsCheck:index]) {
        return;
    }
    
    [self.collectionView reloadData];
    self.currentSelectedIndex = index;
    [self isScrollingBeforeMoveToCenter:NO];
}

- (void)resetSelectionAsDefault
{
    if ([self isOutOfBoundsCheck:self.defaultSelectionIndex]) {
        return;
    }
    
    [self.collectionView reloadData];
    self.currentSelectedIndex = self.defaultSelectionIndex;
    [self isScrollingBeforeMoveToCenter:NO canCallback:NO];
}

+ (CGSize)designSizeWithConfig:(ACCSpeciesInfoCardsViewConfig *)config
{
    CGSize size = [ACCSpeciesInfoCardsView collectionViewSize];
    if (!ACC_isEmptyString(config.allowResearchTips)) {
        return CGSizeMake(ACC_SCREEN_WIDTH, size.height + 160.0f);
    }
    return CGSizeMake(ACC_SCREEN_WIDTH, size.height + 128.0f);
}

+ (CGSize)collectionViewSize
{
    CGFloat w = 284.0f;
    CGFloat h = 214.0f;
    CGFloat width = (w * ACC_SCREEN_WIDTH) / 375.0f;
    CGFloat height = (h * width) / w;
    return CGSizeMake(width, height);
}

#pragma mark - Private Methods

- (BOOL)isOutOfBoundsCheck:(NSUInteger)checkIndex
{
    NSInteger numberOfItems = [self.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
    return (numberOfItems <= checkIndex);
}

- (void)isScrollingBeforeMoveToCenter:(BOOL)isScrolling
{
    [self isScrollingBeforeMoveToCenter:isScrolling canCallback:YES];
}

- (void)isScrollingBeforeMoveToCenter:(BOOL)isScrolling canCallback:(BOOL)canCallback
{
    NSInteger from = self.currentSelectedIndex;
    if (isScrolling) {
        CGFloat dragMiniDistance = ACC_SCREEN_WIDTH / 20.0f;
        if (self.dragStartX - self.dragEndX >= dragMiniDistance) {
            self.currentSelectedIndex -= 1;
        } else if (self.dragEndX - self.dragStartX >= dragMiniDistance) {
            self.currentSelectedIndex += 1;
        }
    }
    
    NSInteger maxIndex = [self.collectionView numberOfItemsInSection:0] - 1;
    self.currentSelectedIndex = self.currentSelectedIndex <= 0 ? 0 : self.currentSelectedIndex;
    self.currentSelectedIndex = self.currentSelectedIndex >= maxIndex ? maxIndex : self.currentSelectedIndex;
   
    if (canCallback && (from != self.currentSelectedIndex)) {
        [self onSlideCardFrom:from to:self.currentSelectedIndex];
    }
    
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:self.currentSelectedIndex inSection:0];
    [self.collectionView selectItemAtIndexPath:selectedIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
}

- (void)onSlideCardFrom:(NSInteger)from to:(NSInteger)to
{
    if ([self.delegate respondsToSelector:@selector(cardsView:didSlideCardFrom:to:withAllowResearch:)]) {
        [self.delegate cardsView:self didSlideCardFrom:from to:self.currentSelectedIndex withAllowResearch:self.allowResearch];
    }
}

- (void)updateTipsForDataSource
{
    BOOL isDummy = NO;
    if ([self.dataSource respondsToSelector:@selector(isDummyDataInCardsView:)]) {
        isDummy = [self.dataSource isDummyDataInCardsView:self];
    }
    if (isDummy) {
        self.resultTipLabel.text = self.config.dummyDataTips;
    } else {
        self.resultTipLabel.text = self.config.realDataTips;
    }
}

- (void)updateAllowResearchButtonImage
{
    UIImage *image = self.allowResearch ? ACCResourceImage(@"icon_filter_box_check") : ACCResourceImage(@"ic_checkbox_unselected");
    [self.allowResearchButton setImage:image forState:UIControlStateNormal];
}

#pragma mark - Actions

- (void)clickCloseButton:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(cardsView:didCloseAtIndex:withAllowResearch:)]) {
        [self.delegate cardsView:self didCloseAtIndex:self.currentSelectedIndex withAllowResearch:self.allowResearch];
    }
}

- (void)clickConfirmButton:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(cardsView:didSelectItemAtIndex:withAllowResearch:)]) {
        [self.delegate cardsView:self didSelectItemAtIndex:self.currentSelectedIndex withAllowResearch:self.allowResearch];
    }
}

- (void)clickAllowResearchButton:(UIButton *)sender
{
    self.allowResearch = !self.allowResearch;
    if ([self.delegate respondsToSelector:@selector(cardsView:didCheckAllowResearch:)]) {
        [self.delegate cardsView:self didCheckAllowResearch:self.allowResearch];
    }
    [self updateAllowResearchButtonImage];
}

#pragma mark - UICollectionViewDelegate

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    CGFloat designWidth = [ACCSpeciesInfoCardsView collectionViewSize].width;
    CGFloat edgeWidth = (ACC_SCREEN_WIDTH - designWidth) / 2;
    UIEdgeInsets inset = UIEdgeInsetsMake(0, edgeWidth, 0, edgeWidth);
    return inset;
}

#pragma mark - UIScrollViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [ACCSpeciesInfoCardsView collectionViewSize];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.dragStartX = scrollView.contentOffset.x;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    self.dragEndX = scrollView.contentOffset.x;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self isScrollingBeforeMoveToCenter:YES];
    });
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentSelectedIndex = indexPath.row;
    [self isScrollingBeforeMoveToCenter:NO];
}

#pragma mark - Getter

- (id<UICollectionViewDataSource>)dataSource
{
    return self.collectionView.dataSource;
}

#pragma mark - Setter

- (void)setDataSource:(id<UICollectionViewDataSource>)dataSource
{
    self.collectionView.dataSource = dataSource;
}

@end


@implementation ACCSpeciesInfoCardsViewConfig

+ (instancetype)configWithDefaultParams
{
    ACCSpeciesInfoCardsViewConfig *config = [[ACCSpeciesInfoCardsViewConfig alloc] init];
    config.confirmText = @"确认";
    config.realDataTips = @"识别到的物种是";
    config.dummyDataTips = @"未识别出动植物，你还可以";
    config.allowResearch = NO;
    config.allowResearchTips = nil;
    return config;
}

+ (instancetype)configWithGrootParams
{
    ACCSpeciesInfoCardsViewConfig *config = [self configWithDefaultParams];
    config.allowResearch = YES;
    config.allowResearchTips = @"愿意通过抖音通知了解动植物相关公益项目";
    return config;
}

@end

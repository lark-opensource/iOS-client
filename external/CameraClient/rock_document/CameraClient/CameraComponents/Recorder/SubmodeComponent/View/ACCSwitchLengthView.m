//
//  AWESwitchLengthController.m
//  DouYin
//
//  Created by shaohua yang on 6/29/20.
//  Copyright © 2020 United Nations. All rights reserved.
//

#import "ACCSwitchLengthView.h"

#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCConfigKeyDefines.h"
#import "ACCRecordContainerMode.h"
#import "ACCRecordSubmodeViewModel.h"

@interface ACCSwitchLengthView () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, assign) NSInteger modeIndex;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *maskView;

@end

@implementation ACCSwitchLengthView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    NSInteger start = MAX(2 * SUBMODE_CELL_WIDTH - self.collectionView.contentOffset.x, 0);
    NSInteger end = MIN((self.cellCount - 2) * SUBMODE_CELL_WIDTH - self.collectionView.contentOffset.x, self.acc_width);
    CGRect visibleRect = CGRectMake(start, 0, end - start, self.acc_height);
    return CGRectContainsPoint(visibleRect, point);
}

#pragma mark - Private

- (void)setupUI
{
    self.layer.masksToBounds = YES;
    
    self.collectionView.frame = self.bounds;
    [self addSubview:self.collectionView];
    
    if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab)) {
        self.maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 46, 26)];
        self.maskView.layer.cornerRadius = 13;
        self.maskView.layer.masksToBounds = YES;
        self.maskView.backgroundColor = UIColor.whiteColor;
        self.maskView.acc_centerX = self.acc_centerX;
        self.maskView.acc_centerY = self.acc_centerY;
        self.maskView.layer.shadowColor = [UIColor.blackColor colorWithAlphaComponent:0.12].CGColor;
        self.maskView.layer.shadowOpacity = 1;
        self.maskView.layer.shadowRadius = 4;
        self.maskView.layer.shadowOffset = CGSizeMake(0, 1);
        [self insertSubview:self.maskView atIndex:0];
        if ([self enableOptimizeArchPerformanceForceLoadComponents]) {
            self.maskView.hidden = YES;
        }
    }
    
    // 左右两侧渐变
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.frame;
    gradientLayer.startPoint= CGPointMake(0, 0);
    gradientLayer.endPoint= CGPointMake(1, 0);
    UIColor* ClearColor = [UIColor.clearColor colorWithAlphaComponent:0];
    UIColor* opaqueColor = [UIColor.clearColor colorWithAlphaComponent:1];
    gradientLayer.colors = @[(__bridge id)ClearColor.CGColor,
                             (__bridge id)opaqueColor.CGColor,
                             (__bridge id)opaqueColor.CGColor,
                             (__bridge id)ClearColor.CGColor];
    gradientLayer.locations = @[@0, @0.18, @0.82, @1];
    self.layer.mask = gradientLayer;
}

- (void)changeModeIndexTo:(NSInteger)index withMethod:(submodeSwitchMethod)method
{
    if ([self.delegate respondsToSelector:@selector(modeIndexDidChangeTo:method:)]) {
        [self.delegate modeIndexDidChangeTo:index method:method];
    }
}

#pragma mark - <UICollectionViewDataSource>

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ACCSwitchLengthCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([ACCSwitchLengthCell class]) forIndexPath:indexPath];
    [cell prepareForReuse];
    cell.text = [self.containerMode.submodeTitles acc_objectAtIndex:indexPath.row - 2];

    //无障碍化设置
    cell.modeId = [self.containerMode.submodes acc_objectAtIndex:indexPath.row - 2].modeId;
    return cell;
}

- (NSInteger)cellCount {
    // _ _ * * * _ _
    // 左右各空出两个
    return self.containerMode.submodes.count + 4;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.cellCount;
}

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // Touch initiated mode change
    NSInteger modeIndex = indexPath.row - 2;
    [self setModeIndex:modeIndex animated:YES];
    [self changeModeIndexTo:modeIndex withMethod:submodeSwitchMethodTabBarClick];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (velocity.x < 0) {
        *targetContentOffset = CGPointMake(SUBMODE_CELL_WIDTH * (self.modeIndex - 1), 0);
    } else if (velocity.x > 0) {
        *targetContentOffset = CGPointMake(SUBMODE_CELL_WIDTH * (self.modeIndex + 1), 0);
    } else if (velocity.x == 0) {
        if (fabs(scrollView.contentOffset.x - self.modeIndex * SUBMODE_CELL_WIDTH) > SUBMODE_CELL_WIDTH / 2) {
            NSInteger offset = scrollView.contentOffset.x < self.modeIndex * SUBMODE_CELL_WIDTH ? -1 : 1;
            *targetContentOffset = CGPointMake(SUBMODE_CELL_WIDTH * (self.modeIndex + offset), 0);
        } else {
            *targetContentOffset = CGPointMake(SUBMODE_CELL_WIDTH * self.modeIndex, 0);
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.hidden) {
        return;
    }
    
    // Cell 渐变动画
    if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab)) {
        NSInteger offsetX = scrollView.contentOffset.x;
        NSIndexPath *leftIndexPath = [NSIndexPath indexPathForRow:offsetX / SUBMODE_CELL_WIDTH + 2 inSection:0];
        NSIndexPath *rightIndexPath = [NSIndexPath indexPathForRow:offsetX / SUBMODE_CELL_WIDTH + 3 inSection:0];
        ACCSwitchLengthCell *leftCell = (ACCSwitchLengthCell *)[self.collectionView cellForItemAtIndexPath:leftIndexPath];
        ACCSwitchLengthCell *rightCell;
        if (offsetX % SUBMODE_CELL_WIDTH == 0) {
            [[self.collectionView visibleCells] enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                ACCSwitchLengthCell *_cell = (ACCSwitchLengthCell *)obj;
                [_cell setProgress:1];
            }];
            [leftCell setProgress:0];
        } else {
            rightCell = (ACCSwitchLengthCell *)[self.collectionView cellForItemAtIndexPath:rightIndexPath];
            CGFloat progress = (offsetX % SUBMODE_CELL_WIDTH) / (CGFloat)SUBMODE_CELL_WIDTH;
            [leftCell setProgress:progress];
            [rightCell setProgress:1 - progress];
        }
    }
    
    CGFloat leftLimit = -0.5 * SUBMODE_CELL_WIDTH;
    CGFloat rightLimit = (self.containerMode.submodes.count - 0.5) * SUBMODE_CELL_WIDTH;
    if (scrollView.contentOffset.x <= leftLimit) {
        scrollView.contentOffset = CGPointMake(leftLimit, 0);
    } else if (scrollView.contentOffset.x >= rightLimit) {
        scrollView.contentOffset = CGPointMake(rightLimit, 0);
    } else {
        if (fabs(scrollView.contentOffset.x - self.modeIndex * SUBMODE_CELL_WIDTH) > SUBMODE_CELL_WIDTH / 2) {
            // Dragging initiated mode change
            if (scrollView.isTracking || scrollView.isDecelerating) {
                NSInteger index = (scrollView.contentOffset.x + SUBMODE_CELL_WIDTH / 2) / SUBMODE_CELL_WIDTH;
                [self changeModeIndexTo:index withMethod:submodeSwitchMethodTabBarSlide];
                self.modeIndex = index;
            }
            if ([scrollView isKindOfClass:[UICollectionView class]]) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.modeIndex + 2 inSection:0];
                UICollectionView *collectionView = (UICollectionView *)scrollView;
                [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:0];
                if ([ACCAccessibility() isVoiceOverOn]) {
                    [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
                }
            }
        }
    }
}

#pragma mark - Public

- (void)setModeIndex:(NSInteger)modeIndex animated:(BOOL)animated
{
    if ((self.collectionView.isDragging || self.collectionView.isDecelerating) && !self.needForceSwitch) {
        return;
    }
    self.needForceSwitch = NO;
    self.modeIndex = modeIndex;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:modeIndex + 2 inSection:0];
    [self.collectionView selectItemAtIndexPath:indexPath animated:animated scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    if (!animated && ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab)) {
        ACCSwitchLengthCell *cell = (ACCSwitchLengthCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell setProgress:0];
    }
}

#pragma mark - Getter & Setter

- (void)setContainerMode:(ACCRecordContainerMode *)containerMode
{
    _containerMode = containerMode;
    if (containerMode) {
        if ([self enableOptimizeArchPerformanceForceLoadComponents]) {
            self.maskView.hidden = NO;
        }
        [self.collectionView reloadData];
        [self.collectionView layoutIfNeeded];
        [self setModeIndex:containerMode.currentIndex animated:NO];
    }
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *flow = [[UICollectionViewFlowLayout alloc] init];
        flow.itemSize = CGSizeMake(SUBMODE_CELL_WIDTH, SUBMODE_CELL_HEIGHT);
        flow.minimumInteritemSpacing = 0;
        flow.minimumLineSpacing = 0;
        flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flow];
        [_collectionView registerClass:[ACCSwitchLengthCell class] forCellWithReuseIdentifier:NSStringFromClass([ACCSwitchLengthCell class])];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.layer.masksToBounds = NO;
        _collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab)) {
            _collectionView.bounces = NO;
        }
    }
    return _collectionView;
}

- (BOOL)enableOptimizeArchPerformanceForceLoadComponents
{
    ACCOptimizePerformanceType type = ACCConfigEnum(kConfigInt_component_performance_architecture_optimization_type, ACCOptimizePerformanceType);
    return ACCOptimizePerformanceTypeContains(type, ACCOptimizePerformanceTypeRecorderWithForceLoad);
}

@end

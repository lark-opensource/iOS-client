//
//  ACCImageAlbumDotPageControl.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/10/13.
//

#import "ACCImageAlbumDotPageControl.h"
#import "ACCImageAlbumDotPageControlCollectionView.h"

@interface ACCImageAlbumDotPageControl ()

@property (nonatomic, strong, nullable) ACCImageAlbumDotPageControlCollectionView *collectionView;

@property (nonatomic, strong, nullable) CALayer *gradientContainerLayer;
@property (nonatomic, strong, nullable) CAGradientLayer *leftGradientLayer;
@property (nonatomic, strong, nullable) CALayer *centerLayer;
@property (nonatomic, strong, nullable) CAGradientLayer *rightGradientLayer;

@end

@implementation ACCImageAlbumDotPageControl

@synthesize currentPageIndex;
@synthesize totalPageNum;

- (instancetype)initWithDotDiameter:(CGFloat)diameter visiableCellCount:(NSInteger)visiableCellCount dotSpacing:(CGFloat)dotSpacing
{
    self = [super init];
    if (self) {
        self.collectionView = [[ACCImageAlbumDotPageControlCollectionView alloc] initWithDotDiameter:diameter visiableCellCount:visiableCellCount dotSpacing:dotSpacing];
        [self p_setupUI];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat frameWidth = self.frame.size.width;
    CGFloat frameHeight = self.frame.size.height;
    self.collectionView.center = CGPointMake(frameWidth / 2.f, frameHeight / 2.f);
    [self p_setupGradientLayer];
}

#pragma mark - Private Methods

- (void)p_setupGradientLayer
{
    CGFloat gradientWidth = 1 + self.collectionView.dotDiameter + self.collectionView.dotSpacing;
    
    /* Container */
    self.gradientContainerLayer = [CALayer layer];
    self.gradientContainerLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    /* Left */
    self.leftGradientLayer = [CAGradientLayer layer];
    self.leftGradientLayer.startPoint = CGPointMake(0, 0.5);
    self.leftGradientLayer.endPoint = CGPointMake(1, 0.5);
    self.leftGradientLayer.colors = @[
        (id)[UIColor colorWithWhite:1.f alpha:0].CGColor,
        (id)[UIColor colorWithWhite:1.f alpha:0].CGColor,
        (id)[UIColor colorWithWhite:1.f alpha:1.f].CGColor,
    ];
    self.leftGradientLayer.locations = @[@0.0,
                                         @0.2,
                                         @1.0];
    self.leftGradientLayer.frame = CGRectMake(0, 0, gradientWidth, self.frame.size.height);
    
    /* Center */
    self.centerLayer = [CALayer layer];
    self.centerLayer.frame = CGRectMake(gradientWidth, 0, self.frame.size.width - 2 * gradientWidth, self.frame.size.height);
    self.centerLayer.backgroundColor = [UIColor colorWithWhite:1.f alpha:1.f].CGColor;
    
    /* Right */
    self.rightGradientLayer = [CAGradientLayer layer];
    self.rightGradientLayer.startPoint = CGPointMake(1, 0.5);
    self.rightGradientLayer.endPoint = CGPointMake(0, 0.5);
    self.rightGradientLayer.colors = @[
        (id)[UIColor colorWithWhite:1.f alpha:0].CGColor,
        (id)[UIColor colorWithWhite:1.f alpha:0].CGColor,
        (id)[UIColor colorWithWhite:1.f alpha:1.f].CGColor,
    ];
    self.rightGradientLayer.locations = @[@0.0,
                                          @0.2,
                                         @1.0];
    self.rightGradientLayer.frame = CGRectMake(self.frame.size.width - gradientWidth, 0, gradientWidth, self.frame.size.height);
    
    /* Combine */
    [self.gradientContainerLayer addSublayer:self.centerLayer];
    [self.gradientContainerLayer addSublayer:self.leftGradientLayer];
    [self.gradientContainerLayer addSublayer:self.rightGradientLayer];
    
    /* Mask */
    self.layer.mask = self.gradientContainerLayer;
}

- (void)p_setupUI
{
    self.backgroundColor = UIColor.clearColor;
    
    [self addSubview:self.collectionView];
    self.frame = self.collectionView.frame;
    self.collectionView.center = CGPointMake(self.frame.size.width / 2.f, self.frame.size.height / 2.f);
}

- (BOOL)p_shouldShowLeftGradident
{
    BOOL result = NO;
    NSInteger visiableCellCount = self.collectionView.visiableCellCount;
    if (self.totalPageNum <= visiableCellCount) {
        result = NO;
    } else if (self.currentPageIndex > visiableCellCount / 2) {
        result = YES;
    }
    return result;
}

- (BOOL)p_shouldShowRightGradident
{
    BOOL result = NO;
    NSInteger visiableCellCount = self.collectionView.visiableCellCount;
    if (self.totalPageNum <= visiableCellCount) {
        result = NO;
    } else if (self.currentPageIndex < self.totalPageNum - 1 - visiableCellCount / 2) {
        result = YES;
    }
    return result;
}

#pragma mark - Public Methods

- (void)updateCurrentPageIndex:(NSInteger)currentPageIndex
{
    // 越界保护
    if (currentPageIndex < 0) {
        currentPageIndex = 0;
    } else if (currentPageIndex > self.totalPageNum - 1) {
        currentPageIndex = self.totalPageNum - 1;
    }
    
    self.currentPageIndex = currentPageIndex;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:currentPageIndex inSection:0];
    [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    
    NSArray *gradentArr = @[
        (id)[UIColor colorWithWhite:1.f alpha:0].CGColor,
        (id)[UIColor colorWithWhite:1.f alpha:0].CGColor,
        (id)[UIColor colorWithWhite:1.f alpha:1.f].CGColor,
    ];
    
    NSArray *nonGradentArr = @[
        (id)[UIColor colorWithWhite:1.f alpha:1.f].CGColor,
        (id)[UIColor colorWithWhite:1.f alpha:1.f].CGColor,
        (id)[UIColor colorWithWhite:1.f alpha:1.f].CGColor,
    ];
    
    if ([self p_shouldShowLeftGradident]) {
        self.leftGradientLayer.colors = [gradentArr copy];
    } else {
        self.leftGradientLayer.colors = [nonGradentArr copy];
    }
    
    if ([self p_shouldShowRightGradident]) {
        self.rightGradientLayer.colors = [gradentArr copy];
    } else {
        self.rightGradientLayer.colors = [nonGradentArr copy];
    }
}

- (void)resetTotalPageNum:(NSInteger)totalPageNum currentPageIndex:(NSInteger)currentPageIndex
{
    self.totalPageNum = totalPageNum;
    [self.collectionView updateCellQty:self.totalPageNum];
    [self updateCurrentPageIndex:currentPageIndex];
}

@end

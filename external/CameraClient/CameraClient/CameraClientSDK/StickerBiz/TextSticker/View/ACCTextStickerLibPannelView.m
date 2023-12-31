//
//  ACCTextStickerLibPannelView.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/7/30.
//

#import "ACCTextStickerLibPannelView.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <Masonry/Masonry.h>
#import <CreativeKit/ACCMacros.h>
#import "AWERepoStickerModel.h"
#import <CameraClientModel/ACCTextRecommendModel.h>
#import "ACCTextStickerRecommendDataHelper.h"
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

typedef NS_ENUM(NSUInteger, ACCTextStickerLibTitleCellStyle) {
    ACCTextStickerLibTitleCellStyleTabNormal = 0,
    ACCTextStickerLibTitleCellStyleTabSelected = 1,
    ACCTextStickerLibTitleCellStyleContent = 2
};

@interface ACCTextStickerLibTitleCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *titleView;
@property (nonatomic, strong) UIView *spiltLine;

@end

@implementation ACCTextStickerLibTitleCell

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
    UILabel *titleView = [[UILabel alloc] init];
    titleView.textColor = [UIColor whiteColor];
    titleView.lineBreakMode = NSLineBreakByTruncatingTail;
    titleView.textAlignment = NSTextAlignmentCenter;
    self.titleView = titleView;
    [self addSubview:titleView];
    ACCMasMaker(titleView, {
        make.edges.equalTo(self);
    });
    
    UIView *splitLine = [[UIView alloc] init];
    splitLine.acc_height = 1.f/[UIScreen mainScreen].scale;
    splitLine.backgroundColor = ACCResourceColor(ACCColorBGTertiary3);
    self.spiltLine = splitLine;
    [self addSubview:splitLine];
    ACCMasMaker(splitLine, {
        make.left.right.bottom.equalTo(self);
        make.height.equalTo(@(1.f/[UIScreen mainScreen].scale));
    });
    self.spiltLine.hidden = YES;
}

- (void)editWithStyle:(ACCTextStickerLibTitleCellStyle)style
{
    UILabel *titleView = self.titleView;
    switch (style) {
        case ACCTextStickerLibTitleCellStyleTabNormal:
        {
            titleView.font = [UIFont acc_systemFontOfSize:15.f weight:ACCFontWeightRegular];
            titleView.textColor = [UIColor colorWithWhite:1.f alpha:0.5];
            titleView.textAlignment = NSTextAlignmentCenter;
        }
            break;
        case ACCTextStickerLibTitleCellStyleTabSelected:
        {
            titleView.font = [UIFont acc_systemFontOfSize:15.f weight:ACCFontWeightMedium];
            titleView.textColor = [UIColor whiteColor];
            titleView.textAlignment = NSTextAlignmentCenter;
        }
            break;
        default:
        {
            titleView.font = [UIFont acc_systemFontOfSize:14.f weight:ACCFontWeightMedium];
            titleView.textColor = [UIColor whiteColor];
            titleView.textAlignment = NSTextAlignmentLeft;
            titleView.numberOfLines = 0;
        }
            break;
    }
}

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.titleView.text;
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

+ (NSString *)identifier
{
    return @"ACCTextStickerLibTitleCell";
}

@end

/***********************Beautiful Split Line***************************/

@interface ACCTextStickerLibPannelView()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, copy) NSArray<ACCTextStickerLibItem *> *items;
// 分类tab
@property (nonatomic, strong) UICollectionView *categoryView;
@property (nonatomic, strong) UIView *categoryLine;
// 详细列表
@property (nonatomic, strong) UICollectionView *listView;
@property (nonatomic, strong) UILabel *retryLabel;
// 底部按钮
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *confirmBtn;

@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) CGFloat lastContentOffset;

@property (nonatomic, weak) UIView<ACCLoadingViewProtocol> *loadingView;

@end

@implementation ACCTextStickerLibPannelView

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
    self.backgroundColor = ACCResourceColor(ACCColorConstBGInverse2);
    [self acc_addSystemBlurEffect:UIBlurEffectStyleDark];
    
    UICollectionViewFlowLayout *categoryLayout = [[UICollectionViewFlowLayout alloc] init];
    categoryLayout.minimumInteritemSpacing = 0.f;
    categoryLayout.minimumLineSpacing = 4.f;
    categoryLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    UICollectionView *categoryView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:categoryLayout];
    categoryView.backgroundColor = [UIColor clearColor];
    categoryView.showsHorizontalScrollIndicator = NO;
    categoryView.delegate = self;
    categoryView.dataSource = self;
    categoryView.bounces = YES;
    self.categoryView = categoryView;
    [self addSubview:categoryView];
    ACCMasMaker(categoryView, {
        make.left.right.top.equalTo(self);
        make.height.equalTo(@45.f);
    });
    
    [categoryView registerClass:[ACCTextStickerLibTitleCell class] forCellWithReuseIdentifier:[ACCTextStickerLibTitleCell identifier]];
    
    UIView *categoryLine = [[UIView alloc] init];
    categoryLine.backgroundColor = [UIColor whiteColor];
    categoryLine.acc_height = 2.f;
    categoryLine.acc_bottom = 45.f;
    self.categoryLine = categoryLine;
    [self.categoryView addSubview:categoryLine];
    
    UICollectionViewFlowLayout *listLayout = [[UICollectionViewFlowLayout alloc] init];
    listLayout.minimumLineSpacing = 0.f;
    listLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    UICollectionView *listView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:listLayout];
    listView.backgroundColor = [UIColor clearColor];
    listView.showsVerticalScrollIndicator = NO;
    listView.delegate = self;
    listView.dataSource = self;
    listView.bounces = YES;
    listView.contentInset = UIEdgeInsetsMake(0.f, 16.f, 52.f+ACC_IPHONE_X_BOTTOM_OFFSET, 16.f);
    self.listView = listView;
    [self addSubview:listView];
    ACCMasMaker(listView, {
        make.left.right.bottom.equalTo(self);
        make.top.equalTo(categoryView.mas_bottom);
    });
    
    [listView registerClass:[ACCTextStickerLibTitleCell class] forCellWithReuseIdentifier:[ACCTextStickerLibTitleCell identifier]];
    
    UIView *bottomBar = [[UIView alloc] init];
    bottomBar.backgroundColor = ACCResourceColor(ACCColorConstBGInverse2);
    [bottomBar acc_addSystemBlurEffect:UIBlurEffectStyleDark];
    [self addSubview:bottomBar];
    ACCMasMaker(bottomBar, {
        make.left.right.bottom.equalTo(self);
        make.height.equalTo(@(52.f+ACC_IPHONE_X_BOTTOM_OFFSET));
    });
    
    UIView *splitLine = [[UIView alloc] init];
    splitLine.backgroundColor = ACCResourceColor(ACCColorBGTertiary3);
    [bottomBar addSubview:splitLine];
    ACCMasMaker(splitLine, {
        make.left.right.top.equalTo(bottomBar);
        make.height.equalTo(@(1.f/[UIScreen mainScreen].scale));
    });
    
    UIButton *cancelBtn = [[UIButton alloc] init];
    cancelBtn.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10.f, -10.f, -10.f, -10.f);
    [cancelBtn setImage:ACCResourceImage(@"ic_titlebar_close_white") forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    cancelBtn.accessibilityLabel = @"取消";
    cancelBtn.accessibilityTraits = UIAccessibilityTraitButton;
    cancelBtn.isAccessibilityElement = YES;
    self.cancelBtn = cancelBtn;
    [bottomBar addSubview:cancelBtn];
    ACCMasMaker(cancelBtn, {
        make.left.equalTo(@20.f);
        make.top.equalTo(@14.f);
        make.width.height.equalTo(@20.f);
    });
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont acc_systemFontOfSize:15.f weight:ACCFontWeightMedium];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = @"文案库";
    [bottomBar addSubview:titleLabel];
    ACCMasMaker(titleLabel, {
        make.centerX.equalTo(bottomBar);
        make.top.equalTo(@16.f);
        make.width.equalTo(@50.f);
        make.height.equalTo(@21.f);
    })
    
    UIButton *confirmBtn = [[UIButton alloc] init];
    confirmBtn.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10.f, -10.f, -10.f, -10.f);
    [confirmBtn setImage:ACCResourceImage(@"icon_edit_bar_done") forState:UIControlStateNormal];
    [confirmBtn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    confirmBtn.accessibilityLabel = @"确认";
    confirmBtn.accessibilityTraits = UIAccessibilityTraitButton;
    confirmBtn.isAccessibilityElement = YES;
    self.confirmBtn = confirmBtn;
    [bottomBar addSubview:confirmBtn];
    ACCMasMaker(confirmBtn, {
        make.right.equalTo(@-20.f);
        make.top.equalTo(@14.f);
        make.width.height.equalTo(@20.f);
    });
    
    UILabel *retryLabel = [[UILabel alloc] init];
    retryLabel.userInteractionEnabled = YES;
    retryLabel.text = @"加载失败，点击重试";
    retryLabel.textColor = [UIColor whiteColor];
    retryLabel.textAlignment = NSTextAlignmentCenter;
    retryLabel.font = [UIFont acc_systemFontOfSize:15.f];
    [retryLabel acc_addSingleTapRecognizerWithTarget:self action:@selector(retry)];
    self.retryLabel = retryLabel;
    [self addSubview:retryLabel];
    ACCMasMaker(retryLabel, {
        make.left.right.centerY.equalTo(self);
        make.height.equalTo(@20.f);
    });
    retryLabel.hidden = YES;
    
    [self layoutIfNeeded];// 初始化状态可能就需要有滚动，因此要立即撑开
}

- (void)updateWithItems:(NSArray<ACCTextStickerLibItem *> *)items
{
    _items = items;
    _currentIndex = 0;
    if (items.count > 0) {
        [self scrollToIndex:self.currentIndex];
        [self.listView reloadData];
        CGFloat targetOffset = [self.listView.collectionViewLayout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self.currentIndex]].frame.origin.y;
        [self.listView setContentOffset:CGPointMake(self.listView.contentOffset.x, targetOffset) animated:NO];
        self.retryLabel.hidden = YES;
    } else {
        [self retry];
    }
}

- (void)retry
{
    @weakify(self);
    self.loadingView = [ACCLoading() showLoadingOnView:self];
    self.retryLabel.hidden = YES;
    [ACCTextStickerRecommendDataHelper requestLibList:self.publishViewModel completion:^(NSArray<ACCTextStickerLibItem *> *result, NSError *error) {
        @strongify(self);
        [self.loadingView dismiss];
        if (!error && result.count) {
            self.publishViewModel.repoSticker.textLibItems = result;
            [self updateWithItems:result];
        } else {
            self.retryLabel.hidden = NO;
        }
    }];
}

- (void)scrollToIndex:(NSInteger)index
{
    self.currentIndex = index;
    if (index < self.items.count) {
        self.categoryView.userInteractionEnabled = NO;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.categoryView reloadData];
        [self.categoryView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];

        ACCTextStickerLibTitleCell *cell = [self.categoryView dequeueReusableCellWithReuseIdentifier:[ACCTextStickerLibTitleCell identifier] forIndexPath:indexPath];
        CGFloat targetCenter = cell.acc_centerX;
        CGFloat targetWidth = cell.acc_width - 32.f;
        self.categoryLine.acc_width = targetWidth;
        [UIView animateWithDuration:0.25 animations:^{
            self.categoryLine.acc_centerX = targetCenter;
        } completion:^(BOOL finished) {
            self.categoryView.userInteractionEnabled = YES;
        }];
    }
}

- (void)btnClicked:(UIButton *)btn
{
    if (btn == self.cancelBtn) {
        ACCBLOCK_INVOKE(self.onDismiss, NO);
    } else if (btn == self.confirmBtn) {
        ACCBLOCK_INVOKE(self.onDismiss, YES);
    }
}

#pragma mark - UICollectionViewDataSource, UICollectionViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.listView) {
        CGPoint currentOffset = scrollView.contentOffset;
        BOOL scrollUp = (scrollView.contentOffset.y > self.lastContentOffset);
        if(scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating) {
            UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.listView.collectionViewLayout;
            NSInteger targetIndex = -1;
            for (NSInteger section = 0; section < [self.items count]; section++) {
                ACCTextStickerLibItem *item = [self.items acc_objectAtIndex:section];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:item.titles.count - 1 inSection:section];
                CGRect frame = [layout layoutAttributesForItemAtIndexPath:indexPath].frame;
                if (scrollUp) {
                    if (CGRectGetMaxY(frame) - currentOffset.y >= 0.f) {
                        targetIndex = section;
                        if (section != self.currentIndex) {
                            [self scrollToIndex:section];
                        }
                        break;
                    }
                } else {
                    if (CGRectGetMinY(frame) - currentOffset.y >= 0.f) {
                        targetIndex = section;
                        if (section != self.currentIndex) {
                            [self scrollToIndex:section];
                        }
                        break;
                    }
                }
            }
        }
        self.lastContentOffset = currentOffset.y;
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if (collectionView == self.categoryView) {
        return 1;
    } else {
        return self.items.count;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView == self.categoryView) {
        return self.items.count;
    } else {
        ACCTextStickerLibItem *item = [self.items acc_objectAtIndex:section];
        return item.titles.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCTextStickerLibTitleCell *cell = nil;
    if (collectionView == self.categoryView) {
        cell = [self.categoryView dequeueReusableCellWithReuseIdentifier:[ACCTextStickerLibTitleCell identifier] forIndexPath:indexPath];
        if (indexPath.row == self.currentIndex) {
            [cell editWithStyle:ACCTextStickerLibTitleCellStyleTabSelected];
        } else {
            [cell editWithStyle:ACCTextStickerLibTitleCellStyleTabNormal];
        }
        cell.titleView.text = [self.items acc_objectAtIndex:indexPath.row].name;
    } else{
        cell = [self.listView dequeueReusableCellWithReuseIdentifier:[ACCTextStickerLibTitleCell identifier] forIndexPath:indexPath];
        [cell editWithStyle:ACCTextStickerLibTitleCellStyleContent];
        ACCTextStickerLibItem *item = [self.items acc_objectAtIndex:indexPath.section];
        cell.titleView.text = [item.titles acc_objectAtIndex:indexPath.row];
        cell.spiltLine.hidden = (indexPath.section == self.items.count - 1) && (indexPath.row == item.titles.count - 1);
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.categoryView) {
        NSString *title = [self.items acc_objectAtIndex:indexPath.row].name;
        CGFloat width = [title boundingRectWithSize:CGSizeMake(141.f, 34.f) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13.f]} context:nil].size.width;
        return CGSizeMake(width + 24.f, 45.f);
    } else{
        NSString *title = [[self.items acc_objectAtIndex:indexPath.section].titles acc_objectAtIndex:indexPath.row];
        CGFloat height = [title boundingRectWithSize:CGSizeMake(ACC_SCREEN_WIDTH - 32.f, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13.f]} context:nil].size.height;
        return CGSizeMake(ACC_SCREEN_WIDTH - 32.f, height + 30.f);
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.categoryView) {
        [self scrollToIndex:indexPath.row];
        CGFloat targetOffset = [self.listView.collectionViewLayout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self.currentIndex]].frame.origin.y;
        [self.listView setContentOffset:CGPointMake(self.listView.contentOffset.x, targetOffset) animated:NO];
        
        ACCTextStickerLibItem *item = [self.items acc_objectAtIndex:indexPath.row];
        ACCBLOCK_INVOKE(self.onGroupSelected, item.name);
    } else{
        ACCTextStickerLibItem *item = [self.items acc_objectAtIndex:indexPath.section];
        ACCBLOCK_INVOKE(self.onTitleSelected, [item.titles acc_objectAtIndex:indexPath.row], item.name);
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.listView) {
        ACCTextStickerLibItem *item = [self.items acc_objectAtIndex:indexPath.section];
        if (!item.exposured) {
            ACCBLOCK_INVOKE(self.onTitleExposured, [item.titles acc_objectAtIndex:indexPath.row], item.name);
            if (indexPath.row == item.titles.count - 1) {
                item.exposured = YES;
            }
        }
    }
}

+ (CGFloat)panelHeight
{
    return 308.f + ACC_IPHONE_X_BOTTOM_OFFSET;
}

@end

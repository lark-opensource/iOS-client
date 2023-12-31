//
//  ACCNewYearWishTextEditView.m
//  Aweme
//
//  Created by 卜旭阳 on 2021/11/3.
//

#import "ACCNewYearWishTextEditView.h"

#import "ACCCommonMultiRowsCollectionLayout.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

static const CGFloat kNewYearWishTextCellHeight = 32;
static const CGFloat kNewYearWishTextPadding = 20;
static const CGFloat kNewYearWishTextSpacingX = 12;
static const CGFloat kNewYearWishTextSpacingY = 16;
static const NSInteger kNewYearWishTextMaxLength = 14;

@interface ACCNewYearWishTextEditCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *label;

@end

@implementation ACCNewYearWishTextEditCollectionViewCell

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
    self.contentView.backgroundColor = ACCResourceColor(ACCColorConstBGContainer5);
    self.contentView.layer.cornerRadius = 16.f;
    self.contentView.layer.masksToBounds = YES;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, 0.f, kNewYearWishTextCellHeight)];
    label.textColor = [UIColor colorWithWhite:1.f alpha:0.9];
    label.font = [ACCFont() acc_systemFontOfSize:13 weight:ACCFontWeightRegular];
    [self.contentView addSubview:label];
    self.label = label;
}

- (void)updateWithText:(NSString *)text selected:(BOOL)selected
{
    if (text.length > kNewYearWishTextMaxLength) {
        text = [[text substringToIndex:kNewYearWishTextMaxLength] stringByAppendingString:@"..."];
    }
    self.contentView.layer.borderWidth = selected ? 2.f : 0.f;
    self.contentView.layer.borderColor = selected ? ACCResourceColor(ACCUIColorConstPrimary).CGColor : [UIColor clearColor].CGColor;
    
    CGFloat width = [ACCNewYearWishTextEditCollectionViewCell estimateWidthForTitle:text];
    self.label.frame = CGRectMake(kNewYearWishTextPadding, 0.f, width, kNewYearWishTextCellHeight);
    self.label.text = text;
}

#pragma mark - UIAccessibility

+ (CGFloat)estimateWidthForTitle:(NSString *)title
{
    NSDictionary *attribute = @{NSFontAttributeName: [ACCFont() acc_systemFontOfSize:13 weight:ACCFontWeightRegular]};
    return ceil([title boundingRectWithSize:CGSizeMake(1000.f, kNewYearWishTextCellHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil].size.width);
}

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.label.text;
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

+ (NSString *)identifier
{
    return @"ACCNewYearWishTextEditCollectionViewCell";
}

@end

@interface ACCNewYearWishTextEditView()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIVisualEffectView *panelView;
@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation ACCNewYearWishTextEditView

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
    panelView.frame = CGRectMake(0.f, self.acc_height, ACC_SCREEN_WIDTH, [ACCNewYearWishTextEditView viewHeight]);
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.f, 0.f, ACC_SCREEN_WIDTH, [ACCNewYearWishTextEditView viewHeight]) byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(12.f, 12.f)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.path = bezierPath.CGPath;
    panelView.layer.mask = maskLayer;
    [self addSubview:panelView];
    self.panelView = panelView;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"心愿库";
    titleLabel.font = [UIFont acc_systemFontOfSize:15.f weight:ACCFontWeightMedium];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [panelView.contentView addSubview:titleLabel];
    ACCMasMaker(titleLabel, {
        make.top.equalTo(@(kNewYearWishTextSpacingY));
        make.left.right.equalTo(self);
        make.height.equalTo(@18.f);
    });
    
    ACCCommonMultiRowsCollectionLayout *layout = [[ACCCommonMultiRowsCollectionLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    CGFloat estimatedItemWidth = 80;
    if (@available(iOS 10.0, *)) {
        estimatedItemWidth = 1000;
    }
    layout.estimatedItemSize = CGSizeMake(estimatedItemWidth, kNewYearWishTextCellHeight);
    layout.numberOfRows = 3;
    layout.spacingX = kNewYearWishTextSpacingX;
    layout.SpacingY = kNewYearWishTextSpacingY;

    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0.f, kNewYearWishTextSpacingY * 2 + 30.f, ACC_SCREEN_WIDTH, kNewYearWishTextCellHeight * 3 + kNewYearWishTextSpacingY * 2) collectionViewLayout:layout];
    collectionView.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    collectionView.backgroundColor = UIColor.clearColor;
    [collectionView registerClass:[ACCNewYearWishTextEditCollectionViewCell class] forCellWithReuseIdentifier:[ACCNewYearWishTextEditCollectionViewCell identifier]];
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [panelView.contentView addSubview:collectionView];
    self.collectionView = collectionView;
}

- (void)performAnimation:(BOOL)show
{
    if (show) {
        [self.collectionView reloadData];
        if (self.selectedIndex < self.titles.count) {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        }
        
        self.panelView.acc_top = self.acc_height;
        self.backView.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.panelView.acc_bottom = self.acc_height;
        } completion:^(BOOL finished) {
            self.backView.userInteractionEnabled = YES;
        }];
    } else {
        self.backView.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.panelView.acc_top = self.acc_height;
        } completion:^(BOOL finished) {
            ACCBLOCK_INVOKE(self.dismissBlock);
        }];
    }
}

#pragma mark - DataSource&Delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.titles.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCNewYearWishTextEditCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[ACCNewYearWishTextEditCollectionViewCell identifier] forIndexPath:indexPath];

    NSString *title = [self.titles acc_objectAtIndex:indexPath.row];
    [cell updateWithText:title selected:indexPath.row == self.selectedIndex];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = [self.titles acc_objectAtIndex:indexPath.row];
    self.selectedIndex = indexPath.row;
    
    [self.collectionView reloadData];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    ACCBLOCK_INVOKE(self.onTitleSelected, title, indexPath.row);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = [self.titles acc_objectAtIndex:indexPath.row];
    if (title.length > kNewYearWishTextMaxLength) {
        title = [[title substringToIndex:kNewYearWishTextMaxLength] stringByAppendingString:@"..."];
    }
    return CGSizeMake([ACCNewYearWishTextEditCollectionViewCell estimateWidthForTitle:title] + 2 * kNewYearWishTextPadding, kNewYearWishTextCellHeight);
}

#pragma mark - Private
- (void)p_dismiss
{
    [self performAnimation:NO];
}

+ (CGFloat)viewHeight
{
    return kNewYearWishTextCellHeight * 3 + kNewYearWishTextSpacingY * 2 + kNewYearWishTextSpacingY * 3 + 30.f + ACC_IPHONE_X_BOTTOM_OFFSET;
}

@end

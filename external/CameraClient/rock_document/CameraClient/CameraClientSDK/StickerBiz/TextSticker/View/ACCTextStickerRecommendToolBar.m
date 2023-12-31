//
//  ACCTextStickerRecommendToolBar.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/7/26.
//

#import "ACCTextStickerRecommendToolBar.h"
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <Masonry/Masonry.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CameraClientModel/ACCTextRecommendModel.h>

@interface ACCTextStickerRecommendTitleCell : UICollectionViewCell

@property (nonatomic, strong) UILabel *titleView;

@end

@implementation ACCTextStickerRecommendTitleCell

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
    self.backgroundColor = ACCResourceColor(ACCColorConstBGContainer5);
    self.layer.cornerRadius = 4.f;
    self.layer.masksToBounds = YES;
    
    UILabel *titleView = [[UILabel alloc] init];
    titleView.textColor = [UIColor whiteColor];
    titleView.lineBreakMode = NSLineBreakByTruncatingTail;
    titleView.textAlignment = NSTextAlignmentCenter;
    titleView.font = [UIFont acc_systemFontOfSize:13.f weight:ACCFontWeightMedium];
    [self addSubview:titleView];
    self.titleView = titleView;
    ACCMasMaker(titleView, {
        make.left.equalTo(@12.f);
        make.right.equalTo(@-12.f);
        make.top.equalTo(@8.f);
        make.bottom.equalTo(@-8.f);
    });
}

+ (CGFloat)widthForTitle:(NSString *)title
{
    return ceil([title boundingRectWithSize:CGSizeMake(141.f, 34.f) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont acc_systemFontOfSize:13.f weight:ACCFontWeightMedium]} context:nil].size.width) + 24.f;
}

+ (NSString *)identifier
{
    return @"ACCTextStickerRecommendTitleCell";
}

@end

/***********************Beautiful Split Line***************************/

@interface ACCTextStickerRecommendToolBar()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *recommendTagsView;
@property (nonatomic, strong) UIView *recommendLibView;

@property (nonatomic, copy) NSArray<ACCTextStickerRecommendItem *> *originalTitles;
@property (nonatomic, copy, readwrite) NSArray<ACCTextStickerRecommendItem *> *editingTitles;


@end

@implementation ACCTextStickerRecommendToolBar

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
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 4.f;
    layout.minimumLineSpacing = 4.f;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    UICollectionView *recommendTagsView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    recommendTagsView.backgroundColor = [UIColor clearColor];
    recommendTagsView.contentInset = UIEdgeInsetsMake(0.f, 12.f, 0.f, 0.f);
    recommendTagsView.showsHorizontalScrollIndicator = NO;
    recommendTagsView.delegate = self;
    recommendTagsView.dataSource = self;
    self.recommendTagsView = recommendTagsView;
    [self addSubview:recommendTagsView];
    ACCMasMaker(recommendTagsView, {
        make.edges.equalTo(self);
    });
    
    [recommendTagsView registerClass:[ACCTextStickerRecommendTitleCell class] forCellWithReuseIdentifier:[ACCTextStickerRecommendTitleCell identifier]];
}

- (void)updateWithTitles:(NSArray<ACCTextStickerRecommendItem *> *)titles
{
    NSInteger maxCount = ACCConfigInt(kConfigInt_studio_text_recommend_count) ? : 20;
    titles = titles.count > maxCount ? [titles subarrayWithRange:NSMakeRange(0.f, maxCount)] : titles;
    _originalTitles = titles;
    _editingTitles = titles;
    [self.recommendTagsView reloadData];
}

- (void)selectAtIndex:(NSInteger)index
{
    NSString *title = [self.editingTitles acc_objectAtIndex:index].content;
    ACCBLOCK_INVOKE(self.onTitleSelected, title);
    
    NSMutableArray<ACCTextStickerRecommendItem *> *titles = [self.editingTitles mutableCopy];
    [titles removeObjectAtIndex:index];
    self.editingTitles = [titles copy];
    [self.recommendTagsView reloadData];
}

#pragma mark - UICollectionViewDataSource, UICollectionViewDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.editingTitles.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCTextStickerRecommendTitleCell *cell = [self.recommendTagsView dequeueReusableCellWithReuseIdentifier:[ACCTextStickerRecommendTitleCell identifier] forIndexPath:indexPath];
    NSString *title = [self.editingTitles acc_objectAtIndex:indexPath.row].content;
    cell.titleView.text = title;
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = [self.editingTitles acc_objectAtIndex:indexPath.row].content;
    return CGSizeMake([ACCTextStickerRecommendTitleCell widthForTitle:title], 34.f);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self selectAtIndex:indexPath.row];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    ACCTextStickerRecommendItem *item = [self.editingTitles acc_objectAtIndex:indexPath.row];
    if (!item.exposured) {
        item.exposured = YES;
        ACCBLOCK_INVOKE(self.onTitleExposured, item.content);
    }
}

@end

/***********************Beautiful Split Line***************************/

@implementation ACCTextStickerRecommendLibView

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
    UIImageView *libIcon = [[UIImageView alloc] initWithImage:ACCResourceImage(@"text_lib_icon")];
    [self addSubview:libIcon];
    ACCMasMaker(libIcon, {
        make.width.equalTo(@32.f);
        make.height.equalTo(@32.f);
        make.left.top.equalTo(self);
    });
    UILabel *libLabel = [[UILabel alloc] init];
    libLabel.text = @"文案库";
    libLabel.textAlignment = NSTextAlignmentRight;
    libLabel.textColor = [UIColor whiteColor];
    libLabel.font = [UIFont acc_systemFontOfSize:14.f weight:ACCFontWeightMedium];
    libLabel.userInteractionEnabled = YES;
    [self addSubview:libLabel];
    ACCMasMaker(libLabel, {
        make.width.equalTo(@45.f);
        make.height.equalTo(@32.f);
        make.right.centerY.equalTo(self);
    });
}

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return @"文案库";
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitButton;
}

@end


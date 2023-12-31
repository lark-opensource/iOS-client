//
//  AWEModernStickerContentCollectionViewCell.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/15.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEModernStickerContentCollectionViewCell.h"
#import "AWEModernStickerCollectionViewCell.h"
#import <CreationKitInfra/AWEModernStickerDefine.h>
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <CreativeKit/UIDevice+ACCHardware.h>

@implementation AWEModernStickerContentInnerCollectionView

+ (UICollectionViewFlowLayout *)defaultFlowLayout
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];

    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat itemWidth = screenWidth * 71.5 / 375;
    CGFloat insetWidth = (screenWidth - itemWidth * 5) / 2;
    // Adaption for iPad device.
    if ([UIDevice acc_isIPad]) {
        itemWidth = 414.0f * 71.5 / 375.0f;
        insetWidth = (414.0f - itemWidth * 5) / 2.0f;
    }
    flowLayout.itemSize = CGSizeMake(itemWidth, itemWidth + 14.0); // 14.0 for prop name label height
    flowLayout.sectionInset = UIEdgeInsetsMake(insetWidth, insetWidth, insetWidth, insetWidth);
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.minimumLineSpacing = 0;
    return flowLayout;
}

+ (AWEModernStickerContentInnerCollectionView *)defaultCollectionView
{
    UICollectionViewFlowLayout *flowLayout = [AWEModernStickerContentInnerCollectionView defaultFlowLayout];
    AWEModernStickerContentInnerCollectionView *collectionView = [[AWEModernStickerContentInnerCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    if (@available(iOS 10.0, *)) {
        collectionView.prefetchingEnabled = NO;
    }
    collectionView.backgroundColor = [UIColor clearColor];
    [collectionView registerClass:[AWEModernStickerCollectionViewCell class] forCellWithReuseIdentifier:[AWEModernStickerCollectionViewCell identifier]];
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.allowsMultipleSelection = NO;
    
    return collectionView;
}

- (void)clearSelectedCellsForSelectedModel:(IESEffectModel *)selectedModel
{
    for (UICollectionViewCell *cell in self.visibleCells) {
        if ([cell isKindOfClass:[AWEModernStickerCollectionViewCell class]]) {
            AWEModernStickerCollectionViewCell *stickerCell = (AWEModernStickerCollectionViewCell *)cell;
            if ([stickerCell.effect.effectIdentifier isEqualToString:selectedModel.effectIdentifier]) {
                [stickerCell makeUnselected];
                [stickerCell stopLoadingAnimation];
            }
        }
    }
}

@end

@interface AWEModernStickerContentCollectionViewCell ()

@property (nonatomic, copy) NSArray *effectArray;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, assign) NSInteger section;
@end

@implementation AWEModernStickerContentCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        [self addSubviews];
    }
    return self;
}

- (void)addSubviews
{
    [self.contentView addSubview:self.collectionView];
    ACCMasMaker(self.collectionView, {
        make.edges.equalTo(self);
    });
//    [self.collectionView reloadData];

    [self.contentView addSubview:self.emptyLabel];
    ACCMasMaker(self.emptyLabel, {
        make.left.equalTo(self.contentView).offset(20.f);
        make.right.equalTo(self.contentView).offset(-20.f);
        make.centerY.equalTo(self.contentView);
        make.height.equalTo(@(40.f));
    });
}

- (AWEModernStickerContentInnerCollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [AWEModernStickerContentInnerCollectionView defaultCollectionView];
        _collectionView.tag = AWEModernStickerCollectionViewTagSticker * 1000;
    }
    return _collectionView;
}

- (void)setCollectionViewDataSource:(id<UICollectionViewDataSource>)dataSource delegate:(id<UICollectionViewDelegate>)delegate section:(NSInteger)section
{
	self.section = section;
	self.collectionView.dataSource = dataSource;
	self.collectionView.delegate = delegate;
    [self.collectionView setContentOffset:CGPointMake(0, 0) animated:NO];
	[self.collectionView reloadData];
}

- (void)setSection:(NSInteger)section
{
	_section = section;
	self.collectionView.tag = section;
}

- (UILabel *)emptyLabel {
    if (!_emptyLabel) {
        _emptyLabel = [[UILabel alloc] acc_initWithFontSize:15 isBold:NO textColor:ACCResourceColor(ACCUIColorTextS1) text:@""];
        _emptyLabel.numberOfLines = 0;
        _emptyLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary4);
        _emptyLabel.textAlignment = NSTextAlignmentCenter;
        _emptyLabel.hidden = YES;
    }
    return _emptyLabel;
}

- (void)configWithEmptyString:(NSString *)emptyString
{
    if (emptyString) {
        self.emptyLabel.text = emptyString;
        self.emptyLabel.hidden = NO;
        CGSize size = [self.emptyLabel sizeThatFits:CGSizeMake(self.contentView.frame.size.width - 40.f, CGFLOAT_MAX)];
        if (size.height > 40.f) {
            ACCMasUpdate(self.emptyLabel, {
                make.height.equalTo(@(size.height));
            });
            [self.emptyLabel layoutIfNeeded];
        }
        self.collectionView.hidden = YES;
    } else {
        self.emptyLabel.text = @"";
        self.emptyLabel.hidden = YES;
        self.collectionView.hidden = NO;
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.emptyLabel.text = @"";
    self.emptyLabel.hidden = YES;
    self.collectionView.hidden = NO;
}

@end

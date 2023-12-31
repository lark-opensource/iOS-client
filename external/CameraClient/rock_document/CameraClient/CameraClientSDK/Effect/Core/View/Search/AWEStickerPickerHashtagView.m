//
//  AWEStickerPickerHashtagView.m
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/5/24.
//

#import "AWEStickerPickerHashtagView.h"
#import "AWEStickerPickerHashtagCollectionViewCell.h"
#import "ACCConfigKeyDefines.h"

#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCPersonalRecommendWords.h"

static inline BOOL useSearchOptimization() {
    return ACCConfigBool(kConfigBool_studio_optimize_prop_search_experience);
}

@interface AWEPropSearchHashtagCollectionLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) CGSize currentContentSize;
@property (nonatomic, copy) NSArray *attributesArray;

@property (nonatomic, assign) NSInteger numberOfRows;
@property (nonatomic, assign) CGFloat spacingX;
@property (nonatomic, assign) CGFloat SpacingY;
@property (nonatomic, assign) BOOL isMoreThanOneLine;

@end

@implementation AWEPropSearchHashtagCollectionLayout

- (void)prepareLayout
{
    [super prepareLayout];

    NSMutableArray *attributesArray = [NSMutableArray array];
    NSInteger count = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
    for (NSInteger idx = 0; idx < count; ++idx) {
        [attributesArray addObject:[self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:idx inSection:0]]];
    }

    NSMutableArray *xArray = [NSMutableArray array];
    for (NSInteger idx = 0; idx < self.numberOfRows; ++idx) {
        [xArray addObject:@(self.sectionInset.left)];
    }

    __block CGFloat maxY = 0;
    self.isMoreThanOneLine = NO;
    [attributesArray enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *attributes, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!self.isMoreThanOneLine) {
            NSNumber *min = [xArray firstObject];
            NSInteger index = [xArray indexOfObject:min];
            
            CGRect frame = attributes.frame;
            if ([min floatValue] + frame.size.width > ACC_SCREEN_WIDTH) {
                self.isMoreThanOneLine = YES;
            } else {
                frame.origin.x = min.doubleValue;
                frame.origin.y = index * (frame.size.height + self.SpacingY) + self.sectionInset.top;
                attributes.frame = frame;
                
                xArray[index] = @(CGRectGetMaxX(frame) + self.spacingX);
                maxY = MAX(maxY, CGRectGetMaxY(frame));
                return;
            }
        }
        
        
        NSNumber *min = [xArray valueForKeyPath:@"@min.self"];
        NSInteger index = [xArray indexOfObject:min];
        if (!min || index == NSNotFound) {
            return;
        }

        CGRect frame = attributes.frame;
        frame.origin.x = min.doubleValue;
        frame.origin.y = index * (frame.size.height + self.SpacingY) + self.sectionInset.top;
        attributes.frame = frame;

        xArray[index] = @(CGRectGetMaxX(frame) + self.spacingX);
        maxY = MAX(maxY, CGRectGetMaxY(frame));
    }];

    CGFloat maxX = [[xArray valueForKeyPath:@"@max.self"] doubleValue] - self.spacingX;
    self.currentContentSize = CGSizeMake(maxX + self.sectionInset.right, maxY + self.sectionInset.bottom);
    self.attributesArray = attributesArray;
}

- (CGSize)collectionViewContentSize
{
    return self.currentContentSize;
}

- (nullable NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return self.attributesArray;
}

@end

@interface AWEStickerPickerHashtagView () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UILabel *label;

@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation AWEStickerPickerHashtagView 

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews
{
    [self addSubview:self.label];
    ACCMasMaker(self.label, {
        make.height.equalTo(@(18));
        make.top.equalTo(self.mas_top);
        make.left.equalTo(self.mas_left).offset(16);
    });

    [self addSubview:self.collectionView];
    if (useSearchOptimization()) {
        ACCMasMaker(self.collectionView, {
            make.height.equalTo(@(68));
            make.top.equalTo(self.label.mas_bottom).mas_offset(12);
            make.left.right.equalTo(self);
        });
    } else {
        ACCMasMaker(self.collectionView, {
            make.height.equalTo(@(66));
            make.top.equalTo(self.label.mas_bottom);
            make.left.right.equalTo(self);
        });
    }
}

- (void)setHashtagsList:(NSArray<NSString *> *)hashtagsList
{
    _hashtagsList = hashtagsList;
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {

    AWEStickerPickerHashtagCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[AWEStickerPickerHashtagCollectionViewCell identifier] forIndexPath:indexPath];
    if (cell) {
        [cell configCellWithTitle:[self.hashtagsList acc_objectAtIndex:indexPath.item]];
    }
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.hashtagsList) {
        return self.hashtagsList.count;
    }
    return 0;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate stickerPickerHashtagView:self didSelectCellWithTitle:[self.hashtagsList acc_objectAtIndex:indexPath.item] indexPath:indexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self p_titleLabelSizeWithTitle:[self.hashtagsList acc_objectAtIndex:indexPath.item]];
}

- (CGSize)p_titleLabelSizeWithTitle:(NSString *)title
{
    NSStringDrawingOptions opts = NSStringDrawingUsesLineFragmentOrigin;
    NSDictionary *attributes = @{
        NSFontAttributeName: [UIFont fontWithName:@"PingFangSC-Regular" size:12],
    };
    CGSize textSize = [title boundingRectWithSize:CGSizeMake(MAXFLOAT, 28)
                                          options:opts
                                       attributes:attributes
                                          context:nil].size;
    textSize.width += 24;   // left + right spacing is 12
    textSize.height = 28;
    return textSize;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        if (useSearchOptimization()) {
            AWEPropSearchHashtagCollectionLayout *layout = [[AWEPropSearchHashtagCollectionLayout alloc] init];
            layout.sectionInset = UIEdgeInsetsZero;
            layout.minimumLineSpacing = 0;     // spacing between cells
            layout.minimumInteritemSpacing = 12;
            layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            layout.numberOfRows = 2;
            layout.spacingX = 12;
            layout.SpacingY = 12;
            _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        } else {
            UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
            layout.sectionInset = UIEdgeInsetsZero;
            layout.minimumLineSpacing = 0;     // spacing between cells
            layout.minimumInteritemSpacing = 12;
            layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        }

        _collectionView.backgroundColor = [UIColor clearColor];

        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.allowsMultipleSelection = NO;
        _collectionView.contentInset = useSearchOptimization() ? UIEdgeInsetsMake(0, 16, 0, 16) : UIEdgeInsetsMake(14, 16, 24, 16);

        if (@available(iOS 10.0, *)) {
            _collectionView.prefetchingEnabled = NO;
        }

        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        
        [_collectionView registerClass:[AWEStickerPickerHashtagCollectionViewCell class]
                   forCellWithReuseIdentifier:[AWEStickerPickerHashtagCollectionViewCell identifier]];

    }
    return _collectionView;
}

- (UILabel *)label
{
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.font = [UIFont fontWithName:@"PingFangSC-Medium" size:13];
        _label.textColor = ACCResourceColor(ACCUIColorConstTextTertiary4);
        _label.textAlignment = NSTextAlignmentCenter;
        _label.text = ACCPersonalRecommendGetWords(@"sticker_picker_hastag_view");
    }

    return _label;
}

@end

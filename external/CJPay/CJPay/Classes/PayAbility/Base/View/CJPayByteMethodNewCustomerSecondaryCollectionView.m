//
//  CJPayByteMethodNewCustomerSecondaryCollectionView.m
//  CJPaySandBox
//
//  Created by 郑秋雨 on 2022/12/21.
//

#import "CJPayByteMethodNewCustomerSecondaryCollectionView.h"
#import "CJPayByteMethodNewCustomerSecondaryCollectionViewCell.h"
#import "CJPayUIMacro.h"
#import "CJPayChannelBizModel.h"
#import "CJPayBytePayMethodView.h"

@interface CJPayByteMethodNewCustomerSecondaryCollectionView()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) CJPayChannelBizModel *data;

@end

@implementation CJPayByteMethodNewCustomerSecondaryCollectionView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.collectionView];
    
    CJPayMasMaker(self.collectionView, {
        make.edges.mas_equalTo(self);
    })
}

#pragma mark -  UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 3;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger lastCellIndex = 2;
    UICollectionViewCell *cell = nil;
    if (indexPath.row != lastCellIndex) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([CJPayByteMethodNewCustomerSecondaryCollectionViewBankSelectedCell class]) forIndexPath:indexPath];
        [(CJPayByteMethodNewCustomerSecondaryCollectionViewBankSelectedCell *)cell loadData:[self.data.subPayTypeData objectAtIndex:indexPath.row]];
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([CJPayByteMethodNewCustomerSecondaryCollectionViewMoreCell class]) forIndexPath:indexPath];
    }
    return cell;
}

#pragma  mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.subPayDelegate && [self.subPayDelegate respondsToSelector:@selector(didSelectNewCustomerSubCell:)]) {
        [self.subPayDelegate didSelectNewCustomerSubCell:indexPath.row];
    }
}
#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger lastCellIndex = 2;
    CGFloat height = 0;
    CGFloat width = 0;
    if (indexPath.row != lastCellIndex) {
        width = CJ_SCREEN_WIDTH <= 420 ? 124 : 138;
        height = 48;
    } else {
        width = CJ_SCREEN_WIDTH <= 420 ? 58 : 74;
        height = 48;
    }
    return CGSizeMake(width, height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 8;
}

#pragma mark - common func
- (void)reloadData:(CJPayChannelBizModel *)data {
    self.data = data;
    [self.collectionView reloadData];
}

#pragma mark - lazy load
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flowLayout.sectionInset = UIEdgeInsetsMake(6, 0, 0, 0);
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.allowsSelection = YES;
        _collectionView.backgroundColor = [UIColor whiteColor];
        
        [_collectionView registerClass:[CJPayByteMethodNewCustomerSecondaryCollectionViewBankSelectedCell class] forCellWithReuseIdentifier:NSStringFromClass([CJPayByteMethodNewCustomerSecondaryCollectionViewBankSelectedCell class])];
        [_collectionView registerClass:[CJPayByteMethodNewCustomerSecondaryCollectionViewMoreCell class] forCellWithReuseIdentifier:NSStringFromClass([CJPayByteMethodNewCustomerSecondaryCollectionViewMoreCell class])];
    }
    return _collectionView;
}
@end

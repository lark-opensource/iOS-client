//
//  CJPayBytePayMethodCreditPayCollectionView.m
//  Pods
//
//  Created by bytedance on 2021/8/5.
//

#import "CJPayBytePayMethodCreditPayCollectionView.h"
#import "CJPayBytePayMethodCreditPayItemCell.h"
#import "CJPayChannelBizModel.h"
#import "CJPayUIMacro.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"

@interface CJPayBytePayMethodCreditPayCollectionView ()<UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end

@implementation CJPayBytePayMethodCreditPayCollectionView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.collectionView.backgroundColor = [UIColor clearColor];
        [self setupUI];
    }
    return self;
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    
    self.collectionView.hidden = hidden;
}

- (void)setupUI {
    [self addSubview:self.collectionView];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
        flowLayout.itemSize = CGSizeMake(124, 52);
        flowLayout.minimumLineSpacing = 10;
        flowLayout.minimumInteritemSpacing = 10;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.showsHorizontalScrollIndicator = false;
        _collectionView.allowsSelection = true;
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.contentInset = UIEdgeInsetsMake(6, 0, 0, 0);//6是营销卡片突出来的高度
        [_collectionView registerClass:[CJPayBytePayMethodCreditPayItemCell class] forCellWithReuseIdentifier:NSStringFromClass([CJPayBytePayMethodCreditPayItemCell class])];
    }
    return _collectionView;
}

- (void)reloadData {
    [self.collectionView reloadData];
    
    @CJWeakify(self)
    
    [self.creditPayMethods enumerateObjectsUsingBlock:^(CJPayBytePayCreditPayMethodModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self)
        if (obj.choose == YES) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:(self.scrollAnimated && self.selectedIndexPath)];
            });
        }
    }];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.creditPayMethods.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CJPayBytePayMethodCreditPayItemCell *cell = (CJPayBytePayMethodCreditPayItemCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([CJPayBytePayMethodCreditPayItemCell class]) forIndexPath:indexPath];
    if (cell) {
        cell.model = [self.creditPayMethods objectAtIndex:indexPath.row];
        return cell;
    } else {
        return [CJPayBytePayMethodCreditPayItemCell new];
    }
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndexPath = indexPath;
    CJPayBytePayCreditPayMethodModel *obj = (CJPayBytePayCreditPayMethodModel *)[self.creditPayMethods objectAtIndex:indexPath.row];
    if ([obj.status isEqualToString:@"0"]) {
        return;
    }
    @CJWeakify(self)
    [self.creditPayMethods enumerateObjectsUsingBlock:^(CJPayBytePayCreditPayMethodModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self)
        if (idx == indexPath.row) {
            obj.choose = YES;
            CJ_CALL_BLOCK(self.clickBlock, obj.installment);
        } else {
            obj.choose = NO;
        }
    }];
    [self reloadData];
}

@end

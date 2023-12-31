//
//  CJPayByteMethodNewCustomerSecondaryCell.m
//  CJPaySandBox
//
//  Created by 郑秋雨 on 2022/12/21.
//

#import "CJPayByteMethodNewCustomerSecondaryCell.h"
#import "CJPayByteMethodNewCustomerSecondaryCollectionView.h"
#import "CJPayMehtodDataUpdateProtocol.h"
#import "CJPayBytePayMethodView.h"
#import "CJPayUIMacro.h"

@interface CJPayByteMethodNewCustomerSecondaryCell() <CJPayMethodDataUpdateProtocol>

@property (nonatomic, strong) CJPayByteMethodNewCustomerSecondaryCollectionView *collectionView;
@property (nonatomic, strong) CJPayChannelBizModel *data;

@end

@implementation CJPayByteMethodNewCustomerSecondaryCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self.contentView addSubview:self.collectionView];
    
    CJPayMasMaker(self.collectionView, {
        make.left.mas_equalTo(52);
        make.top.bottom.right.mas_equalTo(self.contentView);
    });
}

#pragma mark - CJPayMehtodDataUpdateProtocol

- (void)updateContent:(CJPayChannelBizModel *)data {
    [self.collectionView reloadData:data];
    self.collectionView.subPayDelegate = self.subPayDelegate;
}

+ (NSNumber *)calHeight:(CJPayChannelBizModel *)data {
    return @(54);
}

#pragma mark - common func

#pragma mark - lazy load
- (CJPayByteMethodNewCustomerSecondaryCollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[CJPayByteMethodNewCustomerSecondaryCollectionView alloc] init];
    }
    return _collectionView;
}

@end

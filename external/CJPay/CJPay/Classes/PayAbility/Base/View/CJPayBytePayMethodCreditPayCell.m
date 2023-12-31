//
//  CJPayBytePayMethodCreditPayCell.m
//  Pods
//
//  Created by bytedance on 2021/7/26.
//

#import "CJPayBytePayMethodCreditPayCell.h"
#import "CJPayBytePayMethodCreditPayItemCell.h"
#import "CJPayChannelBizModel.h"
#import "CJPayUIMacro.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayBytePayMethodCreditPayCollectionView.h"

@interface CJPayBytePayMethodCreditPayCell ()

@property (nonatomic, strong) CJPayBytePayMethodCreditPayCollectionView *collectionView;
@property (nonatomic, copy) NSArray<CJPayBytePayCreditPayMethodModel> *creditPayMethods;

@end

@implementation CJPayBytePayMethodCreditPayCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [self setupUI];
    }
    return self;
}

- (void)setClickBlock:(void (^)(NSString *))clickBlock {
    self.collectionView.clickBlock = clickBlock;
}

- (void)setupUI {
    [super setupUI];
    
    CJPayMasReMaker(self.bankIconView, {
        make.left.equalTo(self.contentView).offset(16);
        make.width.height.mas_equalTo(24);
        make.centerY.equalTo(self.titleLabel);
    });

    CJPayMasReMaker(self.titleLabel, {
        make.top.equalTo(self.contentView).offset(16);
        self.titleLabelCenterBaseContentViewConstraint = nil;
        self.titleLabelLeftBaseIconImageViewConstraint = make.left.equalTo(self.bankIconView.mas_right).offset(12);
        make.right.lessThanOrEqualTo(self.confirmImageView.mas_left);
    });
    
    CJPayMasReMaker(self.rightArrowImage, {
        make.centerY.equalTo(self.titleLabel);
        make.right.equalTo(self).offset(-16);
        make.width.height.mas_equalTo(16);
    });
    
    [self.contentView addSubview:self.collectionView];
    
    CJPayMasMaker(self.collectionView, {
        make.top.equalTo(self.bankIconView.mas_bottom).offset(14);
        make.height.mas_equalTo(58);
        make.left.equalTo(self.titleLabel);
        make.right.equalTo(self.rightArrowImage);
    });
    
}

- (CJPayBytePayMethodCreditPayCollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[CJPayBytePayMethodCreditPayCollectionView alloc] init];
        _collectionView.scrollAnimated = NO;
    }
    return _collectionView;
}

#pragma mark - CJPayMethodDataUpdateProtocol
- (void)updateContent:(CJPayChannelBizModel *)model
{
    [super updateContent:model];
    
    if ([model.channelConfig.payChannel isKindOfClass:CJPaySubPayTypeInfoModel.class]) {
        CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)model.channelConfig.payChannel;
        self.creditPayMethods = payChannel.payTypeData.creditPayMethods;
        self.collectionView.creditPayMethods = payChannel.payTypeData.creditPayMethods;
        self.collectionView.hidden = !model.enable || !payChannel.payTypeData.creditPayMethods;
    }
    [self.collectionView reloadData];
}

+ (NSNumber *)calHeight:(CJPayChannelBizModel *)data
{
    return @116;
}

@end

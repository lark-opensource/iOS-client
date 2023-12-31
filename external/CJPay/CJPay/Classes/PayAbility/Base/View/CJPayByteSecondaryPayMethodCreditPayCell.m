//
//  CJPayByteSecondaryPayMethodCreditPayCell.m
//  Pods
//
//  Created by bytedance on 2021/7/29.
//

#import "CJPayByteSecondaryPayMethodCreditPayCell.h"
#import "CJPayBytePayMethodCreditPayItemCell.h"
#import "CJPayChannelBizModel.h"
#import "CJPayUIMacro.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayBytePayMethodCreditPayCollectionView.h"

@interface CJPayByteSecondaryPayMethodCreditPayCell ()

@property (nonatomic, strong) CJPayBytePayMethodCreditPayCollectionView *collectionView;
@property (nonatomic, copy) NSArray<CJPayBytePayCreditPayMethodModel> *creditPayMethods;

@end

@implementation CJPayByteSecondaryPayMethodCreditPayCell

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
    
    CJPayMasMaker(self.titleLabel, {
        make.height.mas_equalTo(CJ_SIZE_FONT_SAFE(14));
        self.titleLabelLeftBaseSelfConstraint = make.left.equalTo(self.contentView).offset(56);
        self.titleLabelCenterYBaseSelfConstraint = nil;
        self.titleLabelTopBaseSelfConstraint = make.top.equalTo(self.contentView).offset(10);
    });
    
    [self.contentView addSubview:self.collectionView];
    self.collectionView.frame = CGRectMake(52, 48, CJ_SCREEN_WIDTH - 52 - 10, 58);
}

- (CJPayBytePayMethodCreditPayCollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[CJPayBytePayMethodCreditPayCollectionView alloc] init];
        _collectionView.scrollAnimated = YES;
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
    }
    [self.collectionView reloadData];
}

+ (NSNumber *)calHeight:(CJPayChannelBizModel *)data
{
    if ([data.channelConfig.payChannel isKindOfClass:[CJPaySubPayTypeInfoModel class]]) {
        CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)data.channelConfig.payChannel;
        if ([payChannel.payTypeData.creditPayMethods count]) {
            return @(48 + 58 + 8);
        } else {
            return @48;
        }
    } else {
        return @48;
    }
}

@end

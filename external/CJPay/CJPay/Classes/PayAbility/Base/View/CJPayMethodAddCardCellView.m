//
//  CJPayMethodAddCardCellView.m
//  CJPay
//
//  Created by 王新华 on 9/3/19.
//

#import "CJPayMethodAddCardCellView.h"
#import "CJPayCurrentTheme.h"
#import "CJPayLineUtil.h"
#import "CJPayMethodCellTagView.h"
#import "CJPayChannelBizModel.h"

@interface CJPayMethodAddCardCellView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *addIconImageView;
@property (nonatomic, strong) CJPayMethodCellTagView *discountView;
@property (nonatomic, strong) CJPayMethodCellTagView *rightDiscountView;

@property (nonatomic, strong) CJPayChannelBizModel *model;

@end

@implementation CJPayMethodAddCardCellView

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setupUI {
    self.contentView.backgroundColor = [UIColor whiteColor];
    [self.contentView addSubview:self.addIconImageView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.discountView];
    [self.contentView addSubview:self.arrowImageView];
    [self.contentView addSubview:self.seperateView];
    [self.contentView addSubview:self.rightDiscountView];
    
    CJPayMasMaker(self.addIconImageView, {
        make.left.equalTo(self).offset(16);
        make.centerY.equalTo(self);
        make.width.height.mas_equalTo(24);
    });
    
    CJPayMasMaker(self.titleLabel, {
        self.titleLabelLeftBaseIconImageConstraint = make.left.equalTo(self.addIconImageView.mas_right).offset(16);
        self.titleLabelCenterYBaseSelfConstraint = make.centerY.equalTo(self);
        self.titleLabelTopBaseSelfConstraint = make.top.equalTo(self).offset(11);
        make.height.mas_equalTo(CJ_SIZE_FONT_SAFE(16));
    });
    [self.titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [self.titleLabelCenterYBaseSelfConstraint deactivate];
    
    CJPayMasMaker(self.discountView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(6);
        make.left.equalTo(self.titleLabel);
        make.right.lessThanOrEqualTo(self.arrowImageView.mas_left).offset(-8);
        make.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.rightDiscountView, {
        make.left.equalTo(self.titleLabel.mas_right).offset(8);
        make.centerY.equalTo(self.titleLabel);
        make.right.lessThanOrEqualTo(self.arrowImageView.mas_left).offset(4);
    });
    
    CJPayMasMaker(self.arrowImageView, {
        make.right.equalTo(self).offset(-15);
        make.centerY.equalTo(self);
        make.width.height.mas_equalTo(20);
    });
}

- (void)updateContent:(CJPayChannelBizModel *)data {
    self.model = data;
    self.titleLabel.text = data.title;
    [self.discountView updateTitle:data.discountStr];
    [self.rightDiscountView updateTitle:data.rightDiscountStr];
    
    self.discountView.hidden = !Check_ValidString(data.discountStr);
    self.rightDiscountView.hidden = !Check_ValidString(data.rightDiscountStr);
    
    if (self.discountView.hidden) {
        [self.titleLabelTopBaseSelfConstraint deactivate];
        [self.titleLabelCenterYBaseSelfConstraint activate];
    } else {
        [self.titleLabelCenterYBaseSelfConstraint deactivate];
        [self.titleLabelTopBaseSelfConstraint activate];
    }
}

+ (NSNumber *)calHeight:(CJPayChannelBizModel *)data {
    return Check_ValidString(data.discountStr) ? @(60) : @(56);
}

#pragma mark - Getter
- (UIImageView *)addIconImageView
{
    if (!_addIconImageView) {
        _addIconImageView = [UIImageView new];
        [_addIconImageView cj_setImage:@"cj_addbankcard_icon"];
    }
    return _addIconImageView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = UIColor.cj_222222ff;
        _titleLabel.font = [self p_themeFontOfSize:16];
        _titleLabel.text = CJPayLocalizedStr(@"添加新卡支付");
    }
    return _titleLabel;
}

- (CJPayMethodCellTagView *)discountView
{
    if (!_discountView) {
        _discountView = [CJPayMethodCellTagView new];
    }
    return _discountView;
}

- (CJPayMethodCellTagView *)rightDiscountView {
    if (!_rightDiscountView) {
        _rightDiscountView = [CJPayMethodCellTagView new];
    }
    return _rightDiscountView;
}

- (UIFont *)p_themeFontOfSize:(CGFloat)size {
    return [UIFont cj_fontOfSize:size];
}

@end

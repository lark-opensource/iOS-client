//
//  CJPayMethodBannerCell.m
//  Pods
//
//  Created by youerwei on 2021/4/12.
//

#import "CJPayMethodBannerCell.h"
#import "CJPayUIMacro.h"
#import "CJPayButton.h"
#import "CJPayHomePageBannerModel.h"


@interface CJPayMethodBannerCell ()

@property (nonatomic, strong) UIView *bannerView;
@property (nonatomic, strong, readwrite) UILabel *bannerTextLabel;
@property (nonatomic, strong, readwrite) CJPayButton *bannerButton;
@property (nonatomic, copy) NSString *labelAction;

@property (nonatomic, strong) CJPayChannelBizModel *bizModel;
@property (nonatomic, assign) CJPayChannelType type;
@end

@implementation CJPayMethodBannerCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self.contentView addSubview:self.bannerView];
    [self.bannerView addSubview:self.bannerTextLabel];
    [self.bannerView addSubview:self.bannerButton];
    
    CJPayMasMaker(self.bannerView, {
        make.top.bottom.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(40);
        make.right.equalTo(self.contentView).offset(-8);
        make.bottom.equalTo(self.contentView).offset(-4);
    });
    
    CJPayMasMaker(self.bannerTextLabel, {
        make.left.equalTo(self.contentView).offset(52);
        make.right.equalTo(self.bannerButton.mas_left).offset(-20);
        make.centerY.equalTo(self.bannerView);
    });
    
    CJPayMasMaker(self.bannerButton, {
        make.right.equalTo(self.bannerView).offset(-8);
        make.centerY.equalTo(self.bannerView);
        make.width.mas_equalTo(56);
        make.height.mas_equalTo(22);
    });
}

- (void)updateContent:(CJPayChannelBizModel *)model {
    self.bizModel = model;
    self.type = model.type;
    self.bannerTextLabel.text = CJString(model.title);// @"零钱余额 200.00元 可用于组合支付";
    [self.bannerButton cj_setBtnTitle:CJString(model.subTitle)];
}

+ (NSNumber *)calHeight:(CJPayChannelBizModel *)data {
    return @(44);
}

- (UIView *)bannerView {
    if (!_bannerView) {
        _bannerView = [UIView new];
        _bannerView.backgroundColor = [UIColor cj_fe2c55WithAlpha:0.06];
        _bannerView.layer.cornerRadius = 4;
        _bannerView.clipsToBounds = YES;
    }
    return _bannerView;
}

- (UILabel *)bannerTextLabel {
    if (!_bannerTextLabel) {
        _bannerTextLabel = [UILabel new];
        _bannerTextLabel.textColor = [UIColor cj_fe2c55ff];
        _bannerTextLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _bannerTextLabel;
}

- (CJPayButton *)bannerButton {
    if (!_bannerButton) {
        _bannerButton = [CJPayButton new];
        _bannerButton.backgroundColor = [UIColor clearColor];
        [_bannerButton setTitleColor:[UIColor cj_fe2c55ff] forState:UIControlStateNormal];
        _bannerButton.titleLabel.font = [UIFont cj_fontOfSize:11];
        _bannerButton.layer.cornerRadius = 4;
        _bannerButton.clipsToBounds = YES;
        _bannerButton.layer.borderColor = [[UIColor cj_fe2c55ff] CGColor];
        _bannerButton.layer.borderWidth = CJ_PIXEL_WIDTH;
        [_bannerButton addTarget:self action:@selector(p_bannerButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _bannerButton;
}

- (void)p_bannerButtonClick {
    CJ_CALL_BLOCK(self.clickBlock, self.type);
}

@end

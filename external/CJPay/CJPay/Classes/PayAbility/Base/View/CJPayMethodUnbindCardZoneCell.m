//
//  CJPayMethodUnbindCardZoneCell.m
//  cjpayBankLock
//
//  Created by shanghuaijun on 2023/2/15.
//

#import "CJPayMethodUnbindCardZoneCell.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayChannelBizModel.h"

@implementation CJPayMethodUnbindCardZoneCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self.contentView addSubview:self.separatorView];
    [self.contentView addSubview:self.titleLabel];
    
    CJPayMasMaker(self.separatorView, {
        make.top.left.right.equalTo(self.contentView);
        make.height.mas_equalTo(8);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.top.equalTo(self.separatorView.mas_bottom).offset(20);
    });
}

+ (NSNumber *)calHeight:(CJPayChannelBizModel *)data {
    return @(50);
}

- (void)updateContent:(CJPayChannelBizModel *)data {
    self.titleLabel.text = CJString(data.title);
}

- (UIView *)separatorView {
    if (!_separatorView) {
        _separatorView = [UIView new];
        _separatorView.backgroundColor = [UIColor cj_161823WithAlpha:0.03];
    }
    return _separatorView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _titleLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _titleLabel;
}

@end

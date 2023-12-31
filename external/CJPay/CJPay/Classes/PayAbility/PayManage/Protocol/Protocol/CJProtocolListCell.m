//
//  CJProtocolListCell.m
//  CJPay
//
//  Created by 张海阳 on 2019/6/25.
//

#import "CJProtocolListCell.h"
#import "CJPayUIMacro.h"

@interface CJProtocolListCell ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;

@end

@implementation CJProtocolListCell

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_fontOfSize:15];
        _titleLabel.textColor = [UIColor cj_colorWithHexString:@"222222" alpha:1];
    }
    return _titleLabel;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [UIImageView new];
        [_arrowImageView cj_setImage:@"cj_arrow_icon"];
    }
    return _arrowImageView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.arrowImageView];
    
    CJPayMasMaker(self.titleLabel, {
        make.left.equalTo(self.titleLabel.superview).offset(15);
        make.right.equalTo(self.titleLabel.superview).offset(-47);
        make.centerY.equalTo(self.titleLabel.superview);
    });
    
    CJPayMasMaker(self.arrowImageView, {
        make.right.equalTo(self.titleLabel.superview).offset(-15);
        make.centerY.equalTo(self.titleLabel.superview);
        make.width.height.mas_equalTo(20);
    });
}

@end

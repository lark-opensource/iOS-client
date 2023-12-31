//
//  CJPayECHalfNotSufficientViewController.m
//  Pods
//
//  Created by 王新华 on 2021/6/3.
//

#import "CJPayECHalfNotSufficientViewController.h"
#import "CJPayStyleButton.h"
#import "CJPayUIMacro.h"

@interface CJPayEcommerceNotSufficientView : UIView

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLable;
@property (nonatomic, strong) CJPayStyleButton *changePayMethodBtn;

- (void)updateContent:(NSString *)content;

@end

@implementation CJPayEcommerceNotSufficientView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.iconView];
    [self addSubview:self.titleLable];
    [self addSubview:self.changePayMethodBtn];
    
    CJPayMasMaker(self.iconView, {
        make.centerX.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(60, 60));
        make.top.equalTo(self).offset(100);
    });
    CJPayMasMaker(self.titleLable, {
        make.centerX.equalTo(self);
        make.top.equalTo(self.iconView.mas_bottom).offset(16);
        make.width.lessThanOrEqualTo(self).offset(-32);
    });
    CJPayMasMaker(self.changePayMethodBtn, {
        make.size.mas_equalTo(CGSizeMake(160, 40));
        make.centerX.equalTo(self);
        make.top.equalTo(self.titleLable.mas_bottom).offset(24);
    });
}

- (void)updateContent:(NSString *)content {
    self.titleLable.text = content;
}

- (UIImageView *)iconView {
    if (!_iconView) {
        _iconView = [UIImageView new];
        [_iconView cj_setImage:@"cj_sorry_icon"];
        
    }
    return _iconView;
}

- (UILabel *)titleLable {
    if (!_titleLable) {
        _titleLable = [UILabel new];
        _titleLable.numberOfLines = 1;
        _titleLable.font = [UIFont cj_boldFontOfSize:16];
        _titleLable.textColor = [UIColor cj_161823ff];
        _titleLable.textAlignment = NSTextAlignmentCenter;
        _titleLable.adjustsFontSizeToFitWidth = YES;
    }
    return _titleLable;
}

- (CJPayStyleButton *)changePayMethodBtn {
    if (!_changePayMethodBtn) {
        _changePayMethodBtn = [CJPayStyleButton new];
        _changePayMethodBtn.titleLabel.font = [UIFont cj_boldFontOfSize:14];
        [_changePayMethodBtn setTitle:CJPayLocalizedStr(@"更换支付方式") forState:UIControlStateNormal];
    }
    return _changePayMethodBtn;
}

@end

@interface CJPayECHalfNotSufficientViewController()

@property (nonatomic, strong) CJPayEcommerceNotSufficientView *notsufficientView;

@end

@implementation CJPayECHalfNotSufficientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = CJPayDYPayTitleMessage;
    [self useCloseBackBtn];
    
    [self.contentView addSubview:self.notsufficientView];
    CJPayMasMaker(self.notsufficientView, {
        make.edges.equalTo(self.contentView);
    });
    [self.notsufficientView updateContent:self.showTitle ?: CJPayLocalizedStr(@"余额不足")];
    self.exitAnimationType = HalfVCEntranceTypeFromBottom;
}

- (CJPayEcommerceNotSufficientView *)notsufficientView {
    if (!_notsufficientView) {
        _notsufficientView = [CJPayEcommerceNotSufficientView new];
        @CJWeakify(self);
        [_notsufficientView.changePayMethodBtn btd_addActionBlock:^(__kindof UIControl * _Nonnull sender) {
            @CJStrongify(self);
            [self back];
        } forControlEvents:UIControlEventTouchUpInside];
    }
    return _notsufficientView;
}

- (CGFloat)containerHeight {
    if (self.height <= CGFLOAT_MIN) {
        return CJ_HALF_SCREEN_HEIGHT_LOW;
    } else {
        return self.height;
    }
}

@end

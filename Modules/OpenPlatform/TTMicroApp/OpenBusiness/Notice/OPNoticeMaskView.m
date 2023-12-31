//
//  OPNoticeMaskView.m
//  TTMicroApp
//
//  Created by ChenMengqi on 2021/8/9.
//

#import "OPNoticeMaskView.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/UIFont+BDPExtension.h>
#import <Masonry/Masonry.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

@interface OPNoticeMaskView()

///点击“管理员发布”后的通知内容
@property (nonatomic, strong) UIView *tipView;
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UIView *bkgView;

@end

@implementation OPNoticeMaskView

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self addGesture];
        [self loadSubview];
        [self setAutoLayout];
    }
    return self;
}

-(void)addGesture{
    UITapGestureRecognizer *g = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnMaskview)];
    [self addGestureRecognizer:g];
}

-(void)setNoticeText:(NSString *)text{
    NSAttributedString *attText = [text bdp_attributedStringWithFontSize:14 lineHeight:22 lineBreakMode:NSLineBreakByTruncatingTail isBoldFontStyle:NO firstLineIndent:0 textAlignment:NSTextAlignmentLeft];
    self.tipLabel.attributedText = attText;
    
    [self.tipLabel sizeToFit];
}

-(void)loadSubview{
    [self addSubview:self.bkgView];
    [self addSubview:self.tipView];
    [self.tipView addSubview:self.tipLabel];
}

-(void)setAutoLayout{
    [self.bkgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    [self.tipView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(12);
        make.right.lessThanOrEqualTo(self).offset(-12);
        make.top.equalTo(self).offset(36);
    }];
    
    [self.tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.tipView).offset(8);
        make.right.equalTo(self.tipView).offset(-8);
        make.top.equalTo(self.tipView).offset(2);
        make.bottom.equalTo(self.tipView).offset(-8);
    }];
}

-(void)tapOnMaskview{
    [self removeFromSuperview];
}

-(UIView *)tipView{
    if(!_tipView){
        _tipView = [[UIView alloc] init];
        _tipView.backgroundColor = UDOCColor.N00;
        _tipView.layer.cornerRadius = 2;
    }
    return _tipView;
}

-(UILabel *)tipLabel{
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.numberOfLines = 0;
        _tipLabel.textColor = UDOCColor.textTitle;
        _tipLabel.font = [UIFont bdp_pingFongSCWithWeight:UIFontWeightMedium size:14.0];
    }
    return _tipLabel;
}

-(UIView *)bkgView{
    if (!_bkgView) {
        _bkgView = [[UIView alloc] init];
        _bkgView.backgroundColor = UDOCColor.N1000;
        _bkgView.alpha = 0.3;
    }
    return _bkgView;
}


@end

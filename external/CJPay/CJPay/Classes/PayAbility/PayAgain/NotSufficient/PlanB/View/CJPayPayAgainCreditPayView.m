//
//  CJPayPayAgainCreditPayView.m
//  Pods
//
//  Created by liutianyi on 2022/2/26.
//

#import "CJPayPayAgainCreditPayView.h"

#import "CJPayBytePayMethodCreditPayCollectionView.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"

@interface CJPayPayAgainCreditPayView ()

@property (nonatomic, strong) UIImageView *bankIconImageView;
@property (nonatomic, strong) UILabel *bankLabel;
@property (nonatomic, strong) CJPayBytePayMethodCreditPayCollectionView *collectionView;

@end

@implementation CJPayPayAgainCreditPayView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI
{
    [self addSubview:self.bankIconImageView];
    [self addSubview:self.bankLabel];
    [self addSubview:self.collectionView];
    
    CJPayMasMaker(self.bankIconImageView, {
        make.top.left.equalTo(self);
        make.width.height.mas_equalTo(20);
    });
    
    CJPayMasMaker(self.bankLabel, {
        make.left.equalTo(self.bankIconImageView.mas_right).offset(6);
        make.centerY.equalTo(self.bankIconImageView);
    });
    
    CJPayMasMaker(self.collectionView, {
        make.top.equalTo(self.bankIconImageView.mas_bottom).offset(12);
        make.left.equalTo(self);
        make.right.equalTo(self);
        make.height.mas_equalTo(58);//52+上营销卡片突出的6
    });
    
}

- (UIImageView *)bankIconImageView {
    if (!_bankIconImageView) {
        _bankIconImageView = [UIImageView new];
    }
    return _bankIconImageView;
}

- (UILabel *)bankLabel {
    if (!_bankLabel) {
        _bankLabel = [UILabel new];
        _bankLabel.textColor = [UIColor cj_161823ff];
        _bankLabel.font = [UIFont cj_boldFontOfSize:14];
        _bankLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _bankLabel;
}

- (CJPayBytePayMethodCreditPayCollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[CJPayBytePayMethodCreditPayCollectionView alloc] init];
        _collectionView.scrollAnimated = YES;
    }
    return _collectionView;
}

@end

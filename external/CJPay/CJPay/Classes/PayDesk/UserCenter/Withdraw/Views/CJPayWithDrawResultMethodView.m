//
//  BDPayWithDrawResultMethodView.m
//  CJPay
//
//  Created by 徐波 on 2020/4/3.
//

#import "CJPayWithDrawResultMethodView.h"

#import "CJPayThemeStyleManager.h"
#import "CJPayUIMacro.h"
#import "CJPayFullPageBaseViewController+Theme.h"

#import <BDWebImage/BDWebImage.h>

@interface CJPayWithDrawResultMethodView()

@property (nonatomic, strong, readwrite) UIImageView *imageView;
@property (nonatomic, strong, readwrite) UILabel *contentLabel;

@end

@implementation CJPayWithDrawResultMethodView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.imageView];
    [self addSubview:self.contentLabel];
    
    CJPayMasMaker(self.imageView, {
        make.left.centerY.equalTo(self);
        make.width.height.mas_equalTo(14);
    });
    
    CJPayMasMaker(self.contentLabel, {
        make.left.equalTo(self.imageView.mas_right).offset(4);
        make.centerY.right.top.bottom.equalTo(self);
    });
}

- (void)setImage:(UIImage *)image content:(NSString *)content {
    self.imageView.image = image;
    self.contentLabel.text = CJString(content);
}

- (void)setImageUrl:(NSString *)imageUrl content:(NSString *)content {
    if (imageUrl) {
        [_imageView cj_setImageWithURL:[NSURL URLWithString:imageUrl] placeholder:[UIImage cj_roundImageWithColor:[UIColor cj_skeletonScreenColor]]];
    } else {
        [_imageView cj_setImageWithURL:[NSURL URLWithString:imageUrl]];
    }
    
    _contentLabel.text = content;
}

#pragma mark - Getter
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [UIImageView new];
    }
    return _imageView;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [UILabel new];
        _contentLabel.font = [UIFont cj_fontOfSize:13];
        _contentLabel.numberOfLines = 2;
        _contentLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _contentLabel;
}

@end


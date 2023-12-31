//
//  CJPayImageLabelStateView.m
//  CJPay
//
//  Created by 王新华 on 2019/1/15.
//

#import "CJPayImageLabelStateView.h"
#import "CJPayCurrentTheme.h"
#import "CJPayUIMacro.h"
#import "CJPayStyleButton.h"
#import "CJPayStyleImageView.h"

@implementation CJPayStateShowModel

@end

@interface CJPayImageLabelStateView()

@property (nonatomic, strong) CJPayStyleImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CJPayStateShowModel *showModel;

@end

@implementation CJPayImageLabelStateView

- (instancetype)initWithModel:(CJPayStateShowModel *)model {
    self = [super init];
    if (self) {
        _showModel = model;
        [self setupUI];
    }
    return self;
}

- (void)p_updateContent {
    if (Check_ValidString(self.showModel.titleStr)) {
        self.titleLabel.text = self.showModel.titleStr;
    }
    
    if (Check_ValidString(self.showModel.titleAttributedStr.string)) {
        self.titleLabel.attributedText = self.showModel.titleAttributedStr;
    }
    
    if ([self.showModel.iconName hasPrefix:@"https"] || [self.showModel.iconName hasPrefix:@"http"]) {
        [self.imageView setBackgroundColor:[UIColor clearColor]];
        [self.imageView cj_loadGifAndOnceLoopWithURL:self.showModel.iconName duration:self.showModel.imgDurationTime];
    } else if ([self.showModel.iconName hasSuffix:@"gif"]) {
        [self.imageView cj_loadGifAndOnceLoop:self.showModel.iconName duration:0.3];
    } else {
        [self.imageView setImage:self.showModel.iconName backgroundColor:self.showModel.iconBackgroundColor];
    }
}

- (void)setupUI {
    [self p_updateContent];
    
    [self addSubview:self.imageView];
    [self addSubview:self.titleLabel];
    
    CJPayMasMaker(self.imageView, {
        make.top.mas_equalTo(self);
        make.centerX.mas_equalTo(self);
        make.size.mas_equalTo(CGSizeMake(60, 60));
    });

    CJPayMasMaker(self.titleLabel, {
        make.top.mas_equalTo(self.imageView.mas_bottom).offset(12);
        make.left.mas_equalTo(self).offset(40);
        make.right.mas_equalTo(self).offset(-40);
        make.height.mas_equalTo(29 * [UIFont cjpayFontScale]);
    });

    CJPayMasMaker(self, {
        make.bottom.equalTo(self.titleLabel);
    });
}

#pragma mark - lazy views

- (CJPayStyleImageView *)imageView
{
    if (!_imageView) {
        _imageView = [CJPayStyleImageView new];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _imageView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        CGFloat titleFontSize = CJ_SCREEN_WIDTH <= 320 ? 18 : 20;
        _titleLabel.font = [UIFont cj_boldFontOfSize:titleFontSize];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

@end

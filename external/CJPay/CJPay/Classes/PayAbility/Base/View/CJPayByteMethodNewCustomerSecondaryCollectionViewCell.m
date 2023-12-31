//
//  CJPayByteMethodNewCustomerSecondaryCollectionViewCell.m
//  CJPaySandBox
//
//  Created by 郑秋雨 on 2022/12/22.
//

#import "CJPayByteMethodNewCustomerSecondaryCollectionViewCell.h"

#import "CJPayUIMacro.h"
#import "CJPaySubPayTypeData.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPayPaddingLabel.h"

@interface CJPayByteMethodNewCustomerSecondaryCollectionViewBankSelectedCell()

@property (nonatomic, strong) UIView *canvasView;

@property (nonatomic, strong) UIImageView *iconImgView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CJPayPaddingLabel *marketingLabel;

@end

@implementation CJPayByteMethodNewCustomerSecondaryCollectionViewBankSelectedCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor whiteColor];
        [self setupUI];
        [self setupConstraints];
    }
    return self;
}

- (void)setupUI {
    [self.contentView addSubview:self.canvasView];
    [self.canvasView addSubview:self.iconImgView];
    [self.canvasView addSubview:self.titleLabel];
    [self.contentView addSubview:self.marketingLabel];
}

- (void)addDotToCanvasView:(NSString *)marketingText {
    self.marketingLabel.text = marketingText;
    
    CGFloat marketingLabelHeight = 14;
    CJPayMasMaker(self.marketingLabel, {
        make.height.mas_equalTo(marketingLabelHeight);
        make.left.mas_greaterThanOrEqualTo(self.canvasView.mas_left).mas_offset(8);
        make.right.mas_equalTo(self.canvasView.mas_right);
        make.centerY.mas_equalTo(self.canvasView.mas_top).mas_offset(1);
    });
}

- (void)setupConstraints {
    CJPayMasMaker(self.canvasView, {
        make.edges.mas_equalTo(self.contentView);
    });
    
    CJPayMasMaker(self.iconImgView, {
        make.left.mas_equalTo(self.canvasView).mas_offset(CJ_SCREEN_WIDTH <= 420 ? 12 : 19);
        make.top.mas_equalTo(self.canvasView).mas_offset(18.5);
        make.height.width.mas_equalTo(12);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.left.mas_equalTo(self.iconImgView.mas_right).mas_offset(4);
        make.top.mas_equalTo(self.canvasView).mas_offset(16);
        make.height.mas_equalTo(17);
        make.width.mas_equalTo(84);
    });
}

#pragma mark - common func
- (void)loadData:(CJPaySubPayTypeInfoModel *)data {
    if (data) {
        [self.iconImgView cj_setImageWithURL:[NSURL URLWithString:CJString(data.iconUrl)]];
        self.titleLabel.text = data.payTypeData.cardStyleShortName;
        [self setSelected:data.isChoosed];
        
        NSMutableString *dotText = [[NSMutableString alloc] init];
        int tagsCount = 0;
        for (NSString *label in data.payTypeData.subPayVoucherMsgList) {
            if (tagsCount > 0) {
                [dotText appendString:@"+"];
            }
            [dotText appendString:label];
            tagsCount++;
        }
        if (!Check_ValidString(dotText)) {
            self.marketingLabel.hidden = YES;
        } else {
            self.marketingLabel.hidden = NO;
            [self addDotToCanvasView:dotText];
        }
    }
}

- (void)setSelected:(BOOL)selected {
    if (selected) {
        self.titleLabel.textColor = [UIColor cj_fe2c55ff];
        self.canvasView.backgroundColor = [UIColor cj_fe2c55WithAlpha:0.06];
        self.canvasView.layer.borderWidth = 0.5;
        self.canvasView.layer.borderColor = [UIColor cj_fe2c55WithAlpha:0.34].CGColor;
    } else {
        self.titleLabel.textColor = [UIColor cj_colorWithRed:0.09 green:0.09 blue:0.14 alpha:0.90];
        self.canvasView.backgroundColor = [UIColor cj_colorWithRed:0.09 green:0.09 blue:0.14 alpha:0.03];
        self.canvasView.layer.borderWidth = 0;
    }
}

#pragma mark - lazy load
- (UIView *)canvasView {
    if (!_canvasView) {
        _canvasView = [[UIView alloc] init];
        _canvasView.backgroundColor = [UIColor cj_colorWithRed:0.09 green:0.09 blue:0.14 alpha:0.03];
        _canvasView.layer.cornerRadius = 4;
        _canvasView.layer.masksToBounds = YES;
    }
    return _canvasView;
}

- (UIImageView *)iconImgView {
    if (!_iconImgView) {
        _iconImgView = [[UIImageView alloc] init];
    }
    return _iconImgView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor cj_colorWithRed:0.09 green:0.09 blue:0.14 alpha:0.90];
        _titleLabel.font = [UIFont cj_fontOfSize:12];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (CJPayPaddingLabel *)marketingLabel {
    if (!_marketingLabel) {
        _marketingLabel = [[CJPayPaddingLabel alloc] init];
        _marketingLabel.backgroundColor = [UIColor colorWithRed:1.00 green:0.90 blue:0.92 alpha:1.00];
        _marketingLabel.layer.cornerRadius = 2;
        _marketingLabel.layer.masksToBounds = YES;
        _marketingLabel.textColor = [UIColor cj_fe2c55ff];
        _marketingLabel.font = [UIFont cj_fontOfSize:10];
        _marketingLabel.textAlignment = NSTextAlignmentCenter;
        _marketingLabel.textInsets = UIEdgeInsetsMake(0, 4, 0, 4);
    }
    return _marketingLabel;
}

@end


@interface CJPayByteMethodNewCustomerSecondaryCollectionViewMoreCell()

@property (nonatomic, strong) UIView *canvasView;

@property (nonatomic, strong) UILabel *showMoreTitle;
@property (nonatomic, strong) UIImageView *arrowImgView;

@end

@implementation CJPayByteMethodNewCustomerSecondaryCollectionViewMoreCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self setupConstraints];
    }
    return self;
}

- (void)setupUI {
    [self.contentView addSubview:self.canvasView];
    [self.canvasView addSubview:self.showMoreTitle];
    [self.canvasView addSubview:self.arrowImgView];
}

- (void)setupConstraints {
    CJPayMasMaker(self.canvasView, {
        make.edges.mas_equalTo(self.contentView);
    });
    
    CJPayMasMaker(self.showMoreTitle, {
        make.left.mas_equalTo(self.canvasView).mas_offset(CJ_SCREEN_WIDTH <= 420 ? 12 : 19);
        make.top.mas_equalTo(self.canvasView).mas_offset(16);
        make.height.mas_equalTo(17);
        make.width.mas_equalTo(24);
    });
    
    CJPayMasMaker(self.arrowImgView, {
        make.left.mas_equalTo(self.showMoreTitle.mas_right);
        make.centerY.mas_equalTo(self.showMoreTitle);
        make.height.width.mas_equalTo(12);
    })
}

#pragma mark - lazy load
- (UIView *)canvasView {
    if (!_canvasView) {
        _canvasView = [[UIView alloc] init];
        _canvasView.backgroundColor = [UIColor cj_colorWithRed:0.09 green:0.09 blue:0.14 alpha:0.03];
        _canvasView.layer.cornerRadius = 4;
        _canvasView.layer.masksToBounds = YES;
    }
    return _canvasView;
}

- (UILabel *)showMoreTitle {
    if (!_showMoreTitle) {
        _showMoreTitle = [[UILabel alloc] init];
        _showMoreTitle.textColor = [UIColor cj_colorWithRed:0.09 green:0.09 blue:0.14 alpha:0.9];
        _showMoreTitle.font = [UIFont cj_fontOfSize:12];
        _showMoreTitle.textAlignment = NSTextAlignmentCenter;
        _showMoreTitle.text = CJPayLocalizedStr(@"更多");
    }
    return _showMoreTitle;
}

- (UIImageView *)arrowImgView {
    if (!_arrowImgView) {
        _arrowImgView = [[UIImageView alloc] init];
        [_arrowImgView cj_setImage:@"cj_arrow_icon"];
        _arrowImgView.contentMode = UIViewContentModeRight;
    }
    return _arrowImgView;
}

@end

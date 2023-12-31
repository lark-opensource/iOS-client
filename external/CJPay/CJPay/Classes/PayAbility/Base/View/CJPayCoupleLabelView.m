//
//  CJPayCoupleLabelView.m
//  Pods
//
//  Created by 王新华 on 2021/8/3.
//

#import "CJPayCoupleLabelView.h"
#import "CJPayPaddingLabel.h"
#import "CJPayUIMacro.h"

@interface CJPayCoupleLabelView()

@property (nonatomic, strong) CJPayPaddingLabel *firstLabel;
@property (nonatomic, strong) CJPayPaddingLabel *secondLabel;

@end

@implementation CJPayCoupleLabelView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.firstLabel];
        [self addSubview:self.secondLabel];
        
        CJPayMasMaker(self.firstLabel, {
            make.centerY.left.equalTo(self);
            make.right.lessThanOrEqualTo(self);
            make.height.mas_equalTo(18);
        });
        CJPayMasMaker(self.secondLabel, {
            make.centerY.right.lessThanOrEqualTo(self);
            make.left.equalTo(self.firstLabel.mas_right).offset(8);
            make.height.mas_equalTo(18);
        });
        self.firstLabel.hidden = YES;
        self.secondLabel.hidden = YES;
    }
    return self;
}

- (void)updateCoupleLableForSignStatus {
    self.firstLabel.layer.borderColor = [UIColor cj_161823WithAlpha:0.5].CGColor;
    self.firstLabel.textColor = [UIColor cj_161823ff];
    self.firstLabel.font = [UIFont cj_fontOfSize:10];
    self.firstLabel.text = CJPayLocalizedStr(@"已签约");
    self.firstLabel.hidden = NO;
}

- (void)updateCoupleLabelContents:(NSArray<NSString *> *)titles {
    // 预处理下数据，移除掉内容为空的标签
    __block NSMutableArray *preProcessTitles = [NSMutableArray new];
    [titles enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (Check_ValidString(obj)) {
            [preProcessTitles addObject:obj];
        }
    }];
    
    if (preProcessTitles.firstObject) {
        self.firstLabel.layer.borderColor = [UIColor cj_fe2c55WithAlpha:0.5].CGColor;
        self.firstLabel.textColor = [UIColor cj_fe2c55ff];
        self.firstLabel.font = [UIFont cj_fontOfSize:11];
        self.firstLabel.text = preProcessTitles.firstObject;
        self.firstLabel.hidden = NO;
    } else {
        self.firstLabel.hidden = YES;
        self.firstLabel.text = @"";
    }
    if (preProcessTitles.count > 1) {
        self.secondLabel.text = preProcessTitles[1];
        self.secondLabel.hidden = NO;
    } else {
        self.secondLabel.hidden = YES;
        self.secondLabel.text = @"";
    }
}

- (CGSize)intrinsicContentSize {
    CGSize contentSize = CGSizeZero;
    if (Check_ValidString(self.firstLabel.text)) {
        contentSize = [self.firstLabel intrinsicContentSize];
        if (Check_ValidString(self.secondLabel.text)) {
            CGSize secondContentSize = [self.secondLabel intrinsicContentSize];
            contentSize = CGSizeMake(contentSize.width + 8 + secondContentSize.width, contentSize.height);
        }
    }
    return contentSize;
}

- (CJPayPaddingLabel *)firstLabel {
    if (!_firstLabel) {
        _firstLabel = [CJPayPaddingLabel new];
        _firstLabel.textInsets = UIEdgeInsetsMake(0, 2, 0, 2);
        _firstLabel.font = [UIFont cj_fontOfSize:11];
        _firstLabel.textColor = [UIColor cj_fe2c55ff];
        _firstLabel.layer.borderWidth = CJ_PIXEL_WIDTH;
        _firstLabel.textAlignment = NSTextAlignmentCenter;
        _firstLabel.layer.cornerRadius = 2;
        _firstLabel.layer.borderColor = [UIColor cj_fe2c55WithAlpha:0.5].CGColor;
        _firstLabel.backgroundColor = [UIColor clearColor];
    }
    return _firstLabel;
}

- (CJPayPaddingLabel *)secondLabel {
    if (!_secondLabel) {
        _secondLabel = [CJPayPaddingLabel new];
        _secondLabel.textInsets = UIEdgeInsetsMake(0, 2, 0, 2);
        _secondLabel.font = [UIFont cj_fontOfSize:11];
        _secondLabel.textColor = [UIColor cj_fe2c55ff];
        _secondLabel.layer.borderWidth = CJ_PIXEL_WIDTH;
        _secondLabel.textAlignment = NSTextAlignmentCenter;
        _secondLabel.layer.cornerRadius = 2;
        _secondLabel.layer.borderColor = [UIColor cj_fe2c55WithAlpha:0.5].CGColor;
        _secondLabel.backgroundColor = [UIColor clearColor];
    }
    return _secondLabel;
}

@end

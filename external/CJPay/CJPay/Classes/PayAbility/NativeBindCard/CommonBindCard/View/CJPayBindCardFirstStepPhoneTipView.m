//
//  CJPayBindCardFirstStepPhoneTipView.m
//  Pods
//
//  Created by xiuyuanLee on 2020/12/8.
//

#import "CJPayBindCardFirstStepPhoneTipView.h"
#import "CJPayUIMacro.h"


@interface CJPayBindCardFirstStepPhoneTipView()

#pragma mark - view
@property (nonatomic, strong) UILabel *tipsLabel;

@end

@implementation CJPayBindCardFirstStepPhoneTipView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)updateTips:(NSString *)tipsText {
    self.hidden = NO;
    self.tipsLabel.hidden = NO;
    
    self.tipsLabel.text = CJPayLocalizedStr(tipsText);
    self.tipsLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
}

- (void)updateTipsWithWarningText:(NSString *)tipsText {
    [self updateTips:tipsText];
    
    self.tipsLabel.textColor = [UIColor cj_colorWithHexString:@"#FE3824"];
}

#pragma mark - private method
- (void)p_setupUI {
    self.backgroundColor = [UIColor whiteColor];
    
    [self addSubview:self.tipsLabel];
    
    CJPayMasMaker(self.tipsLabel, {
        make.edges.equalTo(self);
    });
}

#pragma mark - lazy view
- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [UILabel new];
        _tipsLabel.textColor = [UIColor cj_161823ff];
        _tipsLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _tipsLabel;
}

@end

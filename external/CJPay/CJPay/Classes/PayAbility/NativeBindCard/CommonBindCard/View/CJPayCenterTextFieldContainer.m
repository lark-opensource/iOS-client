//
//  CJPayCenterTextFieldContainer.m
//  Pods
//
//  Created by xiuyuanLee on 2020/12/9.
//

#import "CJPayCenterTextFieldContainer.h"
#import "CJPayCustomRightView.h"

#import "CJPayUIMacro.h"

@interface CJPayCenterTextFieldContainer ()

@property (nonatomic, assign) CJPayContainerStyle styleType;
@property (nonatomic, strong) UIColor *layerOriginColor;

@end


@implementation CJPayCenterTextFieldContainer

- (instancetype)initWithFrame:(CGRect)frame
                textFieldType:(CJPayTextFieldType)textFieldType type:(CJPayContainerStyle)type {
    self = [super initWithFrame:frame textFieldType:textFieldType];
    if(self){
        _styleType = type;
    }
    return self;
}

- (void)setupUI {
    [super setupUI];
    
    if(self.styleType == CJPayTextFieldQuickBindAuth)
    {
        self.backgroundColor = [UIColor cj_ffffffWithAlpha:1.0];
        
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 4;
        
        self.layer.borderWidth = 0.5;
        self.layer.borderColor = [UIColor cj_161823WithAlpha:0.15].CGColor;
        self.layerOriginColor = [UIColor cj_161823WithAlpha:0.15];
        self.textField.textColor = [UIColor cj_161823ff];
        self.textField.font = [UIFont cj_boldFontOfSize:15];
        
        self.placeHolderLabel.textColor = [UIColor cj_161823WithAlpha:0.34];

        self.bottomLine.hidden = YES;
        return;
    }
    
    if (self.styleType == CJPayTextFieldBindCardFirstStep) {
        self.backgroundColor = [UIColor cj_161823WithAlpha:0.03];
        
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 4;
        
        self.layer.borderWidth = 0;
        self.layerOriginColor = [UIColor cj_161823WithAlpha:0.03];
        self.textField.textColor = [UIColor cj_161823ff];
        self.textField.font = [UIFont cj_boldFontOfSize:16];
        
        self.placeHolderLabel.textColor = [UIColor cj_161823WithAlpha:0.34];

        self.bottomLine.hidden = YES;
        self.backgroundColor = [UIColor whiteColor];
        self.placeHolderLabel.font = [UIFont cj_fontOfSize:16];
        self.layer.borderWidth = 0.5;
        self.layer.borderColor = [UIColor cj_161823WithAlpha:0.12].CGColor;
        
        return;
    }
    // UI重置
    self.backgroundColor = [UIColor cj_f8f8f8ff];
    
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 4;
    
    self.layer.borderWidth = 1;
    self.layer.borderColor = self.backgroundColor.CGColor;
    
    self.layerOriginColor = self.backgroundColor;
    
    self.textField.textColor = [UIColor cj_161823ff];
    self.textField.font = [UIFont cj_boldFontOfSize:16];
    
    CJPayMasReMaker(self.placeHolderLabel, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.centerY.equalTo(self);
        make.height.mas_equalTo(24);
    });
    
    self.placeHolderLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
    
    self.bottomLine.hidden = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textField.frame = CGRectMake(16, (self.cj_height - 48) / 2, self.cj_width - 32, 48);
    self.placeHolderLabel.frame = CGRectMake(16, (self.cj_height - 24) / 2, self.cj_width - 32, 24);
}

- (void)preFillText:(NSString *)text {
    if (!Check_ValidString(text)) {
        return;
    }
    [self textFieldBeginEditAnimation];
    self.textField.text = text;
}

- (void)clearText {
    [self clearTextWithEndAnimated:YES];
}

- (void)clearTextWithEndAnimated:(BOOL)animated {
    self.textField.text = @"";
    if (animated) {
        [self textFieldEndEditAnimation];
    }
}

// 重写基类方法
- (void)textFieldBeginEditAnimation {
//    [super textFieldBeginEditAnimation];
    [UIView animateWithDuration:0.1 animations:^{
        self.placeHolderLabel.alpha = 0;
    }];
}

// 重写基类方法
- (void)textFieldEndEditAnimation {
//    [super textFieldEndEditAnimation];
    [UIView animateWithDuration:0.2 animations:^{
        if (self.textField.userInputContent.length == 0) {
            self.placeHolderLabel.alpha = 1;
        }
    }];
}

- (void)showBorder:(BOOL)show {
    [self showBorder:show withColor:[UIColor cj_fe3824ff]];
}

- (void)showBorder:(BOOL)show withColor:(UIColor *)color {
    self.layer.borderColor = show ? color.CGColor : self.layerOriginColor.CGColor;
}

@end

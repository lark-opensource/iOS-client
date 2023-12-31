//
//  CJPayThemeStyleManager+Biz.m
//  CJPay-4d96cf23
//
//  Created by 王新华 on 11/28/19.
//

#import "CJPayThemeStyleManager+Biz.h"
#import "CJPayStyleButton.h"
#import "CJPayStyleCheckMark.h"
#import "CJPayStyleCheckBox.h"
#import "CJPayCustomTextFieldContainer.h"
#import "CJPayServerThemeStyle.h"
#import "CJPayStyleErrorLabel.h"
#import "CJPayStyleImageView.h"
#import "CJPayAmountTextFieldContainer.h"

@implementation CJPayThemeStyleManager(Biz)

- (void)p_BizRefreshStyle:(CJPayServerThemeStyle *)themeStyle {
    // Button
    CJPayButtonStyle *buttonStyle = themeStyle.buttonStyle;
    [CJPayStyleButton appearance].cornerRadius = buttonStyle.cornerRadius;
    [CJPayStyleButton appearance].titleColor = buttonStyle.titleColor;
    [CJPayStyleButton appearance].disabledAlpha = buttonStyle.disabledAlpha;
    [CJPayStyleButton appearance].normalBackgroundColorStart = buttonStyle.normalBackgroundColorStart;
    [CJPayStyleButton appearance].normalBackgroundColorEnd = buttonStyle.normalBackgroundColorEnd;
    [CJPayStyleButton appearance].disabledBackgroundColorStart = buttonStyle.disabledBackgroundColorStart;
    [CJPayStyleButton appearance].disabledBackgroundColorEnd = buttonStyle.disabledBackgroundColorEnd;

    // RadioButton
    [CJPayStyleCheckMark appearance].backgroundColor = themeStyle.checkBoxStyle.backgroundColor;
    [CJPayStyleCheckBox appearance].selectedCheckBoxColor = themeStyle.checkBoxStyle.backgroundColor;
    [CJPayStyleImageView appearance].backgroundColor = themeStyle.checkBoxStyle.backgroundColor;

    // TextField
    [CJPayCustomTextFieldContainer appearance].cursorColor = themeStyle.cursorColor;
    [CJPayCustomTextFieldContainer appearance].warningTitleColor = themeStyle.linkTextColor;
    
    [CJPayAmountTextFieldContainer appearance].cursorColor = themeStyle.cursorColor;

    // Warning Text
    [CJPayStyleErrorLabel appearance].textColor = themeStyle.linkTextColor;
}

@end

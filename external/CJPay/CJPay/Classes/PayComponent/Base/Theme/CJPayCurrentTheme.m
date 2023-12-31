//
//  CJPayCurrentTheme.m
//  CJPay
//
//  Created by 王新华 on 2018/11/26.
//

#import "CJPayCurrentTheme.h"
#import "CJPayUIMacro.h"

@implementation CJPayCurrentTheme

+ (instancetype)shared{
    static CJPayCurrentTheme *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CJPayCurrentTheme new];
    });
    return instance;
}

- (CJPayDeskTheme *)currentTheme {
    if (!_currentTheme) {
        _currentTheme = [CJPayDeskTheme new];
    }
    
    return _currentTheme;
}

- (UIColor *)bgColor {
    return self.currentTheme.bgColor ?: [UIColor cj_fe2c55ff];
}

- (UIColor *)fontColor {
    return self.currentTheme.fontColor ?: [UIColor whiteColor];
}

@end

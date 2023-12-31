//
//  CJPayServerThemeStyle.m
//  CJPay
//
//  Created by liyu on 2019/10/29.
//

#import "CJPayServerThemeStyle.h"
#import "CJPayUIMacro.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "AccessorsWereOverridden"
#pragma mark - CJPayButtonStyle

@interface CJPayButtonStyle ()

@property (nonatomic, copy) NSString *disabledAlphaString;

@end

@implementation CJPayButtonStyle

@synthesize disabledBackgroundColorStart = _disabledBackgroundColorStart;
@synthesize disabledBackgroundColorEnd = _disabledBackgroundColorEnd;

- (instancetype)init {
    self = [super init];
    if (self) {
        _cornerRadius = 5;
        _disabledAlpha = 0.5;

        _normalBackgroundColorStart = [UIColor cj_colorWithHexString:@"#f85959"];
        _normalBackgroundColorEnd = [UIColor cj_colorWithHexString:@"#f85959"];
        _disabledBackgroundColorStart = nil;
        _disabledBackgroundColorEnd = nil;
        _titleColor = [UIColor cj_colorWithHexString:@"#ffffff"];
    }
    return self;
}

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
            @"normalBackgroundColorStart": @"start_bg_color",
            @"normalBackgroundColorEnd": @"end_bg_color",
            @"titleColor": @"text_color",
            @"cornerRadius": @"corner",
            @"disabledAlphaString": @"disable_alpha",
            @"disabledBackgroundColorStart": @"disable_start_color",
            @"disabledBackgroundColorEnd": @"disable_end_color",
    }];
}

- (void)setDisabledAlphaString:(NSString *)disabledAlphaString {
    if (!Check_ValidString(disabledAlphaString)) {
        return;
    }

    _disabledAlphaString = [disabledAlphaString copy];

    CGFloat floatValue = [_disabledAlphaString floatValue];
    if (floatValue > 0) {
        self.disabledAlpha = floatValue;
    }
}

- (void)setDisabledBackgroundColorStart:(UIColor *)disabledBackgroundColorStart {
    if (disabledBackgroundColorStart == nil) {
        return;
    }

    _disabledBackgroundColorStart = disabledBackgroundColorStart;
}

- (void)setDisabledBackgroundColorEnd:(UIColor *)disabledBackgroundColorEnd {
    if (disabledBackgroundColorEnd == nil) {
        return;
    }

    _disabledBackgroundColorEnd = disabledBackgroundColorEnd;
}

- (UIColor *)disabledBackgroundColorStart {
    return _disabledBackgroundColorStart ?: [self.normalBackgroundColorStart colorWithAlphaComponent:self.disabledAlpha];
}

- (UIColor *)disabledBackgroundColorEnd {
    return _disabledBackgroundColorEnd ?: [self.normalBackgroundColorEnd colorWithAlphaComponent:self.disabledAlpha];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

#pragma mark - nonnull setters

- (void)setTitleColor:(UIColor *)titleColor {
    if (titleColor == nil) {
        return;
    }
    _titleColor = titleColor;
}

- (void)setNormalBackgroundColorStart:(UIColor *)normalBackgroundColorStart {
    if (normalBackgroundColorStart == nil) {
        return;
    }

    _normalBackgroundColorStart = normalBackgroundColorStart;
}

- (void)setNormalBackgroundColorEnd:(UIColor *)normalBackgroundColorEnd {
    if (normalBackgroundColorEnd == nil) {
        return;
    }
    _normalBackgroundColorEnd = normalBackgroundColorEnd;
}

@end

#pragma clang diagnostic pop

#pragma mark - CJPayCheckBoxStyle

@implementation CJPayCheckBoxStyle

- (instancetype)init {
    self = [super init];
    if (self) {
        _backgroundColor = [UIColor cj_fe2c55ff];
    }
    return self;
}

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{@"backgroundColor": @"bg_color"}];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

#pragma mark - nonnull setters

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    if (backgroundColor == nil) {
        return;
    }
    _backgroundColor = backgroundColor;
}

@end

#pragma mark - CJPayThemeStyle

@interface CJPayServerThemeStyle ()

//@property (nonatomic, readwrite) UIColor *cursorColor;

@end

@implementation CJPayServerThemeStyle
@synthesize agreementTextColor = _agreementTextColor;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.themeString = @"light";
        _buttonStyle = [CJPayButtonStyle new];
        _checkBoxStyle = [CJPayCheckBoxStyle new];
        _linkTextColor = [UIColor cj_fe3824ff];
        _agreementTextColor = [UIColor cj_douyinBlueColor];
    }
    return self;
}

+ (CJPayTheme)themeFromString:(NSString *)themeString {
    CJPayTheme result = kCJPayThemeStyleLight;

    NSDictionary *themeMapping = @{
            @"dark": @(kCJPayThemeStyleDark),
            @"light": @(kCJPayThemeStyleLight),
            @"lark": @(kCJPayThemeStyleLight),
    };

    NSNumber *value = themeMapping[themeString];
    if (value != nil) {
        result = (CJPayTheme)value.unsignedIntValue;
    }
    return result;
}

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
            @"themeString": @"theme_type",
            @"linkTextColor": @"link_text_info.text_color",
            @"buttonStyle": @"button_info",
            @"checkBoxStyle": @"checkbox_info",
            @"themedH5PathList": @"is_support_multiple_h5_path",
            @"cursorColor": @"cursor_info.cursor_color",
            @"agreementTextColor": @"agreement_text_info.text_color",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

#pragma mark - nonnull setters

- (void)setThemeString:(NSString *)themeString {
    if (!Check_ValidString(themeString)) {
        return;
    }
    _themeString = [themeString copy];
    self.theme = [[self class] themeFromString:_themeString];
}

- (void)setTheme:(CJPayTheme)theme {
    _theme = theme;
    switch (_theme) {
        case kCJPayThemeStyleLight: {
            _withdrawTipsColor = [UIColor cj_douyinBlueColor];
        }
            break;
        case kCJPayThemeStyleDark: {
            _withdrawTipsColor = [UIColor redColor]; // [UIColor cj_colorWithHexString:@"#FACE15"];
        }
            break;
    }
}

- (void)setLinkTextColor:(UIColor *)linkTextColor {
    if (linkTextColor == nil) {
        return;
    }

    _linkTextColor = linkTextColor;
}

- (void)setAgreementTextColor:(UIColor *)agreementTextColor
{
    if (agreementTextColor == nil) {
        return;
    }
    _agreementTextColor = agreementTextColor;
}

- (UIColor *)warningTextColor {
    return self.linkTextColor ?: [UIColor cj_fe3824ff];
}

- (UIColor *)agreementTextColor {
    return _agreementTextColor ?: [UIColor cj_douyinBlueColor];
}

@end

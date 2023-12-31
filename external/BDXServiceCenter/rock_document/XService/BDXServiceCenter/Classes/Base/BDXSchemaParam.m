//
//  BDXSchemaParam.m
//  BDXServiceCenter
//
//  Created by bytedance on 2021/3/17.
//

#import "BDXSchemaParam.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>

@implementation BDXSchemaParam

+ (instancetype)paramWithDictionary:(NSDictionary *)dict
{
    BDXSchemaParam *param = [[BDXSchemaParam alloc] init];
    [param updateWithDictionary:dict];
    return param;
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
    self.extra = dict;

    NSString *statusFontMode = [dict btd_stringValueForKey:@"status_font_mode"];
    if (statusFontMode) {
        if ([statusFontMode isEqualToString:@"light"]) {
            self.statusFontMode = UIStatusBarStyleLightContent;
        } else if ([statusFontMode isEqualToString:@"dark"]) {
            if (@available(iOS 13.0, *)) {
                self.statusFontMode = UIStatusBarStyleDarkContent;
            } else {
                self.statusFontMode = UIStatusBarStyleDefault;
            }
        } else {
            self.statusFontMode = UIStatusBarStyleDefault;
        }
    } else {
        // status_bar_style_type没有和安卓统一, 统一并优先用status_font_dark
        if ([dict btd_numberValueForKey:@"status_font_dark"] || [dict btd_numberValueForKey:@"status_bar_style_type"]) {
            BOOL dark = NO;
            if ([dict btd_numberValueForKey:@"status_font_dark"]) {
                dark = [[dict btd_numberValueForKey:@"status_font_dark"] boolValue];
            } else if ([dict btd_numberValueForKey:@"status_bar_style_type"]) {
                dark = [dict btd_intValueForKey:@"status_bar_style_type"] == UIStatusBarStyleDefault;
            }
            self.statusFontMode = UIStatusBarStyleLightContent;
            if (@available(iOS 13.0, *)) {
                self.statusFontMode = dark ? UIStatusBarStyleDarkContent : UIStatusBarStyleLightContent;
            } else {
                self.statusFontMode = dark ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
            }
        }
    }

    if ([dict[@"status_bar_color"] isKindOfClass:NSString.class]) {
        self.statusBarColor = [UIColor btd_colorWithHexString:dict[@"status_bar_color"]];
    }

    self.showLoading = [dict btd_boolValueForKey:@"show_loading" default:NO];
    self.showError = [dict btd_boolValueForKey:@"show_error" default:NO];
    if ([dict[@"container_bgcolor"] isKindOfClass:NSString.class]) {
        if ([[dict btd_stringValueForKey:@"container_bgcolor"] isEqualToString:@"transparent"]) {
            self.containerBgColor = [UIColor clearColor];
        } else {
            self.containerBgColor = [UIColor btd_colorWithHexString:dict[@"container_bgcolor"]];
        }
    }
    
    if([dict[@"loading_bgcolor"] isKindOfClass:NSString.class]) {
        if ([[dict btd_stringValueForKey:@"loading_bgcolor"] isEqualToString:@"transparent"]) {
            self.loadingBgColor = [UIColor clearColor];
        } else {
            self.loadingBgColor = [UIColor btd_colorWithHexString:dict[@"loading_bgcolor"]];
        }
    }

    self.disableBuiltIn = [dict btd_numberValueForKey:@"disable_builtin"];
    self.disableGurd = [dict btd_numberValueForKey:@"disable_gecko"];
    self.fallbackURL = [dict btd_stringValueForKey:@"fallback_url"];
    self.forceH5 = [dict btd_numberValueForKey:@"force_h5"];
}

- (void)updateWithParam:(BDXSchemaParam *)newParam
{
    NSMutableDictionary *newExtraDictionary = [self.extra mutableCopy];

    if (newExtraDictionary[@"fallback_url"]) {
        [newExtraDictionary removeObjectForKey:@"fallback_url"];
    }

    [newParam.extra enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
        newExtraDictionary[key] = obj;
    }];

    [self updateWithDictionary:newExtraDictionary];

    self.originURL = newParam.originURL;
    self.resolvedURL = newParam.resolvedURL;
}

@end

//
//  IESLiveResouceStyleModel.m
//  Pods
//
//  Created by Zeus on 17/1/10.
//
//

#import "IESLiveResouceStyleModel.h"
#import "NSString+IESLiveResouceBundle.h"
#import <CoreText/CoreText.h>
#import "IESLiveResourceBundle+File.h"

@implementation IESLiveResouceStyleModel

- (instancetype)initWithDictionary:(NSDictionary *)style assetBundle:(IESLiveResouceBundle *)bundle
{
    self = [super init];
    if (self) {
        if ([style objectForKey:@"overflow"]) {
            if ([[style objectForKey:@"overflow"] isEqualToString:@"visible"]) {
                self.clipsToBounds = [NSNumber numberWithBool:NO];
            }
            if ([[style objectForKey:@"overflow"] isEqualToString:@"hidden"]) {
                self.clipsToBounds = [NSNumber numberWithBool:YES];
            }
        }
        if ([style objectForKey:@"background-color"]) {
            self.backgroudColor = [[style objectForKey:@"background-color"] ies_lr_colorFromARGBHexString];
        }
        if ([style objectForKey:@"opacity"]) {
            self.alpha = @([[style objectForKey:@"opacity"] floatValue]);
        }
        if ([style objectForKey:@"border-color"]) {
            self.borderColor = [[style objectForKey:@"border-color"] ies_lr_colorFromARGBHexString];
        }
        if ([style objectForKey:@"border-width"]) {
            self.borderWidth = @([[style objectForKey:@"border-width"] floatValue]);
        }
        if ([style objectForKey:@"border-radius"]) {
            self.cornerRadius = @([[style objectForKey:@"border-radius"] floatValue]);
        }
        if ([style objectForKey:@"font-size"]) {
            if ([style objectForKey:@"font-family"]) {
                NSString *fontName = [style objectForKey:@"font-family"];
                CGFloat fontSize = [[style objectForKey:@"font-size"] floatValue];
                self.font = [self fontWithName:fontName size:fontSize assetBundle:bundle];
            } else {
                self.font = [UIFont systemFontOfSize:[[style objectForKey:@"font-size"] floatValue]];
                if (style[@"font-weight"]) {
                    if (@available(iOS 8.2, *)) {
                        self.font = [UIFont systemFontOfSize:[[style objectForKey:@"font-size"] floatValue] weight:[IESLiveResouceStyleModel fontWeightFromStr:[style objectForKey:@"font-weight"]]];
                    } else {
                        if ([style[@"font-weight"] isEqualToString:@"thick"]) {
                            self.font = [UIFont boldSystemFontOfSize:[[style objectForKey:@"font-size"] floatValue]];
                        } else {
                            self.font = [UIFont systemFontOfSize:[[style objectForKey:@"font-size"] floatValue]];
                        }
                    }
                }
            }
        }
        if ([style objectForKey:@"color"]) {
            self.textColor = [[style objectForKey:@"color"] ies_lr_colorFromARGBHexString];
        }
    }
    return self;
}

- (UIFont *)fontWithName:(NSString *)name size:(CGFloat)size assetBundle:(IESLiveResouceBundle *)bundle {
    UIFont *font = [UIFont fontWithName:name size:size];
    if (!font) {
        //file/font/下取自定义字体
        NSString *fontPath = bundle.filePath([NSString stringWithFormat:@"%@.ttf",name]);
        font = [self customFontWithPath:fontPath size:size];
    }
    return font ?: [UIFont systemFontOfSize:size];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
static NSDictionary *dic = nil;
+ (UIFontWeight)fontWeightFromStr:(NSString *)strName{
    if (!dic) {
        dic = @{
                @"UIFontWeightUltraLight" : @(UIFontWeightUltraLight),
                @"UIFontWeightThin" : @(UIFontWeightThin),
                @"UIFontWeightLight" : @(UIFontWeightLight),
                @"UIFontWeightRegular" : @(UIFontWeightRegular),
                @"UIFontWeightMedium" : @(UIFontWeightMedium),
                @"UIFontWeightSemibold" : @(UIFontWeightSemibold),
                @"UIFontWeightBold" : @(UIFontWeightBold),
                @"UIFontWeightHeavy" : @(UIFontWeightHeavy),
                @"UIFontWeightBlack" : @(UIFontWeightBlack),
                };
    }
    if (dic[strName]) {
        return (UIFontWeight)[dic[strName] floatValue];
    } else {
        return UIFontWeightRegular;
    }
}
#pragma clang diagnostic pop

- (UIFont*)customFontWithPath:(NSString*)path size:(CGFloat)size
{
    if (path.length <= 0) {
        return nil;
    }
    NSURL *fontUrl = [NSURL fileURLWithPath:path];
    CGDataProviderRef fontDataProvider = CGDataProviderCreateWithURL((__bridge CFURLRef)fontUrl);
    CGFontRef fontRef = CGFontCreateWithDataProvider(fontDataProvider);
    CGDataProviderRelease(fontDataProvider);
    CTFontManagerRegisterGraphicsFont(fontRef, NULL);
    NSString *fontName = CFBridgingRelease(CGFontCopyPostScriptName(fontRef));
    UIFont *font = [UIFont fontWithName:fontName size:size];
    CGFontRelease(fontRef);
    return font;
}

@end

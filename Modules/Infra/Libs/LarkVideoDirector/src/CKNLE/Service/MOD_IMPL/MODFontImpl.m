//
//  MODFontImpl.m
//  Modeo
//
//  Created by limeng on 2020/12/23.
//

#import "MODFontImpl.h"
#import <CreativeKit/UIFont+ACCAdditions.h>

CGFloat MODFontSizeWithClass(ACCFontClass fontClass) {

    switch (fontClass) {
        case ACCFontClassH0:
            return 28;
        case ACCFontClassH1:
            return 24;
        case ACCFontClassH2:
            return 20;
        case ACCFontClassH3:
            return 17;
        case ACCFontClassH4:
            return 15;
        case ACCFontClassP1:
            return 14;
        case ACCFontClassP2:
            return 13;
        case ACCFontClassP3:
            return 12;
        case ACCFontClassSmallText1:
            return 11;
        case ACCFontClassSmallText2:
            return 10;
    }
}

@implementation MODFontImpl

- (UIFont *)boldSystemFontOfSize:(CGFloat)fontSize {
    return [UIFont acc_boldSystemFontOfSize:fontSize];
}

- (UIFont *)systemFontOfSize:(CGFloat)fontSize {
    return [UIFont acc_systemFontOfSize:fontSize];
}

- (UIFont *)systemFontOfSize:(CGFloat)fontSize weight:(ACCFontWeight)weight {
    return [UIFont systemFontOfSize:fontSize weight:weight];
}

- (nonnull UIFont *)acc_boldSystemFontOfSize:(CGFloat)fontSize {
    return [UIFont boldSystemFontOfSize:fontSize];
}

- (nonnull UIFont *)acc_fontOfClass:(ACCFontClass)fontClass weight:(ACCFontWeight)weight {
    return [UIFont systemFontOfSize:MODFontSizeWithClass(fontClass)];
}

- (UIFont *)acc_systemFontOfSize:(CGFloat)fontSize {
    return [UIFont systemFontOfSize:fontSize];
}

+ (UIFontWeight)_transformFontWeight:(ACCFontWeight)fontWeight
{
    if (@available(iOS 8.2, *)) {
        switch (fontWeight) {
            case ACCFontWeightUltraLight:
                return UIFontWeightUltraLight;
            case ACCFontWeightThin:
                return UIFontWeightThin;
            case ACCFontWeightLight:
                return UIFontWeightLight;
            case ACCFontWeightRegular:
                return UIFontWeightRegular;
            case ACCFontWeightMedium:
                return UIFontWeightMedium;
            case ACCFontWeightSemibold:
                return UIFontWeightSemibold;
            case ACCFontWeightBold:
                return UIFontWeightBold;
            case ACCFontWeightHeavy:
                return UIFontWeightHeavy;
            case ACCFontWeightBlack:
                return UIFontWeightBlack;
            default:
                return 0;
        }
    } else {
        return 0;
    }
}

- (UIFont *)acc_systemFontOfSize:(CGFloat)fontSize weight:(ACCFontWeight)weight {
    return [UIFont systemFontOfSize:fontSize weight:[MODFontImpl _transformFontWeight:weight]];
}

- (CGFloat)getAdaptiveFontSize:(CGFloat)fontSize
{
    return fontSize;
}

@end

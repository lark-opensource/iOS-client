//
//  OPUtils.m
//  OPFoundation
//
//  Created by yinyuan on 2020/12/16.
//

#import "OPUtils.h"
#import <UniverseDesignTheme/UniverseDesignTheme-Swift.h>

BOOL OPIsEmptyArray(NSArray *array)
{
    return (!array || ![array isKindOfClass:[NSArray class]] || array.count == 0);
}

BOOL OPIsEmptyString(NSString *string)
{
    return (!string || ![string isKindOfClass:[NSString class]] || string.length == 0);
}

BOOL OPIsEmptyDictionary(NSDictionary *dict)
{
    return (!dict || ![dict isKindOfClass:[NSDictionary class]] || ((NSDictionary *)dict).count == 0);
}

NSArray *OPSafeArray(NSArray *array)
{
    return [array isKindOfClass:[NSArray class]] ? array :@[];
}

NSString *OPSafeString(NSString *string)
{
    return [string isKindOfClass:[NSString class]] ? string : @"";
}

NSDictionary *OPSafeDictionary(NSDictionary *dict)
{
    return [dict isKindOfClass:[NSDictionary class]] ? dict : @{};
}

BOOL OPIsDarkMode()  {
    if (@available(iOS 13.0, *)) {
        return [UDThemeManager getRealUserInterfaceStyle] == UIUserInterfaceStyleDark;
    } else {
        return false;
    }
}


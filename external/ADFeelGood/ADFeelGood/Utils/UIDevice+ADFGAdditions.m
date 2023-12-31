//
//  UIDevice+ADFGAdditions.m
//  ADFeelGood
//
//  Created by cuikeyi on 2021/2/7.
//

#import "UIDevice+ADFGAdditions.h"
#import <sys/utsname.h>
#import "NSDictionary+ADFGAdditions.h"

@implementation UIDevice (ADFGAdditions)

+ (NSString *)adfg_devidePlatformString
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *phoneType = [NSString stringWithCString: systemInfo.machine encoding:NSASCIIStringEncoding];
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"ADFeelGood" ofType:@"bundle"];
    NSBundle *feelGoodBundle = [NSBundle bundleWithPath:bundlePath];
    
    NSString *dataPlistPath = [feelGoodBundle pathForResource:@"DevicePlatformString" ofType:@"plist"];
    NSDictionary *devicePlatformDict = [NSDictionary dictionaryWithContentsOfFile:dataPlistPath];
    NSString *devidePlatformString = [devicePlatformDict adfg_stringForKey:phoneType defaultValue:@"unkonwn"];
    return devidePlatformString;
}

@end

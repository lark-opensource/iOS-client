//
//  NSURLQueryItem+BulletUrlExt.m
//  AAWELaunchOptimization
//
//  Created by duanefaith on 2019/10/12.
//

#import "NSString+BulletXUrlExt.h"
#import "NSURLQueryItem+BulletXUrlExt.h"

@implementation NSURLQueryItem (BulletXUrlExt)

+ (instancetype)bullet_queryItemWithName:(NSString *)name unencodedValue:(NSString *)unencodedValue
{
    return [self queryItemWithName:name ? [name bullet_urlEncode] : name value:unencodedValue ? [unencodedValue bullet_urlEncode] : unencodedValue];
}

@end

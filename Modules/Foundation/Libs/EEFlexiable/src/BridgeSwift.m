//
//  BridgeSwift.m
//  EEFlexiable
//
//  Created by qihongye on 2019/2/11.
//

#import <Foundation/Foundation.h>
#import "BridgeSwift.h"

@implementation NSValue (CSSValue)

+ (instancetype)valuewithCSSValue:(CSSValue)value
{
    return [self valueWithBytes:&value objCType:@encode(CSSValue)];
}

- (CSSValue)cssValue
{
    CSSValue value;
    [self getValue:&value];
    return value;
}

@end



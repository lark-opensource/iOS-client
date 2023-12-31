//
//  NSString+DYCExtension.m
//  BDDynamically
//
//  Created by zuopengliu on 26/9/2018.
//

#import "NSString+DYCExtension_Internal.h"



@implementation NSString (DYCExtensionInternal)

- (BOOL)bddyc_containsString:(NSString *)str
{
    if (!str) return NO;
    if ([self respondsToSelector:@selector(containsString:)]) {
        return [self containsString:str];
    }
    return ([self rangeOfString:str].location != NSNotFound);
}

@end

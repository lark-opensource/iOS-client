//
//  NSString+BDXBridgeAdditions.m
//  BDXBridgeKit-Pods-Aweme
//
//  Created by Lizhen Hu on 2021/3/28.
//

#import "NSString+BDXBridgeAdditions.h"

@implementation NSString (BDXBridgePath)

- (NSString *)bdx_stringByStrippingSandboxPath
{
    NSString *sandboxPath = NSHomeDirectory();
    NSRange range = [self rangeOfString:sandboxPath];
    if (range.location != NSNotFound) {
        NSUInteger index = range.location + range.length;
        if (index < self.length) {
            NSString *path = [self substringFromIndex:index];
            return [path hasPrefix:@"/"] ? path : [@"/" stringByAppendingString:path];
        }
    }
    return self;
}

- (NSString *)bdx_stringByAppendingSandboxPath
{
    NSString *sandboxPath = NSHomeDirectory();
    NSRange range = [self rangeOfString:sandboxPath];
    if (range.location == NSNotFound) {
        return [sandboxPath stringByAppendingPathComponent:self];
    }
    return self;
}

@end

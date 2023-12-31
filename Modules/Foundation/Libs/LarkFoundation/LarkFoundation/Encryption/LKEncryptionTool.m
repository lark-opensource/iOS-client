//
//  LKEncryptionTool.m
//  LarkWeb
//
//  Created by sniperj on 2019/4/15.
//

#import "LKEncryptionTool.h"

@implementation LKEncryptionTool

+ (NSString *)decryptString:(NSString *)string
{
    NSMutableString *resultString = [NSMutableString string];
    for (NSInteger i = 0; i < string.length; i++) {
        unichar c = [string characterAtIndex:i];
        c = c - i;
        if (c <= 33) {
            c = 126 + c - 33;
        }
        [resultString appendString:[NSString stringWithFormat:@"%c",c]];
    }
    return resultString;
}

+ (NSString *)encryptString:(NSString *)string
{
    NSMutableString *resultString = [NSMutableString string];
    for (NSInteger i = 0; i < string.length; i++) {
        unichar c = [string characterAtIndex:i];
        c = c + i;
        if (c > 126) {
            c = c - 126 + 33;
        }
        [resultString appendString:[NSString stringWithFormat:@"%c",c]];
    }
    return resultString;
}

@end

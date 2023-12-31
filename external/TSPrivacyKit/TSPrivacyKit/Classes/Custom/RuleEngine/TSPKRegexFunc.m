//
//  TSPKRegexFunc.m
//  Musically
//
//  Created by ByteDance on 2022/10/8.
//

#import "TSPKRegexFunc.h"
#import "TSPKLogger.h"

@implementation TSPKRegexFunc

- (NSString *)symbol {
    return @"regex";
}

- (id)execute:(NSMutableArray *)params {
    if (params.count >= 2) {
        NSString *content = params[0];
        NSArray *regexArray = params[1];
        
        @try {
            for (NSString *regex in regexArray) {
                NSPredicate *regexPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
                if ([regexPredicate evaluateWithObject:content]) {
                    return @YES;
                }
            }
        } @catch (NSException *exception) {
            [TSPKLogger logWithTag:@"TSPKRegexFunc" message:@"regex analysis error"];
        }
    }
    
    return @NO;
}

@end

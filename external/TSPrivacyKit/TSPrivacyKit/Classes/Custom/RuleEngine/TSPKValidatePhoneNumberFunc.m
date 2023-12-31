//
//  TSPKValidatePhoneNumberFunc.m
//  Musically
//
//  Created by ByteDance on 2022/12/26.
//

#import "TSPKValidatePhoneNumberFunc.h"
#import "TSPKLogger.h"

@implementation TSPKValidatePhoneNumberFunc

- (NSString *)symbol {
    return @"is_phone_number";
}

- (id)execute:(NSMutableArray *)params {
    if (params.count >= 4) {
        NSString *userInput = params[0];
        NSArray *regexArray = params[1];
        NSString *topPageName = params[2];
        NSArray *allowPageList = params[3];

        if ([allowPageList containsObject:topPageName]) {
            return @NO;
        }
        
        @try {
            for (NSString *regex in regexArray) {
                NSPredicate *regexPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
                if ([regexPredicate evaluateWithObject:userInput]) {
                    return @YES;
                }
            }
        } @catch (NSException *exception) {
            [TSPKLogger logWithTag:@"TSPKValidatePhoneNumberFunc" message:@"regex analysis error"];
        }
    }
    
    return @NO;
}

@end

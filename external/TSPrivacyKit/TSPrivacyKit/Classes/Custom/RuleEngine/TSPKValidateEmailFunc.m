//
//  TSPKValidateEmailFunc.m
//  Musically
//
//  Created by ByteDance on 2022/12/26.
//

#import "TSPKValidateEmailFunc.h"
#import "TSPKLogger.h"

static NSString *const EmailRegex = @"[a-zA-Z0-9.\\-_+]{2,32}@[a-zA-Z0-9.\\-_]{2,32}\\.[A-Za-z]{2,4}";

@implementation TSPKValidateEmailFunc

- (NSString *)symbol {
    return @"is_email";
}

- (id)execute:(NSMutableArray *)params {
    if (params.count >= 3) {
        NSString *userInput = params[0];
        NSString *topPageName = params[1];
        NSArray *allowPageList = params[2];

        if ([allowPageList containsObject:topPageName]) {
            return @NO;
        }
        
        @try {
            NSPredicate *validateEmail = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", EmailRegex];
            if ([validateEmail evaluateWithObject:userInput]) {
                return @YES;
            }
        } @catch (NSException *exception) {
            [TSPKLogger logWithTag:@"TSPKValidateEmailFunc" message:@"regex analysis error"];
        }
    }
    
    return @NO;
}

@end

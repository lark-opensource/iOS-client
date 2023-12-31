//
//  NSString+BDPTextValidation.m
//  Timor
//
//  Created by 刘春喜 on 2019/12/10.
//

#import "NSString+BDPTextValidation.h"

@implementation NSString (BDPTextValidation)

- (BOOL)bdp_isValidIdentityCard {
    NSString *pattern = @"(^[0-9]{15}$)|([0-9]{17}([0-9]|X)$)";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    BOOL isMatched = [pred evaluateWithObject:self];
    return isMatched;
}

- (BOOL)bdp_isValidChineseCharacters {
    NSString *pattern = @"^[\u4e00-\u9fa5]{2,13}";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    BOOL isMatched = [pred evaluateWithObject:self];
    return isMatched;
}

- (BOOL)bdp_isValidIdentityCardInput {
    NSString *pattern = @"^[xX0-9]+$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    BOOL isMatched = [pred evaluateWithObject:self];
    return isMatched;
}

@end

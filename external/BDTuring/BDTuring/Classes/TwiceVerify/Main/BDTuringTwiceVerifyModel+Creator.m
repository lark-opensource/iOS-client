//
//  BDTuringTwiceVerifyModel+Creator.m
//  BDTuring
//
//  Created by bob on 2021/8/5.
//

#import "BDTuringTwiceVerifyModel+Creator.h"
#import "BDTuringUtility.h"
#import "NSDictionary+BDTuring.h"

@implementation BDTuringTwiceVerifyModel (Creator)

+ (BOOL)canHandleParameter:(NSDictionary *)parameter {
    if (!BDTuring_isValidDictionary(parameter)) {
        return NO;
    }
    NSString *code = [parameter turing_stringValueForKey:@"code"].lowercaseString;
    if (![code isEqualToString:@"20000"])  {
        return NO;
    }
    
    NSArray *verifyWays = [parameter turing_arrayValueForKey:@"verify_ways"];
    NSString *type = nil;
    if ([verifyWays isKindOfClass:[NSArray class]] && verifyWays.count == 1) {
        type = [[verifyWays firstObject] turing_stringValueForKey:@"verify_way"];
    } else {
        type = [parameter turing_stringValueForKey:@"subtype"];
    }
    if (type == nil) {
        return NO;
    }
        
    return YES;
}


@end

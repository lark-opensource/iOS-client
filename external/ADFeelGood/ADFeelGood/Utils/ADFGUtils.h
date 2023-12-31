//
//  ADFGUtils.h
//  ADFeelGood
//
//  Created by cuikeyi on 2021/1/15.
//

#import <Foundation/Foundation.h>
#import "NSDictionary+ADFGAdditions.h"
#import "NSArray+ADFGAdditions.h"
#import "ADFGError.h"

NS_ASSUME_NONNULL_BEGIN

@interface ADFGUtils : NSObject

+ (NSError *)errorWithCode:(NSInteger)code msg:(NSString *)msg;

@end

NS_ASSUME_NONNULL_END

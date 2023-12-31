//
//  NSDate+TSASignature.h
//  TTTopSignature
//
//  Created by 黄清 on 2018/10/17.


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString*  VEKDateFormat;

@interface NSDate (TSASignature)

+ (NSDate *)tsa_clockSkewFixedDate;
- (NSString *)tsa_stringValueISO8601Date2Formatter;

@end

NS_ASSUME_NONNULL_END

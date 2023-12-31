//
//  NSDictionary+IESAdditions.h
//  IESVideoDetector
//
//  Created by geekxing on 2020/6/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (IESAdditions)

+ (NSDictionary *)ies_dictionaryWithJSONString:(NSString *)jsonString;
- (NSString *)ies_JSONString;

@end

NS_ASSUME_NONNULL_END

//
//  BDStrategyCenterUtil.h
//  BDRuleEngine-Pods-AwemeCore
//
//  Created by PengYan on 2022/1/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDStrategyCenterUtil : NSObject

+ (NSString *)formatToJsonString:(id)input;

+ (NSString *)formatToJsonString:(id)input option:(NSJSONWritingOptions)opt;

@end

NS_ASSUME_NONNULL_END

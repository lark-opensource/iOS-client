//
//  BDTuringDeviceHelper.h
//  BDTuring
//
//  Created by bob on 2019/8/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringDeviceHelper : NSObject

+ (NSString *)deviceBrand;
+ (nullable NSString *)deviceModel;

+ (NSString *)systemVersion;

+ (NSString *)resolutionString;

+ (NSString *)localeIdentifier;

@end

NS_ASSUME_NONNULL_END

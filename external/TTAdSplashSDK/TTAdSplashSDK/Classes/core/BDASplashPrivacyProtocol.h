//
//  BDASplashPrivacyProtocol.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2021/4/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDASplashPrivacyProtocol <NSObject>

+ (NSString*)idfaString;

+ (NSString *)idfvString;
@end

NS_ASSUME_NONNULL_END

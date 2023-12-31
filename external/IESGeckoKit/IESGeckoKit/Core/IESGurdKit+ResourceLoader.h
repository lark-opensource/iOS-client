//
//  IESGurdKit+ResourceLoader.h
//  IESGurdKit
//
//  Created by liuhaitian on 2021/4/21.
//

#import "IESGeckoKit.h"
#import "IESGurdSettingsResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdKit (ResourceLoader)

+ (IESGurdSettingsResponse *)settingsResponse;

+ (NSDictionary *)settingsResponseDictionary;

@end

NS_ASSUME_NONNULL_END

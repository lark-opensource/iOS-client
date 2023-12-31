//
//  IESGurdSettingsManager.h
//  IESGeckoKit
//
//  Created by liuhaitian on 2021/4/19.
//

#import <Foundation/Foundation.h>
#import "IESGurdSettingsResponse.h"
#import "IESGurdSettingsResponseExtra.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdSettingsManager : NSObject

@property (nonatomic, strong, readonly) IESGurdSettingsResponse *settingsResponse;

@property (nonatomic, strong) IESGurdSettingsResponseExtra *extra;

+ (instancetype)sharedInstance;

- (void)fetchSettingsWithRequestType:(IESGurdSettingsRequestType) requestType;

- (void)cleanCache;

@end

NS_ASSUME_NONNULL_END


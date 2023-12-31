//
//  IESGurdRegisterManager.h
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/14.
//

#import <Foundation/Foundation.h>

#import "IESGurdRegisterModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdRegisterManager : NSObject

+ (instancetype)sharedManager;

- (void)registerAccessKey:(NSString *)accessKey;

- (void)registerAccessKey:(NSString *)accessKey SDKVersion:(NSString * _Nullable)SDKVersion;

- (void)addCustomParamsForAccessKey:(NSString *)accessKey
                       customParams:(NSDictionary * _Nullable)customParams;

- (BOOL)isAccessKeyRegistered:(NSString *)accessKey;

- (IESGurdRegisterModel *)registerModelWithAccessKey:(NSString *)accessKey;

- (NSArray<NSString *> *)allAccessKeys;

- (NSArray<IESGurdRegisterModel *> *)allRegisterModels;

@end

NS_ASSUME_NONNULL_END

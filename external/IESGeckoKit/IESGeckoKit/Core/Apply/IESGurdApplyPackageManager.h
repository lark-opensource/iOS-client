//
//  IESGurdApplyPackageManager.h
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/27.
//

#import <Foundation/Foundation.h>

#import "IESGeckoDefines.h"
#import "IESGeckoResourceModel.h"

NS_ASSUME_NONNULL_BEGIN

@class IESGurdApplyPackageManager;

@protocol IESGurdApplyPackageManagerDelegate <NSObject>

- (void)applyPackageManager:(IESGurdApplyPackageManager *)manager
didApplyPackageForAccessKey:(NSString *)accessKey
                    channel:(NSString *)channel;

@end

@interface IESGurdApplyPackageManager : NSObject

@property (nonatomic, weak) id<IESGurdApplyPackageManagerDelegate> delegate;

+ (instancetype)sharedManager;

- (void)applyAllInactiveCacheWithCompletion:(IESGurdSyncStatusBlock)completion;

- (void)applyInactiveCacheForAccessKey:(NSString *)accessKey
                               channel:(NSString *)channel
                            completion:(IESGurdSyncStatusBlock)completion;

- (void)applyInactiveCacheForAccessKey:(NSString *)accessKey
                               channel:(NSString *)channel
                               logInfo:(NSDictionary * _Nullable)logInfo
                            completion:(IESGurdSyncStatusBlock)completion;

@end

NS_ASSUME_NONNULL_END

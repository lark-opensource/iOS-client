//
//  IESGurdLazyResourcesManager.h
//  Aspects
//
//  Created by 陈煜钏 on 2021/6/9.
//

#import <Foundation/Foundation.h>

#import "IESGeckoDefines+Private.h"

NS_ASSUME_NONNULL_BEGIN

@class IESGurdResourceModel, IESGurdLazyResourcesInfo, IESGurdFetchResourcesParams;

@interface IESGurdLazyResourcesManager : NSObject

+ (instancetype)sharedManager;

- (BOOL)isLazyResourceWithModel:(IESGurdResourceModel *)model;

- (BOOL)isLazyChannel:(NSString *)accesskey channel:(NSString *)channel;

- (NSArray<IESGurdResourceModel *> *)modelsToDownloadWithParams:(IESGurdFetchResourcesParams *)params;

- (IESGurdLazyResourcesInfo *)lazyResourceInfoWithAccesskey:(NSString *)accesskey channel:(NSString *)channel;

@end

NS_ASSUME_NONNULL_END

//
//  IESPrefetchAPIModel.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/4.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchJSNetworkRequestModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESPrefetchAPIModel : NSObject

@property (nonatomic, strong) IESPrefetchJSNetworkRequestModel *request;
@property (nonatomic, assign) int64_t expire;

@end

NS_ASSUME_NONNULL_END

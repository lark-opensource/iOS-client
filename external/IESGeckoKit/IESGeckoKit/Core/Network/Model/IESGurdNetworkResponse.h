//
//  IESGurdNetworkResponse.h
//  IESGeckoKit-Pods-Aweme
//
//  Created by 陈煜钏 on 2020/6/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdNetworkResponse : NSObject

@property (nonatomic, assign) NSInteger statusCode;

@property (nonatomic, strong) id _Nullable responseObject;

@property (nonatomic, strong) NSError * _Nullable error;

@property (nonatomic, copy) NSDictionary *allHeaderFields;

@end

NS_ASSUME_NONNULL_END

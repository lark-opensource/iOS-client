//
//  RequestRetryResult.h
//  TTNetworkManager
//
//  Created by taoyiyuan on 2022/10/21.
//

#import <Foundation/Foundation.h>

@interface RequestRetryResult : NSObject

@property(nonatomic, assign) BOOL requestRetryEnabled;

@property(atomic, strong, nullable) NSDictionary* addRequestHeaders;

- (instancetype _Nonnull)initWithRetryResult:(BOOL)requestRetryEnabled addRequestHeaders:(nullable NSDictionary* )addRequestHeaders;

@end

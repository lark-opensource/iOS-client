//
//  IESFalconManager+InterceptionDelegate.h
//  IESWebKit
//
//  Created by li keliang on 2019/5/7.
//

#import "IESFalconManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESFalconManager (InterceptionDelegate)

+ (void)callingOutFalconInterceptedRequest:(NSURLRequest *)requst willLoadFromCache:(BOOL)fromCache;

@end

NS_ASSUME_NONNULL_END

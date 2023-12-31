//
//  HMDURLProtocol.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/21.
//

#import <Foundation/Foundation.h>

/// 如果不需要拦截 url_session 的特定请求 可以使用 [HMDURLProtocol setProperty:@YES forKey:HMDURLProtocolNoFilterIdentifier inRequest:mutableRequest],标识不去拦截这个请求
extern NSString * _Nonnull const HMDURLProtocolNoFilterIdentifier;

@interface HMDURLProtocol : NSURLProtocol

@end

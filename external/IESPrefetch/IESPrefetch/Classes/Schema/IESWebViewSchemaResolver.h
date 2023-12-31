//
//  IESWebViewSchemaResolver.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/1.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchSchemaResolver.h"

NS_ASSUME_NONNULL_BEGIN

/// 用于解析WebView的Schema，可拦截的Schema格式为: xxx://webview?url=encoded_schema
@interface IESWebViewSchemaResolver : NSObject<IESPrefetchSchemaResolver>

@end

NS_ASSUME_NONNULL_END

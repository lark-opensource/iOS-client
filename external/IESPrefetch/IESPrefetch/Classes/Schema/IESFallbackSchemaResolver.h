//
//  IESDirectSchemaResolver.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/4.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchSchemaResolver.h"

NS_ASSUME_NONNULL_BEGIN

/// 直接转换，会拦截所有schema字符串，作为默认的fallback解析器
@interface IESFallbackSchemaResolver : NSObject<IESPrefetchSchemaResolver>

@end

NS_ASSUME_NONNULL_END

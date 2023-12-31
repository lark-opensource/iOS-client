//
//  IESPrefetchConfigResolver.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IESPrefetchConfigTemplate;
/// 配置解析器，配置的不同部分由不同的解析器来进行解析
@protocol IESPrefetchConfigResolver <NSObject>
/// 解析相应的配置，并返回对应的模板结果
- (id<IESPrefetchConfigTemplate>)resolveConfig:(NSDictionary *)config;

@end

NS_ASSUME_NONNULL_END

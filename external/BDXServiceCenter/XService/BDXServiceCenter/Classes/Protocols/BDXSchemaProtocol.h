//
//  BDXSchemaProtocol.h
//  BDXServiceCenter-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#import <Foundation/Foundation.h>

#import <BDXServiceCenter/BDXContext.h>
#import <BDXServiceCenter/BDXResourceLoaderProtocol.h>

#import "BDXSchemaParam.h"
#import "BDXServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN


@protocol BDXSchemaProtocol <BDXServiceProtocol>

/// URL转换，返回 BDXSchemaParam 参数集合
/// @param originURL 原始URL
/// @param contextInfo context
+ (nullable BDXSchemaParam *)resolverWithSchema:(NSURL *)originURL contextInfo:(nullable BDXContext *)contextInfo;

/// URL转换，返回 BDXSchemaParam 的子类
/// @param originURL 原始URL
/// @param contextInfo context
/// @param cls BDXSchemaParam子类
+ (nullable BDXSchemaParam *)resolverWithSchema:(NSURL *)originURL contextInfo:(nullable BDXContext *)contextInfo paramClass:(Class)cls;

/// 根据 URL 和 prefix 提取 channel/bundle.
/// @param urlString URL
/// @param prefix prefix
+ (NSDictionary *)extractURLDetail:(NSString *)urlString withPrefix:(NSString *)prefix;

@end

NS_ASSUME_NONNULL_END

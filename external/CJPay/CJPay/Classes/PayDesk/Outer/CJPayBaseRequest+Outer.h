//
//  CJPayBaseRequest+Outer.h
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/10.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBaseRequest (Outer)

+ (NSString *)outerH5DeskServerHostString;

+ (NSString *)outerDeskServerUrlString;

+ (void)setOuterConfigHost:(NSString *)configHost;

+ (NSString *)getOuterConfigHost;

+ (NSString *)buildOuterServerUrl;

@end

NS_ASSUME_NONNULL_END

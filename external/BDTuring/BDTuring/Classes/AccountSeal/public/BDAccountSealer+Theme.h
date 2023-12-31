//
//  BDAccountSealer+Theme.h
//  BDTuring
//
//  Created by bob on 2020/7/2.
//

#import "BDAccountSealer.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAccountSealer (Theme)

/**
see https://bytedance.feishu.cn/docs/doccnIDYz3xz2Jr1ZPmxgZEfOze#
 you can set nil to clean custom ui
*/
+ (void)setCustomTheme:(nullable NSDictionary *)theme;
+ (void)setCustomText:(nullable NSDictionary *)text;

@end

NS_ASSUME_NONNULL_END

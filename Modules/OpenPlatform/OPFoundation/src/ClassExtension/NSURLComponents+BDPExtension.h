//
//  NSURLComponents+BDPExtension.h
//  Timor
//
//  Created by tujinqiu on 2020/4/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLComponents (BDPExtension)

// 给url添加参数的便捷方法
- (void)bdp_setQueryItemWithKey:(NSString * _Nonnull)key value:(NSString * _Nullable)value;

@end

NS_ASSUME_NONNULL_END

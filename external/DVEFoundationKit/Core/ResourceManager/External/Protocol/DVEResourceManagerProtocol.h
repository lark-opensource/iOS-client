//
//   DVEResourceManagerProtocol.h
//   BDAlogProtocol
//
//   Created  by ByteDance on 2022/2/24.
//   Copyright © 2022 ByteDance Ltd. All rights reserved.
//
    

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVEResourceManagerProtocol <NSObject>

/// 国际化字符串转换
/// @param key 字符key
/// @return 如果不需要转换则返回nil
- (NSString*)covertStringWithKey:(NSString*)key;

@end

NS_ASSUME_NONNULL_END

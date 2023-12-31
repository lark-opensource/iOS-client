//
//  NSString+HMDSafe.h
//  AFgzipRequestSerializer-iOS13.0
//
//  Created by xuminghao.eric on 2019/11/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (HMDSafe)

- (BOOL)hmd_characterAtIndex:(NSInteger)index writeToChar:(char *)charactor;

- (nullable NSString *)hmd_substringToIndex:(NSInteger)index;

- (nullable NSString *)hmd_substringWithRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END

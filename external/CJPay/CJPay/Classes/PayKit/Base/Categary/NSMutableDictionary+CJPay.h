//
//  NSMutableDictionary+CJPay.h
//  CJPay
//
//  Created by 王新华 on 8/9/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary(CJPay)

- (void)cj_fill:(id) object WhenNotExistForKey:(NSString *)key;

- (void)cj_setObject:(id) object forKey:(NSString *)key;

- (void)cj_setValue:(id _Nullable)value forKeyPath:(NSString *)keypath;

@end

NS_ASSUME_NONNULL_END

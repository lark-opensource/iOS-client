//
//  NSURLComponents+CJPayQueryOperation.h
//  CJPay
//
//  Created by liyu on 2020/6/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLComponents (CJPayQueryOperation)

- (void)cjpay_setQueryValue:(NSString *)value ifNotExistKey:(NSString *)key;

- (void)cjpay_overrideQueryByDict:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END

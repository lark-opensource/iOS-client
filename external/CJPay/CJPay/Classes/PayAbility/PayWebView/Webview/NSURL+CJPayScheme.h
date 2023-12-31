//
//  NSURL+CJPayScheme.h
//  CJPay
//
//  Created by liyu on 2020/5/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (CJPayScheme)

- (BOOL)isCJPayWebviewScheme;

- (BOOL)isCJPayHTTPScheme;

@end

NS_ASSUME_NONNULL_END

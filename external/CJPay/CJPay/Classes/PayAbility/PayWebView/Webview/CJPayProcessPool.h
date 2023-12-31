//
//  CJPayProcessPool.h
//  CJPay
//
//  Created by 王新华 on 2018/12/3.
//

#import <Foundation/Foundation.h>
#import <WebKit/WKProcessPool.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayProcessPool : WKProcessPool

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END

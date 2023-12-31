//
//  NSURL+CJPay.h
//  Pods
//
//  Created by xiuyuanLee on 2021/4/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (CJPay)

+ (instancetype)cj_URLWithString:(NSString *)urlString;

- (NSString *)cj_getHostAndPath;

@end

NS_ASSUME_NONNULL_END

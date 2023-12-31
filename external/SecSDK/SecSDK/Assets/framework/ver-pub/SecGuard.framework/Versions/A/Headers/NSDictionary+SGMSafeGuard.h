//
//  NSDictionary+SGMSafeGuard.h
//  SecSDK
//
//  Created by renfeng.zhang on 2018/1/19.
//  Copyright © 2018年 Zhi Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (SGMSafeGuard)

/* 将NSDictionary转换为json string, 发生错误时返回nil */
- (nullable NSString *)sgm_data_acquisition_jsonString;

@end //NSDictionary (SGMSafeGuard)

@interface NSMutableDictionary (SGMSafeGuard)

- (void)sgm_safeSetObject:(id)object forKey:(id<NSCopying>)key;

@end

NS_ASSUME_NONNULL_END

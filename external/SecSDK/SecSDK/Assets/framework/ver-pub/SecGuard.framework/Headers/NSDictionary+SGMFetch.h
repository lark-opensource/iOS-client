//
//  NSDictionary+SGMFetch.h
//  SecSDK
//
//  Created by renfeng.zhang on 2018/1/19.
//  Copyright © 2018年 Zhi Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (SGMFetch)

- (NSDictionary *)sgm_dictionaryKey:(id)key;
- (NSArray *)sgm_arrayKey:(id)key;
- (NSNumber *)sgm_numberKey:(id)key;
- (NSString *)sgm_stringKey:(id)key;
- (BOOL)sgm_boolKey:(id)key;
- (double)sgm_doubleKey:(id)key;
- (double)sgm_doubleKey:(id)key default:(double)defaultValue;
- (long long)sgm_longlongKey:(id)key;
- (int)sgm_intKey:(id)key;

@end //NSDictionary (SGMFetch)

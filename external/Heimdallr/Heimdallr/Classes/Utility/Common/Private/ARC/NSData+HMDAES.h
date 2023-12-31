//
//  NSData+HMDAES.h
//  Pods
//
//  Created by fengyadong on 2018/9/4.
//

#import <Foundation/Foundation.h>

@interface NSData (HMDAES)

- (NSData *)HMDAES128EncryptedDataWithKey:(NSString *)key;
- (NSData *)HMDAES128DecryptedDataWithKey:(NSString *)key;
- (NSData *)HMDAES128EncryptedDataWithKey:(NSString *)key iv:(NSString *)iv;
- (NSData *)HMDAES128DecryptedDataWithKey:(NSString *)key iv:(NSString *)iv;

@end

//
//  NSData+BulletXSecurity.h
//  Bullet-Pods-Aweme
//
//  Created by zhaoyu on 2020/12/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (BulletXSecurity)

- (NSData *)bullet_AES128EncryptedDataWithKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END

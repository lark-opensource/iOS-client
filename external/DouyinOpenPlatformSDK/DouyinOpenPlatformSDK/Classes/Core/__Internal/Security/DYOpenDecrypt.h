//
//  Decrypt.h
//  DouyinOpenSDKExtension
//
//  Created by bytedance on 2022/2/15.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface NSData(DYOpenDecrypt)

- (NSData *)dyopen_aesDecrypt:(NSData *)key iv:(NSData *)iv;
- (NSData *)dyopen_IV;

@end

@interface NSString(DYOpenDecrypt)

- (NSString *)dyopen_MD5;
- (NSData *)dyopen_aesDecrypt:(NSString *)key iv:(NSString *)iv;
- (NSString *)dyopen_decryptedWithSeed:(NSString*)seed salt:(NSString*)salt;
- (id)dyopen_json;

@end
NS_ASSUME_NONNULL_END

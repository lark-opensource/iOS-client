//
//  NSData+TSASignature.h
//  TTTopSignature
//
//  Created by 黄清 on 2018/10/17.


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (TSASignature)

+ (NSData *)tsa_hash:(NSData *)dataToHash;
+ (NSData *)tsa_sha256HMacWithData:(NSData *)data withKey:(NSData *)key;

@end

NS_ASSUME_NONNULL_END

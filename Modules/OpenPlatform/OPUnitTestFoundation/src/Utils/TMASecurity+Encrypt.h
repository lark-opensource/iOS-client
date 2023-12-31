//
//  TMASecurity+Encrypt.h
//  OPUnitTestFoundation
//
//  Created by baojianjun on 2023/7/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData(Encrypt)

- (nullable NSData *)tma_aesEncrypt:(NSData *)key iv:(NSData *)iv error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

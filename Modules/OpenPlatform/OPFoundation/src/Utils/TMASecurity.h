//
//  TMASecurity.h
//  Timor
//
//  Created by muhuai on 2018/4/8.
//

#import <Foundation/Foundation.h>

@interface NSData(tma_security)

- (NSData *)tma_aesDecrypt:(NSData *)key iv:(NSData *)iv;

@end

@interface NSString(tma_security)

- (NSData *)tma_aesDecrypt:(NSString *)key iv:(NSString *)iv;
@end

//
//  RtcCryptor.h
//  ByteView
//
//  Created by ZhangJi on 2023/5/11.
//

#import <Foundation/Foundation.h>
#import <ByteViewRtcBridge/RtcCrypting.h>
#include "rust_encrypt.h"

NS_ASSUME_NONNULL_BEGIN

@interface E2eeRtcCryptor : NSObject<RtcCrypting>

@property (nonatomic, readonly) NSMutableDictionary<NSNumber *, NSNumber *> *encryptErrors;
@property (nonatomic, readonly) NSMutableDictionary<NSNumber *, NSNumber *> *decryptErrors;

- (instancetype)initWithAlgorithm:(ResourceEncryptAlgorithm)algorithm key:(NSData *)key;

@end

NS_ASSUME_NONNULL_END

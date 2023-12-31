//
//  NSString+BDCTCrypto.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/5/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSString (BDCTCrypto)

- (NSString *)bdct_packedData;

@end

NS_ASSUME_NONNULL_END

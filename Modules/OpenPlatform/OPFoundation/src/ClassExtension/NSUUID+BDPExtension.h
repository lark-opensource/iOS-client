//
//  NSUUID+BDPExtension.h
//  Timor
//
//  Created by 傅翔 on 2019/9/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSUUID (BDPExtension)

+ (NSString *)bdp_timestampUUIDString;

@end

NS_ASSUME_NONNULL_END

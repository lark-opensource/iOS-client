//
//  BDPTracingManager+PrivateAPI.h
//  Timor
//
//  Created by changrong on 2020/5/24.
//

#import <Foundation/Foundation.h>
#import "BDPTracing.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPTracingManager (PrivateAPI)

+ (void)doBlock:(dispatch_block_t)block withCurrentTracing:(BDPTracing *)tracing;

@end

NS_ASSUME_NONNULL_END

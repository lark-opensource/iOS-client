//
//  NLEProcessUnit.h
//  NLEPlatform-Pods-Aweme
//
//  Created by raomengyun on 2021/7/4.
//

#import <Foundation/Foundation.h>
#import "NLEMacros.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEProcessQueue: NSObject

- (void)addSyncUnitWithBlock:(NLEBaseBlock)block;
- (void)addAsyncUnitWithBlock:(void (^)(NLEBaseBlock finish))block;

- (void)runWithCompletion:(NLEBaseBlock)completion;

@end

NS_ASSUME_NONNULL_END

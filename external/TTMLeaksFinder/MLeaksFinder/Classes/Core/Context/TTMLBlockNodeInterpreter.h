//
//  TTMLBlockNodeInterpreter.h
//  TTMLeaksFinder-Pods-Aweme
//
//  Created by maruipu on 2020/12/9.
//

#import <Foundation/Foundation.h>
#import "TTMLLeakCycle.h"

extern NSString * const TTMLBlockNodeAddressKey;
extern NSString * const TTMLBlockNodeNameKey;

NS_ASSUME_NONNULL_BEGIN

@interface TTMLBlockNodeInterpreter : NSObject <TTMLLeakCycleNodeInterpreter>

@end

NS_ASSUME_NONNULL_END

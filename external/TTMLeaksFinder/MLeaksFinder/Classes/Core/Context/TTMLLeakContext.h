//
//  TTMLLeakContext.h
//  TTMLeaksFinder
//
//  Created by maruipu on 2020/11/3.
//

#import <Foundation/Foundation.h>
#import "TTMLLeakCycle.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTMLLeakContext : NSObject

@property (atomic, strong) NSArray<NSString *> *viewStack;
@property (atomic, strong) NSSet<NSNumber *> *parentPtrs;
@property (atomic, strong) NSArray<TTMLLeakCycle *> *cycles;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end



@interface TTMLLeakContextMap : NSObject

+ (instancetype)sharedInstance;
- (TTMLLeakContext *)ttml_leakContextOf:(id)obj;
- (BOOL)ttml_hasRetainCycleOf:(id)obj;

@end

NS_ASSUME_NONNULL_END



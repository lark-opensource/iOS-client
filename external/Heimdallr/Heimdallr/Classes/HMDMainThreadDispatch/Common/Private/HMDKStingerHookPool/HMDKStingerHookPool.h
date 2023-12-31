//
//  HMDKStingerHookPool.h
//  Indexer
//
//  Created by Martin Lyu on 2022/3/14.
//

#import <Foundation/Foundation.h>
#import "HMDWPDynamicSafeData.h"
#import "HMDOCMethod.h"

@protocol StingerParams;

typedef void(^HMDStingerHookOperation)(id<StingerParams> _Nonnull params,
                                       HMDWPDynamicSafeData * _Nonnull returnStore,
                                       size_t returnSize);

NS_ASSUME_NONNULL_BEGIN

@interface HMDKStingerHookPool : NSObject

+ (BOOL)hookOCMethod:(HMDOCMethod *)method
               block:(HMDStingerHookOperation)operationBlock;

@end

NS_ASSUME_NONNULL_END

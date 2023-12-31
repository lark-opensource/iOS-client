//
//  WCMemoryStatConfig.h
//  Pods-IESDetection_Example
//
//  Created by zhufeng on 2021/8/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMMemoryStatConfig : NSObject

+ (MMMemoryStatConfig *)defaultConfiguration;

/**
 * The filtering strategy of the stack
 */

// If the malloc size more than 'skipMinMallocSize', the stack will be saved. Default to PAGE_SIZE
@property (nonatomic, assign) int skipMinMallocSize;
// Otherwise if the stack contains App's symbols in the last 'skipMaxStackDepth' address,
// the stack also be saved. Default to 8
@property (nonatomic, assign) int skipMaxStackDepth;

@property (nonatomic, assign) int dumpCallStacks; // 0 = not dump, 1 = dump all objects' call stacks, 2 = dump only objc objects'

@end

NS_ASSUME_NONNULL_END

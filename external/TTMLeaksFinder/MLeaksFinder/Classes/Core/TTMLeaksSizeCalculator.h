//
//  TTMLeaksSizeCalculator.h
//  TTMLeaksFinder
//
//  Created by  郎明朗 on 2021/5/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** 获取该对象所占用的内存size
 *  maxNodeNumber:最多遍历的对象个数
 *  maxTreeDepth :遍历树时的最大深度
 */

@interface TTMLeaksSizeCalculator : NSObject
+ (double)tt_memoryUseOfObj:(id)obj;

+ (double)tt_memoryUseOfObj:(id)obj maxNodeNumber:(NSInteger)maxNodeNumber maxTreeDepth:(NSInteger)maxTreeDepth;
@end

NS_ASSUME_NONNULL_END

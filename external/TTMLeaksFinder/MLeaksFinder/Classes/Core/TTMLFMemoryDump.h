//
//  MemoryDump.h
//  MLeaksFinder
//
//  Created by renpengcheng on 2019/4/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTMLFMemoryDump : NSObject

// 获取全部实例数量
+ (NSDictionary<NSString*,NSNumber*>*)instanceCountsForClassNames;

/**
 每隔interval，检测是否超过阈值，如果超过，则开始dump，并上传（默认阈值是 OOM * 2/3）
 
 @param interval 检测的时间间隔, interval不能过短,暂定最短60s
 @param countLimit 上传数量最多的前
 @param ignore 忽略系统类别
 */

+ (void)enableMemoryDumpWithInterval:(NSTimeInterval)interval
                               limit:(NSInteger)countLimit
                        ignoreSystem:(BOOL)ignore;
@end

NS_ASSUME_NONNULL_END

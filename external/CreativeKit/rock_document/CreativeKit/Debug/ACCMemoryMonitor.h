//
//  ACCMemoryMonitor.h
//  CameraClient
//
//  Created by Liu Deping on 2020/5/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMemoryMonitor : NSObject

+ (void)startCheckMemoryLeaks:(id)object;

+ (void)startMemoryMonitorForContext:(NSString *)context tartgetClasses:(NSArray<Class> *)classes maxInstanceCount:(NSUInteger)count;

+ (void)addObject:(id)obj forContext:(NSString *)context;

+ (void)stopMemoryMonitorForContext:(NSString *)context;

+ (void)ignoreContext:(NSString *)context;

@end

NS_ASSUME_NONNULL_END

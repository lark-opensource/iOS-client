//
//  BDHybridBaseMonitor.h
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/6/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDHybridBaseMonitor : NSObject

+ (BOOL)startMonitorWithClasses:(NSSet *)classes
                        setting:(NSDictionary *)setting;
+ (BOOL)startMonitorWithSetting:(NSDictionary *)setting;

@end

NS_ASSUME_NONNULL_END

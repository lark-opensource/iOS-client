//
//  IESLiveWebViewOfflineMonitor.h
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/8/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESLiveWebViewOfflineMonitor : NSObject

+ (void)startMonitorWithClasses:(NSSet *)classes
                        setting:(NSDictionary *)setting;

@end

NS_ASSUME_NONNULL_END

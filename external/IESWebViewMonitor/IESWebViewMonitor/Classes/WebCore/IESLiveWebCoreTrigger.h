//
//  IESLiveWebCoreTrigger.h
//  IESWebViewMonitor
//
//  Created by 蔡腾远 on 2020/1/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESLiveWebCoreTrigger : NSObject

+ (void)startMonitorWithClasses:(NSSet *)classes
                        setting:(NSDictionary *)setting;

@end

NS_ASSUME_NONNULL_END

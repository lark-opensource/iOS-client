//
//  NSObject+ACCEventContext.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/1.
//

#import <Foundation/Foundation.h>
#import "ACCEventContext.h"

@interface NSObject (ACCEventContext)

@property (nonatomic, strong)ACCEventContext *acc_eventContext;

/**
 V3 版本埋点

 @param event    event
 */
- (void)acc_trackEvent:(NSString *)event;

/**
 V3 版本埋点

 @param event    事件名
 @param block    事件参数构造block
 */
- (void)acc_trackEvent:(NSString *)event attributes:(void(^)(ACCAttributeBuilder *builder))block;

/**
 V3 版本埋点

 @param event       事件名
 @param context     事件参数context
 */
- (void)acc_trackEvent:(NSString *)event context:(ACCEventContext *)context;
+ (void)acc_trackEvent:(NSString *)event context:(ACCEventContext *)context;

@end

//
//  HMDControllerMonitor.h
//  Heimdallr
//
//  Created by joy on 2018/5/10.
//

#import <Foundation/Foundation.h>

@protocol HMDControllerMonitorDelegate
- (void)hmdControllerName:(NSString *)pageName typeName:(NSString *)typeName timeInterval:(NSTimeInterval)interval isFirstOpen:(NSInteger)isFirstOpen;
@end

@interface HMDControllerMonitor : NSObject

@property (nonatomic, weak) id<HMDControllerMonitorDelegate> delegate;

+ (instancetype)sharedInstance;
- (void)addControllerMonitorWithPageName:(NSString *)pageName methodSelector:(NSString *)selectorName timeInterval:(NSTimeInterval)interval isFirstOpen:(NSInteger)isFirstOpen;
//- (void)addControllerMonitorWithViewControllerTimeStamp:(NSTimeInterval)timeStamp pageName:(NSString *)pageName state:(HMDControllerMonitorState)state typeName:(NSString *)typeName;
@end

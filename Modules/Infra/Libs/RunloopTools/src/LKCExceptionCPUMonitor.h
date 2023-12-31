//
//  LKCExceptionCPUMonitor.h
//  LarkMonitor
//
//  Created by sniperj on 2020/2/5.


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^LKCCPUCallBack)(double);

@interface LKCExceptionCPUMonitor : NSObject

+ (id)registCallback:(LKCCPUCallBack)callback timeInterval:(int)interval;
+ (void)unRegistCallback:(id)callback;

@end

NS_ASSUME_NONNULL_END

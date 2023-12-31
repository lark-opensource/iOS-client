//
//  TTKitchenKeyReporter.h
//  TTKitchen
//
//  Created by liujinxing on 2020/8/31.
//

#import <Foundation/Foundation.h>
#import "TTKitchenManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTKitchenKeyReporter : NSObject <TTKitchenKeyMonitor, TTKitchenKeyErrorReporter>

/**
单个Key是否只上报一次堆栈信息
*/
@property(nonatomic, assign) BOOL keyStackReportRepeatly;
@property(nonatomic, assign) BOOL keyStackReportEnabled;

+ (instancetype)sharedReporter;

@end

NS_ASSUME_NONNULL_END

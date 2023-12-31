//
//  NSFileManager+Monitor.h
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/11/20.
//

#import <Foundation/Foundation.h>
#import "FCFileMonitorInterface.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (Monitor) <FCFileMonitorInterface>

@end

NS_ASSUME_NONNULL_END

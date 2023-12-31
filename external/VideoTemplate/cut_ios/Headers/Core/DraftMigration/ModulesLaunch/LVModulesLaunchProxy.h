//
//  LVModulesLaunchProxy.h
//  Pods
//
//  Created by kevin gao on 11/3/19.
//

#import <Foundation/Foundation.h>
#import "LVModulesLaunchExport.h"
#import "LVModulesLaunchStatistics.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVModulesLaunchProxy : NSObject <LVModulesLaunchStatisticsDeleagte, LVModulesLaunchExportDelegate>

@end

NS_ASSUME_NONNULL_END

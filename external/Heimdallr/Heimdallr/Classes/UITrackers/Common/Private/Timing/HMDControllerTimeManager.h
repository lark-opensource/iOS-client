//
//  HMDControllerTimeManager.h
//  Heimdallr
//
//  Created by joy on 2018/5/10.
//

#import <Foundation/Foundation.h>
#import "HMDControllerMonitor.h"
#import "HMDControllerTimeRecord.h"
#import "HeimdallrModule.h"

@interface HMDControllerTimeManager : HeimdallrModule
+ (instancetype)sharedInstance;

// records
- (NSArray *)fetchUploadRecords;
@end

//
//  HMDGWPASanManager.h
//  HMDGWPASanManager
//
//  Created by someone at yesterday
//

#import <Foundation/Foundation.h>
#import "HMDGWPAsanOption.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDGWPASanManager : NSObject

+ (void)startWithOption:(HMDGWPAsanOption *)option;

@property(class, nonatomic, readonly, getter=isStarting) BOOL starting;

@property(class, nonatomic, readonly, getter=isStarted)  BOOL started;

@end

NS_ASSUME_NONNULL_END

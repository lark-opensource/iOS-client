//
//  BDUGTrackerInterface.h
//  Pods
//
//  Created by shuncheng on 2018/12/27.
//

#import <Foundation/Foundation.h>
#import <BDUGContainer/BDUGContainerProtocol.h>
#import <BDUGContainer/BDUGContainer.h>

NS_ASSUME_NONNULL_BEGIN

#define BDUGTracker BDUG_CONTAINER_OBJECT(BDUGTrackerInterface)

@protocol BDUGTrackerInterface <BDUGContainerProtocol>

- (void)event:(NSString *)event params:(NSDictionary * _Nullable)params;

@end

NS_ASSUME_NONNULL_END

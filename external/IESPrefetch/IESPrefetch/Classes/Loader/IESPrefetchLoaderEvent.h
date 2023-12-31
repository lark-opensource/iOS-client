//
//  IESPrefetchLoaderEvent.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/17.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchDefines.h"

NS_ASSUME_NONNULL_BEGIN

@protocol IESPrefetchLoaderEvent <NSObject>

@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, strong) NSError *error;

@end

FOUNDATION_EXPORT NSTimeInterval eventDurationToNow(id<IESPrefetchLoaderEvent> event);

@interface IESPrefetchLoaderConfigEvent : NSObject<IESPrefetchLoaderEvent>

@property (nonatomic, copy) NSString *project;

@end

@interface IESPrefetchLoaderTriggerEvent : NSObject<IESPrefetchLoaderEvent>

@property (nonatomic, copy) NSString *occasion;
@property (nonatomic, copy) NSString *schema;

@end

@interface IESPrefetchLoaderAPIEvent : NSObject<IESPrefetchLoaderEvent>

@property (nonatomic, copy) NSString *apiName;
@property (nonatomic, assign) IESPrefetchCache cacheStatus;

@end

NS_ASSUME_NONNULL_END

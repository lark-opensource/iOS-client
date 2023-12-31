//
//  BDAutoTrackEventGenerator.h
//  RangersAppLog
//
//  Created by bytedance on 7/21/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef enum : NSUInteger {
    BDAutoTrackEventTypeDefault,
    BDAutoTrackEventTypeUserDefined,
    BDAutoTrackEventTypeLaunch,
    BDAutoTrackEventTypeTerminate
} BDAutoTrackEventType;

@class BDAutoTrack;
@interface BDAutoTrackEventGenerator : NSObject

+ (instancetype)generatorForTrack:(BDAutoTrack *)tracker;

@property (nonatomic, weak) BDAutoTrack *tracker;
//
////event[...] for Internal
//@property (nonatomic, copy) NSDictionary<NSString *,id>* (^eventParameterBlock)(void);
//
////event.param[...] for Internal
//@property (nonatomic, copy) NSDictionary<NSString *,id>* (^internalGlobalUserParameterBlock)(void);
//
////event.param[...] for Public
//@property (nonatomic, copy) NSDictionary<NSString *,id>* (^globalUserParameterBlock)(void);


- (void)addGlobalUserParameter:(NSDictionary <NSString *,id> *)parameter;

- (void)removeGlobalUserParameterForKey:(NSString *)key;

- (void)addEventParameter:(NSDictionary <NSString *,id> *)parameter;

- (void)removeEventParameterForKey:(NSString *)key;


- (BOOL)trackEvent:(NSString *)event_
         parameter:(NSDictionary <NSString *,id> *)parameter_
           options:(nullable id)opt;

- (BOOL)trackLaunch:(NSDictionary *)launch;

- (BOOL)trackTerminate:(NSDictionary *)terminate;

- (BOOL)trackEventType:(NSString *)type
             eventBody:(NSDictionary *)event
               options:(nullable id)opt;

- (dispatch_queue_t)executionQueue;
                

#pragma mark -


- (void)setBatchTriggerBulk:(NSUInteger)bulk;
- (void)restoreBulkCounter;
        

@end

NS_ASSUME_NONNULL_END

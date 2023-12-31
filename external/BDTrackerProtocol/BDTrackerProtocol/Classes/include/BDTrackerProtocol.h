//
//  BDTrackerProtocol.h
//  Pods-BDTrackerProtocol
//
//  Created by lizhuopeng on 2019/3/11.
//

#import "BDTrackerProtocolDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTrackerProtocol : NSObject

+ (void)eventV3:(NSString *_Nonnull)event params:(NSDictionary *_Nullable)params;
+ (void)eventV3:(NSString *_Nonnull)event params:(NSDictionary *_Nullable)params isDoubleSending:(BOOL)isDoubleSending;

//================================V1 Interface===================================
+ (void)event:(nonnull NSString *)event;
+ (void)event:(nonnull NSString *)event label:(nonnull NSString *)label;
+ (void)eventData:(nonnull NSDictionary *)event;
/*
 *  use dictionary as track data
 */
+ (void)eventData:(nonnull NSDictionary *)event isV3Format:(BOOL)isV3Format;

/**
 *  category = default
 *  id should be string or number
 */
+ (void)event:(nonnull NSString *)event
        label:(nonnull NSString *)label
        value:(nullable id)value
     extValue:(nullable id)extValue
    extValue2:(nullable id)extValue2;

+ (void)event:(nonnull NSString *)event
        label:(nonnull NSString *)label
        value:(nullable id)value
     extValue:(nullable id)extValue
    extValue2:(nullable id)extValue2
         dict:(nullable NSDictionary *)aDict;

+ (void)event:(nonnull NSString *)event label:(nonnull NSString *)label json:(nullable NSString *)json;
+ (void)category:(nonnull NSString *)category event:(nonnull NSString *)event label:(nonnull NSString *)label json:(nullable NSString *)json;
+ (void)category:(nonnull NSString *)category event:(nonnull NSString *)event label:(nonnull NSString *)label dict:(nullable NSDictionary *)aDict;
+ (void)category:(nonnull NSString *)category event:(nonnull NSString *)event label:(nonnull NSString *)label dict:(nullable NSDictionary *)aDict json:(nullable NSString *)json;

+ (void)trackEventWithCustomKeys:(nonnull NSString *)event label:(nonnull NSString *)label value:(nullable NSString *)value source:(nullable NSString *)source extraDic:(nullable NSDictionary *)extraDic;

///////////////////////////////////////////////////////////////////////////////////////////

/**
 session id

 @return session id
 */
+(NSString *)sessionID;

/**
  install id

 @return install id
 */
+ (NSString *)installID;

/**
 device id

 @return device id
 */
+ (NSString *)deviceID;

/**
  client did
 
 @return client did
 */
+ (NSString *)clientDID;

/**
set launch
*/
+ (void)setLaunchFrom:(BDTrackerLaunchFrom)from;

/**
get launch
*/
+ (BDTrackerLaunchFrom)launchFrom;

/**
APP launch string keyword
*/
+ (nullable NSString *)launchFromString;

@end

NS_ASSUME_NONNULL_END


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/**
 业务方提供的applog上报接口
 */
typedef void (^IESAppLogTrackerBlock)(NSString *event, NSDictionary *params, NSString *eventType);

@interface IESAppLogger : NSObject

+ (instancetype)sharedInstance;
/**
 给业务端的applog回调

 @param appId 业务端appId
 @param callback 回调
 */
- (void)setAppLogCallback:(NSString *_Nonnull)appId callback:(IESAppLogTrackerBlock _Nullable)callback isAbroad:(BOOL)isAbroad;

/**
 sdk applog事件上报

 @param event 事件名
 @param params 参数
 @param eventType 事件类型
 */
- (void)appLogOnEvent:(NSString *_Nonnull)event params:(NSMutableDictionary *_Nullable)params eventType:(NSString *_Nonnull)eventType; // 埋点数据不上报业务线，只上报到智创
- (void)appLogOnEvent:(NSString *_Nonnull)event params:(NSMutableDictionary *_Nullable)params eventType:(NSString *_Nonnull)eventType uploadToBusiness:(BOOL)uploadToBusiness;

NS_ASSUME_NONNULL_END
@end




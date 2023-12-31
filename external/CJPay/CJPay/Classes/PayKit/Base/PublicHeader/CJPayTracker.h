//
//  CJPayTracker.h
//  CJPay
//
//  Created by 王新华 on 2019/2/12.
//

#import <Foundation/Foundation.h>

#define CJTracker CJPayTracker

NS_ASSUME_NONNULL_BEGIN


/**
 业务配置的代理，现在只有埋点
 */
@protocol CJPayManagerBizDelegate<NSObject>

/**
 业务打点
 
 @param event 时间名称
 @param params 参数字段 字典形式
 */
- (void)event:(NSString *_Nonnull)event params:(NSDictionary *_Nullable)params;

@end

@interface CJPayTracker : NSObject

@property(nonatomic, weak) id<CJPayManagerBizDelegate> trackerDelegate;

+ (instancetype)shared;

+ (void)addCommonTrackDic:(NSDictionary *)commonTrackDic;

+ (void)event:(NSString *)event params:(NSDictionary *)params;

- (void)addTrackerDelegate:(id<CJPayManagerBizDelegate>) trackerDelegate;

- (void)removeTrackerDelegate:(id<CJPayManagerBizDelegate>) trackerDelegate;

@end

NS_ASSUME_NONNULL_END

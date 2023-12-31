//
//  SGMSafeGuardLoggerManager.h
//  SecGuard
//
//  Created by jianghaowne on 2018/7/3.
//

#import <Foundation/Foundation.h>

#define SGM_START_TS \
try {} @finally {} \
CFTimeInterval sgm_st = CFAbsoluteTimeGetCurrent()

#define SGM_END_TS \
try {} @finally {} \
CFTimeInterval dur = CFAbsoluteTimeGetCurrent() - sgm_st

#define SGM_START_TS_CURTHR \
try {} @finally {} \
struct timespec timeStart, timeEnd; \
if (@available(iOS 10.0, *)) { \
    clock_gettime(CLOCK_THREAD_CPUTIME_ID, &timeStart); \
}

#define SGM_END_TS_CURTHR \
try {} @finally {} \
CFTimeInterval durCurThr = -1;\
if (@available(iOS 10.0, *)) { \
    clock_gettime(CLOCK_THREAD_CPUTIME_ID, &timeEnd); \
    durCurThr = timeEnd.tv_sec + ((double)timeEnd.tv_nsec / NSEC_PER_SEC) -  timeStart.tv_sec - ((double)timeStart.tv_nsec / NSEC_PER_SEC); \
}

#define SGM_DUR dur
#define SGM_DUR_CURTHR durCurThr

typedef NS_ENUM(NSUInteger, SGMSafeGuardLoggerUploadScene) {
    SGMSafeGuardLoggerUploadSceneFirstCreate, ///< 首次创建
    SGMSafeGuardLoggerUploadSceneForeground, ///< 进前台
    SGMSafeGuardLoggerUploadSceneBackground, ///< 进后台
};

typedef NS_ENUM(NSUInteger, SGMSafeGuardLoggerCategory) {
    SGMSafeGuardLoggerCategorySig = 1, ///< 签名
    SGMSafeGuardLoggerCategoryEnv, ///< 采集
    SGMSafeGuardLoggerCategoryFore, ///< 前置防御
    SGMSafeGuardLoggerCategoryVerify, ///< 验证码
    SGMSafeGuardLoggerCategoryConsume, ///< 性能
    SGMSafeGuardLoggerCategoryOther, ///< 其他
};

@protocol SGMSafeGuardLoggerProtocol

@optional

+ (instancetype)logger;

- (void)logEvent:(NSString *)event category:(SGMSafeGuardLoggerCategory)category customInfos:(NSDictionary *)customInfos;
- (void)logEvent:(NSString *)event infos:(NSDictionary *)infos detailInfos:(NSDictionary *)detailInfos;
- (void)logEventsFromArray:(NSArray <NSDictionary *> *)array additionInfos:(NSDictionary *)additionInfos;
- (BOOL)needUploadForScene:(SGMSafeGuardLoggerUploadScene)scene;
- (void)doUpload;
- (void)clearLegacyLogs;

@end

@interface SGMSafeGuardLoggerManager : NSObject

+ (instancetype)sharedManager;

- (void)registLogger:(id<SGMSafeGuardLoggerProtocol>)logger;

- (void)logEvent:(NSString *)event category:(SGMSafeGuardLoggerCategory)category customInfos:(NSDictionary *)customInfos;

- (void)logEventsFromArray:(NSArray <NSDictionary *> *)array additionInfos:(NSDictionary *)additionInfos;

- (void)logEvent:(NSString *)event infos:(NSDictionary *)infos details:(NSDictionary *)details;

- (void)upload:(SGMSafeGuardLoggerUploadScene)scene;

@end

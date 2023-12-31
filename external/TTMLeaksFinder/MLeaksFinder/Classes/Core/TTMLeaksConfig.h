//
//  MLeaksConfig.h
//  MLeaksFinder
//
//  Created by xushuangqing on 2019/8/12.
//

#import <Foundation/Foundation.h>
#import "TTMLLeakCycle.h"

NS_ASSUME_NONNULL_BEGIN

extern NSInteger TTMLStackDepthInBuildRetainTreeOperation;
extern NSInteger TTMLOneClassCheckMaxCount;
extern NSInteger TTMLOneClassBuildRetainTreeMaxCount;
extern NSInteger TTMLBuildRetainTreeMaxNode;

extern NSInteger TTMLStackDepthInDetectRetainCycleOperation;
extern NSInteger TTMLOneClassOnceDetectRetainCycleMaxCount;
extern NSInteger TTMLOneClassOnceDetectRetainMaxTraversedNodeNumber;

typedef NSString *_Nullable(^MLeaksGetUserInfoBlock)(void);

typedef NS_OPTIONS(NSUInteger, MLeaksViewStackType) {
    MLeaksViewStackNone = 0,
    MLeaksViewStackTypeViewController = 1 << 0,
    MLeaksViewStackTypeView = 1 << 1,
    MLeaksViewStackTypeObject = 1 << 2,
};

@interface TTMLeaksCase : NSObject

/**
* 透传 MLeaksConfig.aid
**/
@property (nonatomic, copy, nonnull) NSString *aid;

/**
* 在退出这个 ViewStack 的时候发生了泄漏
**/
@property (nonatomic, copy, nullable) NSArray *viewStack;

/**
* 引用环
**/
@property (nonatomic, copy, nullable) NSString *retainCycle;

@property (nonatomic, strong) TTMLLeakCycle *leakCycle;

/**
* 引用环中的关键结点，可以使用这个结点来分配到人，策略：https://bytedance.feishu.cn/docs/doccn1casmnoTZkQcYai2cFCvof#
**/
@property (nonatomic, copy, nullable) NSString *cycleKeyClass;

/**
* 这个 Leak 的 ID，为 md5(引用环 + AppVersion)
**/
@property (nonatomic, copy, nullable) NSString *ID;

/**
* 这个 Leak 的 ID，为 md5(引用环)
**/
@property (nonatomic, copy, nullable) NSString *cycleID;

/**
* 透传 MLeaksConfig.buildInfo
**/
@property (nonatomic, copy, nullable) NSString *buildInfo;

/**
* 透传 MLeaksConfig.appVersion
**/
@property (nonatomic, copy, nonnull) NSString *appVersion;

/**
* 透传 MLeaksConfig.userInfoBlock 的返回值
**/
@property (nonatomic, copy, nullable) NSString *hostAppUserInfo;

/**
* 组件版本
**/
@property (nonatomic, copy, nullable) NSString *mleaksVersion;

- (NSDictionary *)transToParams;
- (NSDictionary *)transToNotificationUserInfo;

@end

@protocol TTMLeaksFinderDelegate <NSObject>

+ (void)leakDidCatched:(TTMLeaksCase *)leakCase;

@optional
+ (void)trackService:(NSString *)serviceName metric:(nullable NSDictionary <NSString *, NSNumber *> *)metric category:(nullable NSDictionary *)category extra:(nullable NSDictionary *)extraValue;

@end

@interface TTMLeaksConfig : NSObject

@property (nonatomic, copy, readonly) NSString *aid;

/**
 * 是否检测关联对象的强引用。启用该功能需要hook一些东西，影响暂时未知，建议开关控制确保随时可关闭
 **/
@property (nonatomic, assign) BOOL enableAssociatedObjectHook;

/**
*开关设置 是否开启非vc和view 的内存泄漏检测
 */
@property (nonatomic, assign) BOOL enableNoVcAndViewHook;

/**
 * 需要过滤的强引用关系
 * 库中已添加一些默认filter，业务方传入的filter将merge到默认filter上
 * 格式：
 * {
 *     "类名1" : [@"变量名1.1", @"变量名1.2"...],
 *     "类名2" : [@"变量名2.1", @"变量名2.2"...]...
 **/
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<NSString *> *> *filters;

/**
 * 设置上报的ViewStack类型，建议和默认 MLeaksViewStackTypeViewController
 **/
@property (nonatomic, assign) MLeaksViewStackType viewStackType;

/**
 * 版本号。报警中一次 ACK 会 ACK 同一版本且同样 retain cycled 的问题
 **/
@property (nonatomic, copy, readonly) NSString *appVersion;

/**
 * 业务方自定义信息，比如可以传入：本次打包的cid、分支名、用户did等，会体现在报警中作为附加信息
 **/
@property (nonatomic, copy, readonly) NSString *buildInfo;

/**
 * 业务方自定义信息，比如可以传入：本次打包的cid、分支名、用户did等，会体现在报警中作为附加信息
 **/
@property (nonatomic, copy) MLeaksGetUserInfoBlock userInfoBlock;

/**
* 业务方自定义信息，比如可以传入：@[@"XXXViewController"]，以跳过针对 XXXViewController 的检查
**/
@property (nonatomic, copy) NSArray<NSString *> *classWhitelist;

/**
* 业务方实现 delegate 后是否还继续向轻服务发送
**/
@property (nonatomic, assign) BOOL doubleSend;

@property (nonatomic,assign) BOOL enableAlogOpen;

@property (nonatomic,assign) NSInteger enableDetectSystemClass;


/**
* 业务方实现的 delegate，一旦 delegate 方法实现，MLeaksFinder 将不再向服务端上报内存泄漏，由业务方在 delegate 方法中上报
**/
@property (nonatomic, strong, readonly) Class<TTMLeaksFinderDelegate> delegateClass;

- (instancetype)initWithAid:(NSString *)aid;

- (instancetype)initWithAid:(NSString *)aid
 enableAssociatedObjectHook:(BOOL)enableAssociatedObjectHook
                    filters:(nullable NSDictionary<NSString *, NSArray<NSString *> *> *)filters
              viewStackType:(MLeaksViewStackType)viewStackType
                 appVersion:(NSString *)appVersion
                  buildInfo:(nullable NSString *)buildInfo
              userInfoBlock:(nullable MLeaksGetUserInfoBlock)userInfoBlock;

- (instancetype)initWithAid:(NSString *)aid
enableAssociatedObjectHook:(BOOL)enableAssociatedObjectHook
                   filters:(nullable NSDictionary<NSString *, NSArray<NSString *> *> *)filters
            classWhitelist:(nullable NSArray<NSString *> *)classWhitelist
             viewStackType:(MLeaksViewStackType)viewStackType
                appVersion:(NSString *)appVersion
                 buildInfo:(nullable NSString *)buildInfo
             userInfoBlock:(nullable MLeaksGetUserInfoBlock)userInfoBlock;

- (instancetype)initWithAid:(NSString *)aid
enableAssociatedObjectHook:(BOOL)enableAssociatedObjectHook
     enableNoVcAndViewHook:(BOOL)enableNoVcAndViewHook
                   filters:(nullable NSDictionary<NSString *, NSArray<NSString *> *> *)filters
            classWhitelist:(nullable NSArray<NSString *> *)classWhitelist
             viewStackType:(MLeaksViewStackType)viewStackType
                appVersion:(NSString *)appVersion
                 buildInfo:(nullable NSString *)buildInfo
             userInfoBlock:(nullable MLeaksGetUserInfoBlock)userInfoBlock
             delegateClass:(nullable Class<TTMLeaksFinderDelegate>)delegateClass;

- (instancetype)initWithAid:(NSString *)aid
enableAssociatedObjectHook:(BOOL)enableAssociatedObjectHook
     enableNoVcAndViewHook:(BOOL)enableNoVcAndViewHook
                   filters:(nullable NSDictionary<NSString *, NSArray<NSString *> *> *)filters
            classWhitelist:(nullable NSArray<NSString *> *)classWhitelist
             viewStackType:(MLeaksViewStackType)viewStackType
                appVersion:(NSString *)appVersion
                 buildInfo:(nullable NSString *)buildInfo
             userInfoBlock:(nullable MLeaksGetUserInfoBlock)userInfoBlock
                doubleSend:(BOOL)doubleSend
            enableAlogOpen:(BOOL)enableAlogOpen
   enableDetectSystemClass:(NSInteger)enableDetectSystemClass
             delegateClass:(nullable Class<TTMLeaksFinderDelegate>)delegateClass;

@end

NS_ASSUME_NONNULL_END

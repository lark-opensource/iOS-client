//
//  HMConfig.h
//  Hermas
//
//  Created by 崔晓兵 on 20/1/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^JSONFinishBlock)(NSError * _Nullable error, id _Nullable jsonObj);

@interface HMRequestModel : NSObject
@property (nonatomic, copy, nullable) NSString *requestURL;
@property (nonatomic, copy, nullable) NSString *method;
@property (nonatomic, strong, nullable) NSDictionary<NSString*, NSString*> *headerField;
@property (nonatomic, assign) BOOL needEcrypt;
@property (nonatomic, strong, nullable) NSData *postData;
@end

@protocol HMNetworkProtocol <NSObject>
@required
- (void)requestWithModel:(HMRequestModel * _Nonnull)model callback:(JSONFinishBlock _Nullable)callback;
@optional
- (BOOL)isReady;
@end


typedef NS_ENUM(NSInteger, HMConditionJudgeType) {
    HMConditionJudgeNone,
    HMConditionJudgeLess,
    HMConditionJudgeEqual,
    HMConditionJudgeGreater,
    HMConditionJudgeContain,
    HMConditionJudgeIsNULL,
};

typedef NS_ENUM(NSInteger, HMFlowControlStrategy) {
    HMFlowControlStrategyNormal = 0,    // 正常模式
    HMFlowControlStrategyLimited        // 限流模式
};

extern NSString * _Nonnull const kModuleUploadSuccess;


@interface HMAggregateParam : NSObject

/// 聚合文件总大小
@property (nonatomic, assign) int64_t fileSize;

/// 文件分区配置
@property (nonatomic, copy, nullable) NSDictionary<NSNumber*, NSNumber*> *fileConfig;

/// 特殊聚合字段 - 取最大值
@property (nonatomic, copy, nullable) NSDictionary<NSString*, NSArray*> *aggreIntoMax;

@end


@protocol HMModuleConfig <NSObject>

/// Module名称，和上传协议一一对应
@property (nonatomic, copy, nonnull) NSString *name;

/// 域名
@property (nonatomic, copy, nonnull) NSString *domain;

/// 上传path
@property (nonatomic, copy, nonnull) NSString *path;

/// 整体文件存储大小
@property (nonatomic, assign) NSUInteger maxStoreSize;

/// 未命中采样日志存储大小
@property (nonatomic, assign) NSUInteger maxLocalStoreSize;

/// 上传压缩时字典类型，与上传协议一一对应
@property (nonatomic, copy, nonnull) NSString *zstdDictType;

/// 是否支持双发
@property (nonatomic, assign) BOOL forwardEnabled;

/// 双发Url（自带域名）
@property (nonatomic, copy, nullable) NSString *forwardUrl;

/// 是否禁止文件分片上报，默认为NO
@property (nonatomic, assign) BOOL isForbidSplitReportFile;

/// 云控 Block（目前只有Batch）
@property (nonatomic, copy, nullable) void(^cloudCommandBlock)(NSData * base64String, NSString *ran);

/// 分通道降级状态更新（目前只针对事件）
@property (nonatomic, copy, nullable) void(^downgradeRuleUpdateBlock)(NSDictionary * _Nullable info);

/// 分通道降级（目前只针对事件、性能）
@property (nonatomic, copy, nullable) BOOL(^downgradeBlock)(NSString *logType, NSString * _Nullable serviceName, NSString *aid, double currentTime);

/// 标签校验（目前只针对事件）
@property (nonatomic, copy, nullable) BOOL(^tagVerifyBlock)(NSInteger tag);

/// 是否支持加密
@property (nonatomic, assign) BOOL enableEncrypt;

/// 不压缩不加密上报，仅在debug生效(默认是压缩上报)
@property (nonatomic, assign) BOOL enableRawUpload;

/// 聚合配置
@property (nonatomic, strong, nullable) HMAggregateParam *aggregateParam;

/// 共享写入线程
@property (nonatomic, assign) BOOL shareRecordThread;

@end


@class HMGlobalConfig;
@interface HMModuleConfig : NSObject <HMModuleConfig>

@end

@protocol HMGlobalConfig <NSObject>

/// 整体文件存储大小
@property (nonatomic, assign) NSUInteger maxStoreSize;

/// 文件最长存储事件
@property (nonatomic, assign) NSTimeInterval maxStoreTime;

/// 单个文件最大存储大小
@property (nonatomic, assign) NSUInteger maxFileSize;

/// 单个文件最多日志条数
@property (nonatomic, assign) NSUInteger maxLogNumber;

/// 单次上报最大日志大小
@property (nonatomic, assign) NSUInteger maxReportSize;

/// 上报最大间隔
@property (nonatomic, assign) NSTimeInterval reportInterval;

/// 流量控制下单次上报最大日志大小
@property (nonatomic, assign) NSUInteger limitReportSize;

/// 流量控制下上报最大间隔
@property (nonatomic, assign) NSTimeInterval limitReportInterval;

@end


@interface HMGlobalConfig : NSObject<HMGlobalConfig>

/// 文件存储根路径
@property (nonatomic, copy, nonnull) NSString *rootDir;

/// 宿主aid
@property (nonatomic, copy, nonnull) NSString *hostAid;

/// Heimdallr aid
@property (nonatomic, copy, nonnull) NSString *heimdallrAid;

/// zstd dic path
@property (nonatomic, copy, nullable) NSString *zstdDictPath;

/// quota path
@property (nonatomic, copy, nullable) NSString *quotaDictPath;

/// 加密 Block
@property (nonatomic, copy, nullable) NSData* (^encryptBlock)(NSData *_Nullable data);

/// 公共参数
@property (nonatomic, copy, nullable) NSDictionary *reportCommonParams;

@property (nonatomic, copy, nullable) NSDictionary* (^reportCommonParamsBlock)(void);

/// 文件头参数（低频变化）
@property (nonatomic, copy, nullable) NSDictionary *reportHeaderLowLevelParams;

/// 文件头参数（不变化）
@property (nonatomic, copy, nullable) NSDictionary *reportHeaderConstantParams;

/// 清理文件间隔
@property (nonatomic, assign) NSTimeInterval cleanupInterval;

/// 内存
@property (nonatomic, copy) int64_t (^memoryBlock)(void);

/// 内存极限
@property (nonatomic, copy) int64_t (^memoryLimitBlock)(void);

/// 虚拟内存用量
@property (nonatomic, copy) int64_t (^virtualMemoryBlock)(void);

/// 虚拟内存总量
@property (nonatomic, copy) int64_t (^totalVirtualMemoryBlock)(void);

/// 日志ID生成器
@property (nonatomic, copy) int64_t (^sequenceCodeGenerator)(NSString *_Nullable className);

/// 设备ID请求闭包
@property (nonatomic, copy, nullable) NSString* (^deviceIdRequestBlock)(void);

/// 机型性能描述
@property (nonatomic, copy, nullable) NSString *devicePerformance;

/// Heimdallr是否初始化完毕
@property (nonatomic, assign) BOOL heimdallrInitCompleted;

/// 是否使用原生网络进行上报
@property (nonatomic, copy) BOOL (^useURLSessionUploadBlock)(void);

/// 未命中采样日志禁止落盘
@property (nonatomic, assign) BOOL (^stopWriteToDiskWhenUnhitBlock)(void);

@end


@class HMModuleConfig;

@interface HMInstanceConfig : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithModuleId:(NSString * _Nonnull)moduleId aid:(NSString * _Nonnull)aid;

@property (nonatomic, copy, readonly, nonnull) NSString *moduleId;

@property (nonatomic, copy, readonly, nonnull) NSString *aid;

@property (nonatomic, assign) BOOL enableSemiFinished;

@property (nonatomic, assign) BOOL enableAggregate;

@property (nonatomic, weak, readonly, nullable) HMModuleConfig *moduleConfig;

@end


@interface HMSearchCondition : NSObject

@property (nonatomic, assign) HMConditionJudgeType judgeType;

@property (nonatomic, copy) NSString *_Nonnull key;

@property (nonatomic, assign) double threshold;

@property (nonatomic, copy) NSString * _Nullable stringValue;

@end


@interface HMSearchAndCondition : HMSearchCondition

@property (nonatomic, strong, readonly, nonnull) NSArray<HMSearchCondition *> *conditions;

- (void)addCondition:(nonnull HMSearchCondition *)condition;

@end


@interface HMSearchOrCondition : HMSearchCondition

@property (nonatomic, strong, readonly, nonnull) NSArray<HMSearchCondition *> *conditions;

- (void)addCondition:(nonnull HMSearchCondition *)condition;

@end


@interface HMSearchParam : NSObject

@property (nonatomic, copy, nonnull) NSString *moduleId;

@property (nonatomic, copy, nonnull) NSString *aid;

@property (nonatomic, strong, nonnull) HMSearchCondition *condition;

@property (nonatomic, strong, nullable) id userInfo;

@end

NS_ASSUME_NONNULL_END

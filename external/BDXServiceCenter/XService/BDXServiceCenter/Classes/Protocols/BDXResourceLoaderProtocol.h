//
//  BDXResourceLoaderProtocol.h
//  BDXResourceLoader
//
//  Created by David on 2021/3/14.
//

#ifndef BDXResourceLoaderProtocol_h
#define BDXResourceLoaderProtocol_h

#import "BDXServiceProtocol.h"
#import <BDXServiceCenter/BDXContext.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDXResourceProtocol;
@protocol BDXResourceLoaderTaskProtocol;
@protocol BDXResourceLoaderAdvancedOperatorProtocol;

@class BDXResourceLoaderConfig;
@class BDXResourceLoaderTaskConfig;

#pragma mark-- Block Define

typedef void (^BDXResourceLoaderResolveHandler)(id<BDXResourceProtocol> resourceProvider, NSString *resourceLoaderName);
typedef void (^BDXResourceLoaderRejectHandler)(NSError *error);
typedef void (^BDXResourceLoaderCompletionHandler)(id<BDXResourceProtocol> __nullable resourceProvider, NSError *__nullable error);
typedef void (^BDXResourceCompletionHandler)(NSData *_Nullable data, NSString *_Nullable pathURL, NSError *_Nullable error);
typedef void (^BDXGeckoCompletionHandler)(BOOL success, NSError *_Nullable error);

#pragma mark-- BDXResourceLoaderProtocol

@protocol BDXResourceLoaderProtocol <BDXServiceProtocol>

@required

/// @abstract 初始化或更新加载器设置.
/// @param config  BDXResourceLoaderConfig
- (void)updateLoaderConfig:(BDXResourceLoaderConfig *)config;

/// @abstract
/// 获得URL对应的资源，会依次访问LoaderProcessor进行资源获取，一旦有一个Processor获取成功，后面的Processor不再执行。
/// 如果前面的Processor获取失败，会交由下一个Processor处理。如果所有的Processor都处理失败则调用rejectHandler。
/// @param url  资源url
/// @param container  当前所在容器，可以为空
/// @param taskConfig  设置此次加载任务的配置，可以为空
/// @param completionHandler  完成回调
/// @result 返回一个标识本次资源加载任务的Task
- (id<BDXResourceLoaderTaskProtocol>)fetchResourceWithURL:(NSString *)url container:(UIView *__nullable)container taskConfig:(BDXResourceLoaderTaskConfig *__nullable)taskConfig completion:(BDXResourceLoaderCompletionHandler __nullable)completionHandler;

/// @abstract 取消下载.
/// @param task  由fetchResourceWithURI返回的对象，自己创建的对象无效
/// @result 如果当前任务已经处理结束则返回false
- (BOOL)cancelResourceLoad:(id<BDXResourceLoaderTaskProtocol>)task;

/// @abstract 删除资源
/// @param resource  BDXResourceProtocol对象实例
- (BOOL)deleteResource:(id<BDXResourceProtocol>)resource;

@optional

/// @abstract 通过Advanced Operator可以执行sync、prefetch等操作
- (id<BDXResourceLoaderAdvancedOperatorProtocol>)getAdvancedOperator;

@end

#pragma mark-- BDXResourceProtocol

typedef NS_ENUM(NSInteger, BDXResourceStatus) {
    BDXResourceStatusGecko,    //命中gecko资源
    BDXResourceStatusCdn,      //从cdn加载
    BDXResourceStatusCdnCache, //从cdn缓存中加载
    BDXResourceStatusBuildIn,  //加载打包的默认资源
    BDXResourceStatusOffline,  //加载已经下载到本地的离线资源
};

typedef NS_ENUM(NSInteger, BDXProcessType) {
    BDXProcessTypeGecko,
    BDXProcessTypeBuildin,
    BDXProcessTypeCdn,
};

/// BDXResource 资源的协议定义
@protocol BDXResourceProtocol <NSObject>

/// 该资源对应的 sourceURL
- (nullable NSString *)sourceUrl;
/// 该资源对应的 cdnURL
- (nullable NSString *)cdnUrl;
/// 该 gecko 资源对应的 channel
- (nullable NSString *)channel;
//  该 gecko 资源对应的 channel的版本
- (uint64_t)version;
/// 该 gecko 资源在 channel 下对应的相对路径
- (nullable NSString *)bundle;
/// 该资源的绝对路径
- (nullable NSString *)absolutePath;
/// 该资源的二进制内容
- (nullable NSData *)resourceData;
///资源对应的AccessKey
- (nullable NSString *)accessKey;
/// 资源类型
- (BDXResourceStatus)resourceType;
/// 原始URL
- (nullable NSString *)originSourceURL;

+ (instancetype)resourceWithURL:(NSURL *)url;

@end

#pragma mark-- BDXResourceLoaderProcessorProtocol

@protocol BDXResourceLoaderProcessorProtocol <NSObject>

@property(nonatomic, copy, readonly) NSString *resourceLoaderName;

/// @abstract 在此方法中Processor具体实现获取资源的逻辑.
/// @param url  资源url
/// @param container  当前所在容器，可以为空
/// @param loaderConfig  加载配置
/// @param taskConfig  任务配置
/// @param resolveHandler  获取成功
/// @param rejectHandler  获取失败
- (void)fetchResourceWithURL:(NSString *)url container:(UIView *__nullable)container loaderConfig:(BDXResourceLoaderConfig *__nullable)loaderConfig taskConfig:(BDXResourceLoaderTaskConfig *__nullable)taskConfig resolve:(BDXResourceLoaderResolveHandler)resolveHandler reject:(BDXResourceLoaderRejectHandler)rejectHandler;

/// @abstract
/// 取消下载，调用当前正在执行的Processor的cancel方法，并取消后续过程。
- (void)cancelLoad;

@end

/// 创建BDXResourceLoaderProcessor的Provider
typedef id<BDXResourceLoaderProcessorProtocol> _Nonnull (^BDXResourceLoaderProcessorProvider)(void);

#pragma mark-- BDXResourceLoaderConfig

@interface BDXResourceLoaderConfig : NSObject

@property(nonatomic, copy) NSString *accessKey; /// 设置默认gecko access
                                                /// key，每次请求若未设置TaskConfig则尝试使用此key

@property(nonatomic, strong) NSNumber *disableGurd;       /// 不读取Gecko下载数据
@property(nonatomic, strong) NSNumber *disableBuildin;    /// 不读取内置数据
@property(nonatomic, strong) NSNumber *disableGurdUpdate; /// 强制不触发gecko更新（dynamic参数失效）

@property(nonatomic, assign) BOOL disableGurdThrottle;
@property(nonatomic, assign) NSInteger gurdDownloadPrority;

@end

#pragma mark-- BDXResourceLoaderProcessorConfig

@interface BDXResourceLoaderProcessorConfig : NSObject

/// 设置自定义的高优先级加载器, 在默认加载器之前执行
@property(nonatomic, copy, nullable) NSArray<BDXResourceLoaderProcessorProvider> *highProcessorProviderArray;
/// 设置自定义的低优先级加载器, 在默认加载器之后执行
@property(nonatomic, copy, nullable) NSArray<BDXResourceLoaderProcessorProvider> *lowProcessorProviderArray;
/// 禁用默认处理器的执行，设置后只会使用传入的highProcessors与lowProcessors
@property(nonatomic, assign) BOOL disableDefaultProcessors;
/// 调整默认加载器个数或顺序，如只使用CDN可设为：@[@(BDXProcessTypeCdn)]; 若为空，默认处理器会按内置规则顺序进行加载。
@property(nonatomic, copy, nullable) NSArray<NSNumber *> *defaultProcessorsSequence;

@end

#pragma mark-- BDXResourceLoaderTaskConfig

@interface BDXResourceLoaderTaskConfig : NSObject

/// gecko 下载相关
@property(nonatomic, copy) NSString *accessKey;   /// gecko的 access key
@property(nonatomic, copy) NSString *channelName; /// gecko的 channel
@property(nonatomic, copy) NSString *bundleName;  /// gecko的 bundle

/// 更新策略
///  0-只读取Gecko本地
///  1-读取Gecko本地,
///  若获取到数据则返回并且触发新数据同步，若未能获取数据则尝试新建GurdSyncTask拉取数据
///  2-直接尝试新建GurdSyncTask拉取数据
@property(nonatomic, strong) NSNumber *dynamic;

@property(nonatomic, strong) NSNumber *onlyLocal;         /// 不走CDN  不等待Gecko更新返回
@property(nonatomic, strong) NSNumber *disableGurd;       /// 不读取Gecko下载数据
@property(nonatomic, strong) NSNumber *disableBuildin;    /// 不读取内置数据
@property(nonatomic, strong) NSNumber *disableGurdUpdate; /// 强制不触发gecko更新（dynamic参数失效）

/// 设置自定义资源加载器
@property(nonatomic, strong, nullable) BDXResourceLoaderProcessorConfig *processorConfig;

/// cdn下载相关
@property(nonatomic, copy) NSString *cdnUrl;                     /// 如果配置此项，则在走到cdn加载器时，强制使用此url进行下载。
@property(nonatomic, strong) NSNumber *addTimeStampInTTIdentity; /// 在TTNetwork请求identity上添加timeStamp
@property(nonatomic, assign) NSInteger loadRetryTimes;
@property(nonatomic, weak) BDXContext *context; ///  当前BDX上下文

/// 扩展参数
@property(nonatomic, strong) NSNumber *syncTask; /// onlyLocal下，可以设置同步返回
@property(nonatomic, strong) NSNumber *runTaskInGlobalQueue; ///  将本次fetch任务放到GlobalQueue中执行
@property(nonatomic, strong) NSNumber *onlyPath; ///  只查找本地路径，不去读data


@end

#pragma mark-- BDXResourceLoaderTaskProtocol

@protocol BDXResourceLoaderTaskProtocol <NSObject>

@property(nonatomic, copy) NSString *url;

- (BOOL)cancelTask;

@end

#pragma mark-- BDXAdvancedOperatorProtocol

@protocol BDXResourceLoaderAdvancedOperatorProtocol <NSObject>

- (NSString *)getDefaultAccessKey;

/// 注册accessKey
- (void)registeDefaultAccessKey:(NSString *)accessKey;
/// 注册accessKey， 并设置此Key对应的匹配前缀
- (void)registeAccessKey:(NSString *__nonnull)accessKey withPrefixList:(NSArray *)prefixList;
/// 注册accessKey， 并追加此Key对应的匹配前缀
- (void)registeAccessKey:(NSString *__nonnull)accessKey appendPrefixList:(NSArray *)prefixList;
/// 追加此accessKey对应的匹配前缀
- (void)appendPrefixList:(NSArray *)prefixList withAccessKey:(NSString *__nonnull)accessKey;

- (void)syncChannelIfNeeded:(NSString *)channel accessKey:(NSString *)accessKey completion:(BDXGeckoCompletionHandler __nullable)completion;

@end

NS_ASSUME_NONNULL_END

#endif /* BDXResourceLoaderProtocol_h */

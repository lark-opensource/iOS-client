//
//  AWECloudCommandManager.h
//  Aweme
//
//  Created by willorfang on 2017/1/15.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWECloudCommandMacros.h"
#import "AWECloudCommandNetworkHandler.h"

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^ForbidCloudCommandUpload)(AWECloudCommandModel * model);

typedef AWECloudCommandModel *_Nullable (^AWECloudCommandCustomBlock)(AWECloudCommandModel * model);

@interface AWECustomCommandResult : NSObject

/// 上传文件数据
@property (nonatomic, strong, nullable) NSData *data;
/// 文件类型，用于可视化配置，目前支持json, log, xml, text, 默认为unknown
@property (nonatomic, copy, nullable) NSString *fileType;
/// 错误内容
@property (nonatomic, strong, nullable) NSError *error;
/// 文件状态，有error时默认失败，其他情况默认成功
@property (nonatomic, assign) AWECloudCommandStatus status;
/// 命令生效时间，默认为开始执行命令的时间
@property (nonatomic, assign) long long operateTimestamp;

@end


typedef void(^AWECustomCommandCompletion)(AWECustomCommandResult *result);

@protocol AWECustomCommandHandler <NSObject>
@required
/// 自定义命令标识
+ (NSString *)cloudCommandIdentifier;
/// 创建用于执行指令的实例变量
+ (instancetype)createInstance;
/// 执行自定义命令
- (void)excuteCommandWithParams:(NSDictionary *)params
                    completion:(AWECustomCommandCompletion)completion;
@optional
/// 上传结果到服务器成功
- (void)uploadCommandResultSuccessedWithParams:(NSDictionary *)params;
/// 上传结果到服务器失败
- (void)uploadCommandResultFailedWithParams:(NSDictionary *)params error:(NSError *)error;
@end


@interface AWECloudCommandParamModel : NSObject

@property (nonatomic, copy, nonnull) NSString *appID;
@property (nonatomic, copy, nonnull) NSString *deviceId;
@property (nonatomic, copy, nullable) NSString *userId;
@property (nonatomic, copy, nullable) NSString *appBuildVersion;

@end


@interface AWECloudCommandManager : NSObject

/**
 [Required]
 必传的参数
 */
@property (nonatomic, copy, nullable) AWECloudCommandParamModel *(^cloudCommandParamModelBlock)(void);
@property (nonatomic, strong, readonly) AWECloudCommandParamModel *cloudCommandParamModel;

/**
 [Optional]
 网络请求的公共参数
 */
@property (nonatomic, copy, nonnull) NSDictionary *(^commonParamsBlock)(void);
@property (nonatomic, copy, readonly) NSDictionary *commonParams;

/**
 [Optional]
 网络请求代理
 */
@property (nonatomic, strong, nullable) id<AWECloudCommandNetworkDelegate> networkDelegate;

/**
 [Optional]
 所有请求接口的host地址，默认为 mon.zijieapi.com
 */
@property (nonatomic, copy, nullable) NSString *host;

/**
 [Optional]
 These file paths are not allowed to upload
 */
@property (nonatomic, copy, nullable) NSArray<NSString *> *blockList;

/// 自定义的云控指令
@property (nonatomic, copy, readonly) NSArray<Class<AWECustomCommandHandler>> *customCommandHandlerClsArray;

/**
 [Optional]
 设置回调，业务方可以通过回调控制回捞是否执行
 */
@property (nonatomic, copy, nullable) ForbidCloudCommandUpload forbidCloudCommandUpload;

/**
 [Optional]
 磁盘回捞中，path脱敏处理器
 */
@property (nonatomic, copy, nullable) AWECloudCommandCustomBlock diskPathsComplianceHandler;


/**
 [Optional]
 添加业务方自定义的云控指令实现的类
 */
- (void)addCustomCommandHandlerCls:(Class<AWECustomCommandHandler>)handlerCls;
/**
 [Optional]
 批量添加业务方自定义的云控指令实现的类
 */
- (void)addCustomCommandHandlerClsArray:(NSArray<Class<AWECustomCommandHandler>> *)handlerClsArray;

/// 得到云控单例
+ (instancetype)sharedInstance;

/// 拉取云控指令
- (void)getCloudControlCommandData;

/// 执行云控指令，一般用于长链接payload
//This method has been deprecated
- (void)executeCommandWithData:(NSData *)data;

//ran is the key for aes
- (void)executeCommandWithData:(NSData *)data ran:(NSString *)ran;

NS_ASSUME_NONNULL_END

@end



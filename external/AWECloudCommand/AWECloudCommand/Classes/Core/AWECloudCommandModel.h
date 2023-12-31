//
//  AWECloudCommandModel.h
//  Pods
//
//  Created by willorfang on 2017/1/23.
//
//

#import <Foundation/Foundation.h>
#import "AWECloudCommandMultiData.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AWECloudCommandStatus)
{
    AWECloudCommandStatusNever = 0,             // 未上传过
    AWECloudCommandStatusInProgress = 1,        // 上传中
    AWECloudCommandStatusSucceed = 2,           // 上传成功
    AWECloudCommandStatusFail = 3,              // 失败
};

/////////////////////////////////////////////////////////////////////

@interface AWECloudCommandModel : NSObject

@property (nonatomic, strong) NSNumber *commandId;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSDictionary *params;

- (instancetype)initWithDict:(NSDictionary *)dict;

- (void)configFileBlockList:(NSArray<NSString *> *)blockList;

- (NSArray<NSString *> *)allowedFilePathsAfterChecking:(NSString *)path;

@end

/////////////////////////////////////////////////////////////////////

@interface AWECloudCommandResult : NSObject

@property (nonatomic, strong) NSNumber *commandId;
@property (nonatomic, assign) AWECloudCommandStatus status;
@property (nonatomic, copy, nullable) NSString *errorMessage;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, copy) NSString *mimeType;  // Deprecated, 迁移到slardar平台后，该字段已废弃
@property (nonatomic, copy) NSString *fileType;  // 目前支持json, log, xml, text
@property (nonatomic, assign) long long operateTimestamp;   // 命令生效时间戳

@property (nonatomic, assign) BOOL isMultiData;
@property (nonatomic, copy) NSArray<AWECloudCommandMultiData *> *multiDataArray;
@property (nonatomic, strong) NSDictionary *additionalUploadParams; // 上传时的额外参数

@property (nonatomic, copy, nullable) dispatch_block_t uploadSuccessedBlock;
@property (nonatomic, copy, nullable) void(^uploadFailedBlock)(NSError *error);

@end

typedef void(^AWECloudCommandResultCompletion)(AWECloudCommandResult *result);

@protocol AWECloudCommandProtocol <NSObject>
@required
/// 创建用于执行指令的实例变量
+ (instancetype)createInstance;

/// 执行命令
- (void)excuteCommand:(AWECloudCommandModel *)model
           completion:(AWECloudCommandResultCompletion)completion;

@end

/////////////////////////////////////////////////////////////////////

FOUNDATION_EXPORT void AWECloudCommandRegisterCommand(NSString *type, Class<AWECloudCommandProtocol> commandClass);
FOUNDATION_EXPORT Class<AWECloudCommandProtocol> AWECloudCommandForType(NSString *type);

NS_ASSUME_NONNULL_END


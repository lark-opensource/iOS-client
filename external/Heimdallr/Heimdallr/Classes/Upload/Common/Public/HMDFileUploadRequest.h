//
//  HMDFileUploadRequest.h
//  Heimdallr-iOS13.0
//
//  Created by fengyadong on 2020/2/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^HMDFileUploaderBlock)(BOOL success, id _Nullable jsonObject);

/// 请求 - 文件上传
@interface HMDFileUploadRequest : NSObject

/// [必填] 待上报的文件路径
@property (nonatomic, copy, nullable) NSString *filePath;

/// [必填] 文件类型，请不要起的太通用，容易冲突
@property (nonatomic, copy, nullable) NSString *logType;

/// [必填] 文件上报时的场景，如崩溃或用户主动反馈
@property (nonatomic, copy, nullable) NSString *scene;

/// [必填] 是否由用户触发，默认:NO
@property (nonatomic, assign) BOOL byUser;

/// [选填] 除文件之外的其他自定义参数
@property (nonatomic, copy, nullable) NSDictionary *commonParams;

/// [选填] 上报接口的path，默认/monitor/collect/c/logcollect
@property (nonatomic, copy, null_resettable) NSString *path;

/// [选填] 完成回调
@property (nonatomic, copy, nullable) HMDFileUploaderBlock finishBlock;

@end

NS_ASSUME_NONNULL_END

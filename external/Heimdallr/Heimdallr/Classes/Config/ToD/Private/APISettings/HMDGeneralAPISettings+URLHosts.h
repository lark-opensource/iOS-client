//
//  HMDGeneralAPISettings+URLHosts.h
//  HeimdallrFinder
//
//  Created by Nickyo on 2023/8/21.
//

#import "HMDGeneralAPISettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDGeneralAPISettings (URLHosts)

/// 获取配置 Hosts
@property (nonatomic, copy, readonly) NSArray<NSString *> * _Nullable configFetchHosts;

/// 崩溃上传 Hosts
@property (nonatomic, copy, readonly) NSArray<NSString *> * _Nullable crashUploadHosts;

/// 异常上传 Hosts
@property (nonatomic, copy, readonly) NSArray<NSString *> * _Nullable exceptionUploadHosts;

/// 用户异常上传 Hosts
@property (nonatomic, copy, readonly) NSArray<NSString *> * _Nullable userExceptionUploadHosts;

/// 性能上传 Hosts
@property (nonatomic, copy, readonly) NSArray<NSString *> * _Nullable performanceUploadHosts;

/// 文件上传 Hosts
@property (nonatomic, copy, readonly) NSArray<NSString *> * _Nullable fileUploadHosts;

@end

NS_ASSUME_NONNULL_END

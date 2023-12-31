//
//  BDXRLTaskConfig.h
//  BDXResourceLoader
//
//  Created by David on 2021/3/19.
//

#import <BDXServiceCenter/BDXService.h>
#import "BDXRLOperator.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark-- BDXResourceLoaderUrlParamConfig

@interface BDXRLUrlParamConfig : NSObject

/// 可访问当前对应的配置
@property(nonatomic, strong) BDXResourceLoaderConfig *loaderConfig;
@property(nonatomic, strong) BDXResourceLoaderTaskConfig *taskConfig;

- (instancetype)initWithUrl:(NSString *)url loaderConfig:(BDXResourceLoaderConfig *)loaderConfig taskConfig:(BDXResourceLoaderTaskConfig *)taskConfig advOperator:(BDXRLOperator *)advancedOperator;

- (NSString *)url;
- (NSString *)sourceURL;
- (NSString *)cdnURL;
- (NSString *)accessKey;
- (NSString *)channelName;
- (NSString *)bundleName;
- (NSInteger)dynamic;
- (BOOL)onlyLocal;
- (BOOL)addTimeStampInTTIdentity;
- (BOOL)disableGurdUpdate;
- (BOOL)disableGecko;
- (BOOL)disableBuildin;
- (BOOL)disableCDN;
- (BOOL)isSchema;
- (BOOL)syncTask;
- (BOOL)onlyPath;
- (BOOL)runTaskInGlobalQueue;

@end

NS_ASSUME_NONNULL_END

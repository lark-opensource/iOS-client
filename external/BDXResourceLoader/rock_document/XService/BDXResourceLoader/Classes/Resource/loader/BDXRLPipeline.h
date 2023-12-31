//
//  BDXResourceLoaderPipeline.h
//  BDXResourceLoader
//
//  Created by David on 2021/3/14.
//

#import "BDXRLProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXRLPipeline : NSObject

/// 内部使用的融合配置
@property(nonatomic, strong) BDXRLUrlParamConfig *paramConfig;

/// @abstract 创建一个新的加载流程.
/// @param processorArray
/// 传入各个加载器，会按顺序执行，调用第一个执行成功的加载器回调。
/// @param url  资源url。
/// @param loaderConfig  加载配置
/// @param taskConfig  任务配置
- (instancetype)initWithProcessors:(NSArray<id<BDXResourceLoaderProcessorProtocol>> *)processorArray url:(NSString *)url loaderConfig:(BDXResourceLoaderConfig *__nullable)loaderConfig taskConfig:(BDXResourceLoaderTaskConfig *__nullable)taskConfig;

/// @abstract
/// 取消下载，调用当前正在执行的Processor的cancel方法，并取消后续过程。
- (BOOL)cancelLoad;

/// @abstract 开始获取资源.
/// @param container  当前所在容器，可以为空
/// @param resolveHandler  获取成功
/// @param rejectHandler  获取失败
- (void)fetchResourceWithContainer:(UIView *__nullable)container resolve:(BDXResourceLoaderResolveHandler)resolveHandler reject:(BDXResourceLoaderRejectHandler)rejectHandler;

@end

NS_ASSUME_NONNULL_END

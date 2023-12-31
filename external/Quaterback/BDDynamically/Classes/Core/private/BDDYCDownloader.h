//
//  BDDYCDownloader.h
//  BDDynamically
//
//  Created by zuopengliu on 13/3/2018.
//

#import <Foundation/Foundation.h>
#import "BDDYCSessionTask.h"
#import "BDDYCModuleRequest.h"
#import "BDDYCModuleModel.h"

NS_ASSUME_NONNULL_BEGIN

#if BDAweme
__attribute__((objc_runtime_name("AWECFRhubarb")))
#elif BDNews
__attribute__((objc_runtime_name("TTDToadstool")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDEmu")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDWaterShield")))
#endif
@interface BDDYCDownloader : NSObject

// Step1 + Step2
+ (id<BDDYCSessionTask>)fetchModulesWithRequest:(BDDYCModuleRequest *)aModuleReq
                                    toDirecotry:(NSString *)fileDir
                                       progress:(void (^)(id _Nullable aDYCModule, NSInteger modelIdx, NSError * _Nullable error))progressHandler
                                     completion:(void (^)(NSArray * _Nullable modules, NSError * _Nullable error))completionHandler;

// Step1
/**
 拉取后端所有模块信息
 
 @param aModuleReq          请求
 @param completionHandler   完成回调
 @return 当前请求任务
 */
+ (BDDYCModuleListSessionTask *)fetchModelListWithRequest:(BDDYCModuleRequest *)aModuleReq
                                               completion:(void (^)(NSArray * _Nullable aModuleList /*BDDYCModuleModel*/,
                                                                    NSError * _Nullable error))completionHandler;

// Step2
/**
 下载指定模块至指定目录
 
 @param aModel              模块信息
 @param fileDir             解压文件目录
 @param unzipClass          解压类对象
 @param completionHandler   完成回调
 @return 当前请求任务
 */
+ (BDDYCModuleSessionTask *)fetchModule:(id)aModel
                            toDirecotry:(NSString *)fileDir
                            requestType:(kBDDYCModuleRequestType)requestType
                             completion:(void (^)(id _Nullable aDYCModule, NSError * _Nullable error))completionHandler;


#pragma mark - for test

/**
 解压zip文件到指定目录
 
 @param zipPath     zip文件路径
 @param fileDir     指定目录
 @param completionHandler 完成回调
 */
+ (void)unzipZipFile:(NSString *)zipPath
         toDirecotry:(NSString *)fileDir
          completion:(void (^)(id _Nullable aDYCModule, NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END

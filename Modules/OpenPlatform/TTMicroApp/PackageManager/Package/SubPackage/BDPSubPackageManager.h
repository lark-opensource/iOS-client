//
//  BDPSubPackageManager.h
//  TTMicroApp
//
//  Created by Nicholas Tau on 2021/8/25.
//

#import <Foundation/Foundation.h>
#import "BDPPackageContext.h"
#import <OPFoundation/BDPPkgFileReadHandleProtocol.h>
#import "BDPPackageModuleProtocol.h"
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPCommon.h>

NS_ASSUME_NONNULL_BEGIN
//分包管理器中加载页面JS的阶段
typedef NS_ENUM(NSUInteger, BDPSubPackageExtraJSLoadStep) {
    BDPSubPackageLoadAppPrepare = 0,         //准备加载业务JS
    BDPSubPackageLoadAppServiceBegin = 1,         //加载分包的app-service.js
    BDPSubPackageLoadAppServiceEnd = 2,         //加载分包的app-service.js
    BDPSubPackageLoadPageFrameBegin = 3,          //加载分包的page-frame.js
    BDPSubPackageLoadPageFrameEnd = 4         //加载分包的page-frame.js
};
/// 分包执行页面JS的回调
typedef void(^BDPSubPackageJSExcutedCallback)(BDPSubPackageExtraJSLoadStep loadStep, NSError * _Nullable error);

@interface BDPSubPackageManager : NSObject
+ (instancetype)sharedManager;
-(void)cleanFileReadersWithUniqueId:(BDPUniqueID *)uniqueID;
///切换租户时清理所有的 readers
-(void)cleanAllReaders;
/// 根据context 中关联的信息，绑定fileReader（统一管理分包小程序中多个包的Reader）
/// @param fileReader 文件句柄
/// @param context 包上下文
-(void)updateFileReader:(id<BDPPkgFileReadHandleProtocol> _Nullable) fileReader withPackageContext:(BDPPackageContext *)context;
/// 通过context 上下文获取文件的fileReader
/// @param context 包上下文
-(id<BDPPkgFileReadHandleProtocol> _Nullable)getFileReaderWithPackageContext:(BDPPackageContext *)context;
/// 通过packageName 获取文件的fileReader
/// @param packageName 包名
-(id<BDPPkgFileReadHandleProtocol> _Nullable)getFileReaderWithPackageName:(NSString *)packageName;
/// 通过当前资源的相对路径来获取fileReader文件句柄
/// @param pagePath 资源相对路径
-(id<BDPPkgFileReadHandleProtocol> _Nullable)getFileReaderWithPagePath:(NSString * _Nullable) pagePath uniqueID:(BDPUniqueID *)uniqueID;
/// 是否开启分包模式
-(BOOL)enableSubPackageWithUniqueId:(BDPUniqueID *)uniqueId;
//通过页面路径获取真实的包名
-(BDPPackageContext *)packageContextWithPath:(NSString*)path uniqueID:(BDPUniqueID *)uniqueID;
/// 开始准备分包
/// @param context 分包上下文
/// @param priority 优先级
/// @param begunBlock 下包开始的回调，只回调一次[subPackages 中第一个包开始]
/// @param progressBlock 只反应[subPackages 中第一个包开始的进度]
/// @param completedBlock 下包完成的回调，只回调一次 只回调一次[subPackages 中第一个包下载完成]
- (void)prepareSubPackagesWithContext:(BDPPackageContext *)context
                             priority:(float)priority
                                begun:(BDPPackageDownloaderBegunBlock)begunBlock
                             progress:(BDPPackageDownloaderProgressBlock)progressBlock
                            completed:(BDPPackageDownloaderCompletedBlock)completedBlock;
/// 打开小程序后，独立页面加载分包
/// @param pagePath 当前独立页面的路径
/// @param uniqueID 要启动分包的appID
/// @param isWorker 是否在worker中执行的（如app-service.js）
-(void)prepareSubPackagesForPage:(NSString *)pagePath
                    withUniqueID:(BDPUniqueID *)uniqueID
                        isWorker:(BOOL)isWorker
jsExecuteCallback:(BDPSubPackageJSExcutedCallback)callback;

/// 执行分包页面的 page-frame.js
/// @param fileReader 分包的资源句柄
/// @param pagePath 分包资源主路径
/// @param sepcificPath 页面详情路径
/// @param callback 完成回调
-(void)executeExtraPageFrameJSWith:(BDPPkgFileReader _Nullable)fileReader
                        targetPath:(NSString *)pagePath
                      sepcificPage:(NSString *)sepcificPath
jsExecuteCallback:(BDPSubPackageJSExcutedCallback)callback;


/// 预加载分包(异步)
/// @param pagePath 当前页面路径
/// @param uniqueID 小程序ID
- (void)preloadWithRulesInPagePath:(NSString *)pagePath
                      withUniqueID:(BDPUniqueID *)uniqueID;
@end

@protocol BDPSubPackageManagerEnableProtocol <NSObject>
-(BOOL)isSubpackageEnable;
@end

@interface BDPCommon  (BDPSubPackageManager)<BDPSubPackageManagerEnableProtocol>
@end

@interface BDPPackageContext (BDPSubPackageManager) <BDPSubPackageManagerEnableProtocol>
@end

NS_ASSUME_NONNULL_END

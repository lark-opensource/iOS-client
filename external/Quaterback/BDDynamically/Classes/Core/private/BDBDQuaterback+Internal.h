//
//  BDDYCMain+Internal.h
//  BDDynamically
//
//  Created by zuopengliu on 7/1/2018.
//

#import <Foundation/Foundation.h>
#import "BDBDQuaterback.h"
#import "BDDYCModule+Internal.h"
#import "BDDYCSessionTask.h"
#import "BDDYCUpdateStrategy.h"



NS_ASSUME_NONNULL_BEGIN


#pragma mark -

@interface BDBDQuaterback ()
@property (nonatomic, strong, readwrite) id<BDQBDelegate> delegate;
@property (nonatomic, strong, readwrite) BDQBConfiguration *conf;
@property (nonatomic, strong, readwrite) BDDYCUpdateStrategy *refreshStrategy;


/**
 第一次启动引擎 `engineType`，并加载本地资源
 
 @param engineType 引擎类型
 */
- (void)startEngine:(NSInteger)engineType;

/**
 仅仅启动Brady引擎，不加载本地资源
 */
- (BOOL)runBrady;

/**
 关闭Brady引擎
 */
- (void)closeBrady;

/**
 加载 BDDYCModule 数据

 @param aDYCModule DYCModule 数据
 @param bd_willTransitionToTraitCollection 加载错误回调
 */
- (void)loadDYCModule:(BDBDModule *)aDYCModule
           errorBlock:(void (^_Nullable)(NSError *error))errorBlock;

//loadLazyLoadDylibAndReturnError

- (void)loadDYCLazyDylibModule:(BDBDModule *)aDYCModule
           errorBlock:(void (^_Nullable)(NSError *error))errorBlock;

/**
 是否正在使用Brady

 @return 使用Brady，返回YES；否则返回NO
 */
- (BOOL)isBradyRunning;

/**
 强制拉取服务端数据
 */
+ (void)fetchServerData;

/**
 获取已被加载的patch信息
 */
- (NSArray *)allLoadedQuaterbacks;
@end

#pragma mark -

@interface BDBDQuaterback (ModuleDataFetching)

/**
 拉取后端所有模块列表信息并下载模块数据
 
 @param completionHandler 拉取完成回调
 */
+ (id<BDDYCSessionTask>)fetchModuleDataWithCompletion:(void (^_Nullable)(NSArray *modules, NSError *error))completionHandler;

@end

@interface BDBDQuaterback (Scheme)
/**
 判断并处理通过 ·URL· 访问 ·BDDYCEngine· 的业务

 @param url url对象
 @return 能处理返回YES，否则返回NO
 */
+ (BOOL)handleOpenURL:(NSURL *)url;

/**
 通过各种方式启动 Brady
 */
+ (void)startBrady;

/**
 通过各种方式关闭 Brady
 */
+ (void)closeBrady;

@end

#pragma mark -

// 本地调试
@interface BDBDQuaterback (DEBUG_HELP)
+ (void)loadFileAtPath:(NSString *)filePath;
+ (void)loadZipFileAtPath:(NSString *)filePath;
@end


NS_ASSUME_NONNULL_END

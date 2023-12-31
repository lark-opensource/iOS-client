//
//  BDDYCMain.h
//  BDDynamically
//
//  Created by zuopengliu on 7/1/2018.
//

#import <Foundation/Foundation.h>
#import "BDBDConfiguration.h"
#import "BDQBDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDBDMain : NSObject
@property (nonatomic, strong, readonly) BDBDConfiguration *conf;

/**
 单例
 */
+ (instancetype)sharedMain;

/**
 运行主程序
 
 @param conf     配置
 @param delegate 回调代理，被strong持有
 */
+ (void)startWithConfiguration:(BDBDConfiguration *)conf
                      delegate:(id<BDQBDelegate> _Nullable)delegate;

/**
 主动拉取patch list
 */
+ (void)fetchBandages;

/**
 清理本地补丁包
 */
+ (void)clearAllLocalBandage;


/// 测试本地补丁
/// @param path 本地补丁路径，必须是.bc文件
+ (void)loadModuleAtPath:(NSString *)path;

+ (void *)lookupFunctionByName:(NSString *)functionName
                 inModuleNamed:(NSString *)moduleName
                 moduleVersion:(int)moduleVersion;

@end


NS_ASSUME_NONNULL_END

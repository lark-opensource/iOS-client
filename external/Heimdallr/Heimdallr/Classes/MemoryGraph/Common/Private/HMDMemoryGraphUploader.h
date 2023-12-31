//
//  HMDMemoryGraphUploader.h
//  Heimdallr-iOS13.0
//
//  Created by fengyadong on 2020/3/2.
//

#import <Foundation/Foundation.h>
#import "HMDMemoryGraphTool.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDMemoryGraphUploader : NSObject


/// 异步检查并上报缓存的MemoryGraph文件
- (void)asyncCheckAndUpload;

/// 上报制定的memory graph文件
/// @param identifier 标志，格式是sessionid_次数
/// @param activateManner 触发方式，如线上，手动触发，云控等
/// @param checkServer 上传时是否需要checkserver逻辑
/// @param finishBlock 完成回调
- (void)uploadIdentifier:(NSString *)identifier
          activateManner:(NSString *)activateManner
         needCheckServer:(BOOL)checkServer
             finishBlock:(HMDMemoryGraphFinishBlock)finishBlock;

/// 待处理的文件目录
+ (NSString *)memoryGraphProcessingPath;

/// 已经处理好待上传的目录
+ (NSString *)memoryGraphPreparedPath;

/// 检测env参数
+ (NSDictionary*)checkEnvParamsWithIdentifier:(NSString*)indentifier;

/// 清理zip文件和env文件
/// @param identifier 标志，格式是sessionid_次数
+ (void)cleanupIdentifier:(NSString *)identifier;

- (BOOL)safeCreateZipFileAtPath:(NSString *)path
        withContentsOfDirectory:(NSString *)directory;

@end

NS_ASSUME_NONNULL_END

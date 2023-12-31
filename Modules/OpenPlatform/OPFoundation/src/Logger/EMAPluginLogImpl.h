//
//  EMAPluginLogImpl.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/2/25.
//

#import <Foundation/Foundation.h>
#import <ECOInfra/BDPLog.h>

NS_ASSUME_NONNULL_BEGIN

@interface EMAPluginLogImpl : NSObject

/**
 设定Log实现
 
 @param level BDPLogLevel Debug = 1, Info = 2,Warn = 3, Error = 4, Fatal = 5
 @param tag tag
 @param tracing tracing
 @param fileName from '__FILE__' macro
 @param funcName from '__FUNCTION__' macor
 @param line from '__LINE__' macro
 @param content log content
 */
+ (void)bdp_LogWithLevel:(BDPLogLevel)level tag:(NSString * _Nullable)tag tracing:(NSString * _Nullable)tracing fileName:(NSString * _Nullable)fileName funcName:(NSString * _Nullable)funcName line:(int)line  content:(NSString * _Nullable)content;

@end

NS_ASSUME_NONNULL_END

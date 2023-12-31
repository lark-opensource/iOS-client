//
//  EMADebugUtil+Business.h
//  EEMicroAppSDK
//
//  Created by justin on 2022/12/29.
//

#import <OPFoundation/EMADebugUtil.h>

NS_ASSUME_NONNULL_BEGIN

@interface EMADebugUtil (Business)

- (void)clearMicroAppProcesses; // 清理所有小程序进程
- (void)clearMicroAppFileCache; // 清理所有小程序文件缓存
//清理H5应用文件信息
- (void)clearH5AppFolders;
/// 清理所有小程序文件夹
- (void)clearMicroAppFolders;
- (void)clearJSSDKFileCache;    // 清理JSSDK文件缓存
- (void)checkJSSDKDebugConfig;  // 检查JSSDK配置变更
- (void)checkBlockJSSDKDebugConfig:(BOOL)needExit; // 检查block js sdk配置变更
- (void)clearMicroAppPermission;// 清理权限
/// 清理cookies
- (void)clearAppAllCookies;
- (void)checkAndSetDebuggerConnection;  //检查设置log连接

-(void)reloadCurrentGadgetPage;
-(void)triggerMemorywarning;

@end

NS_ASSUME_NONNULL_END

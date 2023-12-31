//
//  BDPURLProtocolManager.h
//  Timor
//
//  Created by CsoWhy on 2018/8/15.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPUniqueID.h>

@class BDPAppLoadURLInfo, WKWebView;

#define BDP_REFERER_FIELD @"Referer"
#define BDP_JSSDK_SCHEME @"ttjssdk"
#define BDP_JSSDK_MASK @"from=ttjssdk"

NS_ASSUME_NONNULL_BEGIN

/// 拦截小程序/H5小程序的WKWebView内发起的网络请求，包括代码包/temp/user/js sdk/webp图片等类型的请求
@interface BDPURLProtocolManager : NSObject

/// 建议调用`setInterceptionEnable:withWKWebview:`
@property (nonatomic, assign) BOOL requestInterruptionEnabled;


/// 关闭BDPURLProtocol 中的日志
@property (nonatomic, assign) BOOL disableProtocolLog;

+ (instancetype)sharedManager;

/// 用于退出登录时，清理跟小程序文件目录相关的单例对象，便于再次登录时重新初始化
+ (void)clearSharedInstance;

/**
 临时方法，在刚进入小程序的时候调用次方法，去掉掉WK的schema注册。
 最终方案，需要等亮哥那边给一个js脚本配合
 */
+ (void)unregisterWKSchemas;

+ (NSString *)serviceReferer:(BDPUniqueID *)uniqueID version:(NSString *)version;

#pragma mark - 小程序小游戏资源拦截相关
- (nullable BDPAppLoadURLInfo *)infoOfRequest:(NSURLRequest *)request;
/** 产生一个虚拟目录路径, 默认在jssdk下 */
- (NSString *)generateVirtualFolderPath;
/** 添加JSSDK目录的标记 */
- (NSString *)addJSSDKFolderMaskForPath:(NSString *)path;
/** 路径是否位于虚拟目录下 */
- (BOOL)isInVirtualFolderOfPath:(NSString *)path;
- (void)registerFolderPath:(NSString *)path forUniqueID:(BDPUniqueID *)uniqueID pkgName:(NSString *)pkgName;
- (void)unregisterFolderPath:(NSString *)path;

/** 设置拦截开关, 推荐传入拦截实例, 耗时更低 */
- (void)setInterceptionEnable:(BOOL)enable withWKWebview:(nullable WKWebView *)webview;

@end

NS_ASSUME_NONNULL_END

//
//  BDWebViewResourceManager.h
//  BDWebKit
//
//  Created by wealong on 2019/12/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDWebViewResourceManager : NSObject

@property (nonatomic, strong, readonly) NSString *geckoAccessKey;

@property (nonatomic) BOOL isInHouse;

+ (instancetype)sharedInstance;

/**
 * 开启离线化之后的 http 相关 post 请求会丢失 body，这个脚本用来拦截离线化过程中的 post 请求代理到本地
 */
- (NSString *)fetchAjaxHookJS;

/**
 * 白屏脚本检测
 */
- (NSString *)fetchDetectBlankContentJS;

/**
 * console log 拦截，用 confirm 转发
 */
- (NSString *)fetchHookConsoleLogToConfirm;

/**
 * vConsole 脚本，InHouse 下有效
 */
- (NSString *)vConsoleJS;

/**
 * 将页面中的 video 控件转成 native-video 脚本
 */
- (NSString *)nativeVideoHookJS;

@end

NS_ASSUME_NONNULL_END

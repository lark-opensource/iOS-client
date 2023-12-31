//
//  HMDLogHelper.h
//  Heimdallr
//
//  Created by kilroy on 2020/12/6.
//

#import <Foundation/Foundation.h>

typedef void (^ _Nullable HMDLogRedirectCallback)(NSString* _Nullable content);

@interface HMDLogHelper : NSObject

+ (instancetype _Nullable) sharedInstance;

/** 基于管道重定向NSLog至Alog, 对应stderr */
- (void)setRedirectNSLogToAlogEnable:(BOOL)enable;

/** 基于管道重定向printf至Alog, 对应stdout */
- (void)setRedirectPrintfToAlogEnable:(BOOL)enable;

/** 基于管道重定向NSLog至Alog, 对应stderr 返回重定向日志内容
 * @param enable 开/关重定向功能
 * @param callback 返回日志内容信息
 * ⚠️ 注意：callback不要做任何和输出(NSLog等等)相关的操作，会死循环
 */
- (void)setRedirectNSLogToAlogEnable:(BOOL)enable withCallback:(nullable HMDLogRedirectCallback)callback;

/** 基于管道重定向printf至Alog, 对应stdout, 返回重定向日志内容
 * @param enable 开/关重定向功能
 * @param callback 返回日志内容信息
 * ⚠️ 注意：callback不要做任何和输出(NSLog等等)相关的操作，会死循环
 */
- (void)setRedirectPrintfToAlogEnable:(BOOL)enable withCallback:(nullable HMDLogRedirectCallback)callback;

@end

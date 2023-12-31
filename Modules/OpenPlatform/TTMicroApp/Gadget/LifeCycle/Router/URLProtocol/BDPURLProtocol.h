//
//  BDPURLProtocol.h
//  Timor
//
//  Created by CsoWhy on 2018/8/17.
//

#import <Foundation/Foundation.h>

@interface BDPURLProtocol : NSURLProtocol

/// 用于退出登录时，清理跟小程序文件目录相关的单例对象，便于再次登录时重新初始化
+ (void)resetInfoCache;

@end

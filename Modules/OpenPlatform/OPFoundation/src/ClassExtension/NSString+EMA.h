//
//  NSString+EMA.h
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/19.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSString (EMAAddition)

/**
 为url字符串添加子路径

 @param path 子路径
 @return url字符串
 */
- (NSString *)ema_urlStringByAppendingPathComponent:(NSString *)path;

- (NSString *)ema_base64Decode;
- (NSString *)ema_md5;
- (NSString *)ema_sha256EncodeWithSalt:(NSString *)salt;
- (NSString *)ema_sha1;

/// 更安全的 hasPrefix 函数（原 hasPrefix 函数 str = nil 会 crash）
- (BOOL)ema_hasPrefix:(NSString * _Nullable)str;

@end

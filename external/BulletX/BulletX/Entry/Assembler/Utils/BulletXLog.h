//
//  BulletXLog.h
//  Bullet-Pods-AwemeLite
//
//  Created by 王丹阳 on 2020/12/28.
//

#import <BDAlogProtocol/BDAlogProtocol.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define BulletXLog(format, ...) BDALOG_PROTOCOL_INFO(format, ##__VA_ARGS__);
#define BulletXError(format, ...) BDALOG_PROTOCOL_ERROR(format, ##__VA_ARGS__);
#define BulletXLog_TAG(tag, format, ...) BDALOG_PROTOCOL_INFO_TAG(tag, format, ##__VA_ARGS__);
#define BulletXError_TAG(tag, format, ...) BDALOG_PROTOCOL_ERROR_TAG(tag, format, ##__VA_ARGS__);

NS_ASSUME_NONNULL_END

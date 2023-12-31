//
//  NSObject+DartCodec.h
//  FlutterChannelTool
//
//  Created by zhangtianfu on 2019/1/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 *  安全访问dart传递的消息类型
 *
 *  参考官方文档《StandardMessageCodec class》https://docs.flutter.io/flutter/services/StandardMessageCodec-class.html
 */
@interface NSObject (DartCodec)

- (NSString *)dart_string;

- (NSDictionary *)dart_dictionary;

- (NSArray *)dart_array;

- (NSNumber *)dart_number;

- (id)dart_FlutterStandardTypedData;

@end

NS_ASSUME_NONNULL_END

//
//  BridgeResultProtocol.h
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/7.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

//Bridge调用返回状态码(可扩展)
typedef NS_ENUM(NSInteger, FLTBResponseCode) {
  FLTBResponseNotFound    = -2,   //接口不存在
  FLTBResponseNoPrivilege = -1,   //接口无权限
  FLTBResponseError       = 0,    //调用失败
  FLTBResponseSuccess     = 1,    //调用成功
};

NS_ASSUME_NONNULL_BEGIN

@protocol FLTBResponseProtocol <NSObject>

- (NSInteger)code;

- (NSString *)message;

- (nullable id)data;

@end

NS_ASSUME_NONNULL_END

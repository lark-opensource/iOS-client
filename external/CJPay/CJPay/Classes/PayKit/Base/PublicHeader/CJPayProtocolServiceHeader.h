//
//  CJPayProtocolServiceHeader.h
//  Pods
//
//  Created by 王新华 on 2020/11/8.
//

#import <Foundation/Foundation.h>
#import "CJPaySDKDefine.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayWakeBySchemeProtocol <NSObject>

// 支持路由打开特定页面，如果不能处理，返回NO，能够处理返回yes, 可选实现
- (BOOL)openPath:(NSString *)path withParams:(NSDictionary *)params;

@end

@protocol CJPayWakeByUniversalPayDeskProtocol <NSObject>

// 通过UniversalBridge打开  返回NO表示打开失败
- (BOOL)wakeByUniversalPayDesk:(NSDictionary *)dictionary withDelegate:(nullable id<CJPayAPIDelegate>) delegate;

@end


NS_ASSUME_NONNULL_END

//
//  BDNativeWebBaseComponent.h
//  ByteWebView
//
//  Created by liuyunxuan on 2019/6/12.
//

#import <Foundation/Foundation.h>
#import "BDNativeWebContainerObject.h"


typedef void(^BDNativeDispatchActionCallback)(NSDictionary *callbackData);

@class WKWebView;

@interface BDNativeWebBaseComponent : NSObject

+ (NSString *)nativeTagName;
+ (NSNumber *)nativeTagVersion;

- (UIView *)insertInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params;

- (void)updateInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params;

- (void)deleteInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params;

- (void)actionInNativeContainerObject:(BDNativeWebContainerObject *)containerObject
                               method:(NSString *)method
                               params:(NSDictionary *)params
                             callback:(BDNativeDispatchActionCallback)callback;

- (void)fireComponentAction:(NSString *)action params:(NSDictionary *)params;

@end

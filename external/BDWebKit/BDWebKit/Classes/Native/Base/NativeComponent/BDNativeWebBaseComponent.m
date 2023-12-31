//
//  BDNativeWebBaseComponent.m
//  ByteWebView
//
//  Created by liuyunxuan on 2019/6/12.
//

#import "BDNativeWebBaseComponent.h"
#import "WKWebView+BDNativeWeb.h"
#import "BDNativeWebBaseComponent+Private.h"

@implementation BDNativeWebBaseComponent

+ (NSString *)nativeTagName
{
    return nil;
}

+ (NSNumber *)nativeTagVersion {
    return nil;
}

- (UIView *)insertInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params
{
    return nil;
}

- (void)updateInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params
{
    
}

- (void)deleteInNativeContainerObject:(BDNativeWebContainerObject *)containerObject params:(NSDictionary *)params
{
    
}

- (void)actionInNativeContainerObject:(BDNativeWebContainerObject *)containerObject
                               method:(NSString *)string
                               params:(NSDictionary *)params
                             callback:(BDNativeDispatchActionCallback)callback;
{
    
}

- (void)fireComponentAction:(NSString *)action params:(NSDictionary *)params
{
    [self.webView bdNativeWebInvoke:@([self.tagId integerValue]) functionName:action params:params callback:nil];
}


@end

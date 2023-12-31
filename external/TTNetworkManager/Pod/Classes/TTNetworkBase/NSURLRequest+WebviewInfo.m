//
//  NSURLRequest+WebviewInfo.m
//  TTNetworkManager
//
//  Created by dongyangfan on 2021/12/22.
//

#import "NSURLRequest+WebviewInfo.h"
#import <objc/runtime.h>

static char Key;
static char KeyNeedCommonParams;

@implementation NSURLRequest (WebviewInfo)

-(void)setWebviewInfo:(NSDictionary *)webviewinfo {
    objc_setAssociatedObject(self, &Key, webviewinfo, OBJC_ASSOCIATION_COPY);
}

-(NSDictionary *)webviewInfo {
    return objc_getAssociatedObject(self, &Key);
}

-(void)setNeedCommonParams:(BOOL)needCommonParams {
    objc_setAssociatedObject(self, &KeyNeedCommonParams, [NSNumber numberWithBool:needCommonParams], OBJC_ASSOCIATION_ASSIGN);
}

-(BOOL)needCommonParams {
    return [objc_getAssociatedObject(self, &KeyNeedCommonParams) boolValue];
}
@end

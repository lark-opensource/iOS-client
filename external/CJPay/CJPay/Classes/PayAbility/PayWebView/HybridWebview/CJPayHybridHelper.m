//
//  CJPayHybridHelper.m
//  cjpaysandbox
//
//  Created by ByteDance on 2023/4/26.
//

#import "CJPayHybridHelper.h"
#import "CJPayHybridPlugin.h"
#import "CJPaySDKMacro.h"


@implementation CJPayHybridHelper

+ (BOOL)hasHybridPlugin {
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPlugin)) {
        return YES;
    } else {
        return NO;
    }
}

+ (UIView *)createHybridView:(NSString *)scheme wkDelegate:(id)delegate initialData:(NSDictionary *)params {
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPlugin)) {
        return [CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPlugin) createHybridViewWithScheme:scheme delegate:delegate initialData:params];
    } else {
        CJPayLogAssert(YES, @"宿主未接入Hybrid");
        return nil;
    }
}

+ (WKWebView *)getRawWebview:(UIView *)hybridView {
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPlugin)) {
        return [CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPlugin) getRawWebview:hybridView];
    } else {
        CJPayLogAssert(YES, @"宿主未接入Hybrid");
        return nil;
    }
}

+ (void)sendEvent:(NSString *)event params:(NSDictionary *)data container:(UIView *)view {
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPlugin)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPlugin) sendEvent:event params:data container:view];
    } else {
        CJPayLogAssert(YES, @"宿主未接入Hybrid");
    }
}

+ (NSString *)getContainerID:(UIView *)container {
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPlugin)) {
        return [CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPlugin) getContainerID:container];
    } else {
        CJPayLogAssert(YES, @"宿主未接入Hybrid");
        return @"";
    }
}

@end

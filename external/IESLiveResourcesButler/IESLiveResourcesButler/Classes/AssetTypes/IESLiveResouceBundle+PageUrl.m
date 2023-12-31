//
//  IESLiveResouceBundle+PageUrl.m
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import "IESLiveResouceBundle+PageUrl.h"
#import "NSString+IESLiveResouceBundle.h"

@implementation IESLiveResouceBundle (PageUrl)

- (IESLiveResoucePageUrl)page {
    return ^(NSString *key, NSDictionary *params) {
        return [[self objectForKey:key type:@"pageurl"] ies_lr_formatWithParams:params];
    };
}

- (IESLiveResoucePageUrl)pageNoQuery {
    return ^(NSString *key, NSDictionary *params) {
        NSString *pageurl = self.page(key, params);
        if (pageurl) {
            pageurl = [[pageurl componentsSeparatedByString:@"?"] firstObject];
        }
        return pageurl;
    };
}

@end

//
//  BDStartUpImageURLFilter.m
//  BDStartUp
//
//  Created by bob on 2020/1/15.
//

#import "BDStartUpImageURLFilter.h"
#import <ByteDanceKit/BTDMacros.h>

@implementation BDStartUpImageURLFilter

- (NSString *)identifierWithURL:(NSURL *)url {
    // 去掉域名后的URL作为缓存key
    NSString *urlString = url.absoluteString;
    if (BTD_isEmptyString(url.host)) {
        return urlString;
    }
    
    // 过滤掉非网络图片，避免影响其他业务的图片存储
    if (![url.scheme isEqualToString:@"http"] && ![url.scheme isEqualToString:@"https"]) {
        return urlString;
    }
    
    NSRange hostRange = [urlString rangeOfString:url.host];
    if (hostRange.location == NSNotFound) {
        return urlString;
    }
    
    NSRange deleteRange = NSMakeRange(0, hostRange.location + hostRange.length);
    if (NSMaxRange(deleteRange) >= urlString.length) {
        return urlString;
    }
    
    NSString *key = [urlString stringByReplacingCharactersInRange:deleteRange withString:@""];
    return key;
}

@end

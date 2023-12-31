//
//  BDWebDefaultRequestDecorator.m
//  BDWebKit
//
//  Created by yuanyiyang on 2020/5/12.
//

#import "BDWebDefaultRequestDecorator.h"

@implementation BDWebDefaultRequestDecorator

static id<BDWebDefaultRequestDecoratorDelegate> s_delegate;

- (NSURLRequest *)bdw_decorateRequest:(NSURLRequest *)request
{
    if (request == nil || [BDWebDefaultRequestDecorator delegate] == nil) {
        return request;
    }
    BOOL shouldDecorate = NO;
    id<BDWebDefaultRequestDecoratorDelegate> delegate = [BDWebDefaultRequestDecorator delegate];
    if ([delegate respondsToSelector:@selector(bdw_shouldDecorateRequest:)]) {
        shouldDecorate = [delegate bdw_shouldDecorateRequest:request];
    }
    NSString *deviceId = nil;
    if ([delegate respondsToSelector:@selector(bdw_deviceId)]) {
        deviceId = [delegate bdw_deviceId];
    }
    NSString *appId = nil;
    if ([delegate respondsToSelector:@selector(bdw_appId)]) {
        appId = [delegate bdw_appId];
    }
    if (!(shouldDecorate && deviceId && appId)) {
        return request;
    }
    NSMutableURLRequest *mutableRequest = nil;
    if ([request isKindOfClass:[NSMutableURLRequest class]]) {
        mutableRequest = (NSMutableURLRequest *)request;
    } else {
        mutableRequest = [request mutableCopy];
    }
    [mutableRequest setValue:deviceId forHTTPHeaderField:@"x-device-id"];
    [mutableRequest setValue:appId forHTTPHeaderField:@"x-app-id"];
    
    return [mutableRequest copy];
}

+ (id<BDWebDefaultRequestDecoratorDelegate>)delegate
{
    return s_delegate;
}

+ (void)setDelegate:(id<BDWebDefaultRequestDecoratorDelegate>)delegate
{
    s_delegate = delegate;
}

@end

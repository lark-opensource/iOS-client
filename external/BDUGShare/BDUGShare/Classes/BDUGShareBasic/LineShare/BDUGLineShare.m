//
//  BDUGLineShare.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/14.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

NSString *const BDUGLineShareErrorDomain = @"BDUGLineShareErrorDomain";

#import "BDUGLineShare.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <BDUGShareError.h>

@implementation BDUGLineShare

+ (instancetype)sharedLineShare
{
    static dispatch_once_t onceToken;
    static BDUGLineShare *shareInstance;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGLineShare alloc] init];
    });
    return shareInstance;
}

- (BOOL)lineAppInstalled
{
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"line://"]];
}

- (void)shareImage:(UIImage *)image
{
    if (!image) {
        [self callBackWithErrorType:BDUGShareErrorTypeNoImage];
        return;
    }
    if (![self lineAppInstalled]) {
        [self callBackWithErrorType:BDUGShareErrorTypeAppNotInstalled];
        return;
    }
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    
    [pasteboard setData:UIImageJPEGRepresentation(image, 0.9) forPasteboardType:@"public.jpeg"];
    NSString *contentType = @"image";
    
    NSString *contentKey = [pasteboard.name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSString *urlString = [NSString stringWithFormat:@"line://msg/%@/%@",contentType, contentKey];
    NSURL *sendImageURL = [NSURL URLWithString:urlString];
    if ([[UIApplication sharedApplication] canOpenURL:sendImageURL]) {
        [[UIApplication sharedApplication] openURL:sendImageURL];
        [self callBackError:nil];
    } else {
        [self callBackWithErrorType:BDUGShareErrorTypeAppNotSupportAPI];
    }
}

- (void)shareText:(NSString *)text
{
    if (text.length == 0) {
        [self callBackWithErrorType:BDUGShareErrorTypeNoTitle];
        return;
    }
    if (![self lineAppInstalled]) {
        [self callBackWithErrorType:BDUGShareErrorTypeAppNotInstalled];
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"line://msg/text/%@", [text btd_stringByURLEncode]];
    NSURL *senfTextURL = [NSURL URLWithString:urlString];
    if ([[UIApplication sharedApplication] canOpenURL:senfTextURL]) {
        [[UIApplication sharedApplication] openURL:senfTextURL];
        [self callBackError:nil];
    } else {
        [self callBackWithErrorType:BDUGShareErrorTypeAppNotSupportAPI];
    }
}

#pragma mark - call back

- (void)callBackWithErrorType:(BDUGShareErrorType)type
{
    NSError *error = [BDUGShareError errorWithDomain:BDUGLineShareErrorDomain code:type userInfo:nil];
    [self callBackError:error];
}

- (void)callBackError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(lineShare:sharedWithError:)]) {
        [_delegate lineShare:self sharedWithError:error];
    }
}

@end

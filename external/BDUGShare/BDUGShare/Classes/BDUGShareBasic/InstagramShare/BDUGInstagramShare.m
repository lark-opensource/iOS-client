//
//  BDUGInstagramShare.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/5/30.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

static NSString *const kInstagramOpenURLString = @"instagram://app";

NSString * const BDUGInstagramShareErrorDomain = @"BDUGInstagramShareErrorDomain";

#import "BDUGInstagramShare.h"
#import "BDUGSystemShare.h"
#import "BDUGShareError.h"

@implementation BDUGInstagramShare

static BDUGInstagramShare *shareInstance;

+ (instancetype)sharedInstagramShare {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGInstagramShare alloc] init];
    });
    return shareInstance;
}

+ (BOOL)instagramInstalled
{
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kInstagramOpenURLString]];
}

+ (BOOL)openInstagram
{
    return [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kInstagramOpenURLString]];
}

- (void)sendFileWithAlbumIdentifier:(NSString *)identifier
{
    if (![self.class instagramInstalled]) {
        [self callBackWithErrorType:BDUGShareErrorTypeAppNotInstalled];
        return;
    }
    NSString *URLString = [NSString stringWithFormat:@"instagram://library?LocalIdentifier=%@", identifier];
    NSURL *URL = [NSURL URLWithString:URLString];
    if ([[UIApplication sharedApplication] canOpenURL:URL]) {
        [[UIApplication sharedApplication] openURL:URL];
        [self callBackError:nil];
    } else {
        [self callBackWithErrorType:BDUGShareErrorTypeSendRequestFail];
    }
}

- (void)sendImageToStories:(UIImage *)image {
    if (image == nil) {
        [self callBackWithErrorType:BDUGShareErrorTypeNoImage];
        return;
    }
    if (@available(iOS 10.0, *)) {
        NSURL *urlScheme = [NSURL URLWithString:@"instagram-stories://share"];
        if ([[UIApplication sharedApplication] canOpenURL:urlScheme]) {
            NSArray *pasteboardItems = @[@{@"com.instagram.sharedSticker.backgroundImage" : image}];
            NSDictionary *pasteboardOptions = @{UIPasteboardOptionExpirationDate : [[NSDate date] dateByAddingTimeInterval:60 * 5]};
            // This call is iOS 10+, can use 'setItems' depending on what versions you support
            [[UIPasteboard generalPasteboard] setItems:pasteboardItems options:pasteboardOptions];
            [[UIApplication sharedApplication] openURL:urlScheme options:@{} completionHandler:nil];
            [self callBackError:nil];
        } else {
            // Handle older app versions or app not installed case
            [self callBackWithErrorType:BDUGShareErrorTypeSendRequestFail];
        }
    } else {
        [self callBackWithErrorType:BDUGShareErrorTypeOther];
    }
}

- (void)sendVideoDataToStories:(NSData *)videoData {
    if (videoData.length == 0) {
        [self callBackWithErrorType:BDUGShareErrorTypeNoVideo];
        return;
    }
    if (videoData.length > 50 * 1024 * 1024) {
        [self callBackWithErrorType:BDUGShareErrorTypeExceedMaxVideoSize];
        return;
    }
    if (@available(iOS 10.0, *)) {
        NSURL *urlScheme = [NSURL URLWithString:@"instagram-stories://share"];
        if ([[UIApplication sharedApplication] canOpenURL:urlScheme]) {
            NSArray *pasteboardItems = @[@{@"com.instagram.sharedSticker.backgroundVideo" : videoData}];
            NSDictionary *pasteboardOptions = @{UIPasteboardOptionExpirationDate : [[NSDate date] dateByAddingTimeInterval:60 * 5]};
            // This call is iOS 10+, can use 'setItems' depending on what versions you support
            [[UIPasteboard generalPasteboard] setItems:pasteboardItems options:pasteboardOptions];
            [[UIApplication sharedApplication] openURL:urlScheme options:@{} completionHandler:nil];
            [self callBackError:nil];
        } else {
            // Handle older app versions or app not installed case
            [self callBackWithErrorType:BDUGShareErrorTypeSendRequestFail];
        }
    } else {
        [self callBackWithErrorType:BDUGShareErrorTypeOther];
    }
}

#pragma mark - call back

- (void)callBackWithErrorType:(BDUGShareErrorType)type
{
    NSError *error = [BDUGShareError errorWithDomain:BDUGInstagramShareErrorDomain code:type userInfo:nil];
    [self callBackError:error];
}

- (void)callBackError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(instagramShare:sharedWithError:)]) {
        [_delegate instagramShare:self sharedWithError:error];
    }
}


@end

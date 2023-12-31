//
//  BDUGKakaoTalkShare.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/17.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import "BDUGKakaoTalkShare.h"
#import "BDUGShareError.h"
#import <KakaoLink/KakaoLink.h>
#import <KakaoOpenSDK/KakaoOpenSDK.h>

NSString * const BDUGKakaoTalkShareErrorDomain = @"BDUGKakaoTalkShareErrorDomain";

@implementation BDUGKakaoTalkShare

+ (instancetype)sharedKakaoTalkShare
{
    static dispatch_once_t onceToken;
    static BDUGKakaoTalkShare *shareInstance;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGKakaoTalkShare alloc] init];
    });
    return shareInstance;
}

- (BOOL)kakaoTalkInstalled
{
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"kakaolink://"]];
}

- (void)shareURL:(NSURL *)URL
{
    if (!URL) {
        NSError *userError = [BDUGShareError errorWithDomain:BDUGKakaoTalkShareErrorDomain code:BDUGShareErrorTypeNoWebPageURL userInfo:nil];
        [self callBackError:userError];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[KLKTalkLinkCenter sharedCenter] sendScrapWithURL:URL success:^(NSDictionary<NSString *,NSString *> * _Nullable warningMsg, NSDictionary<NSString *,NSString *> * _Nullable argumentMsg) {
        [weakSelf configKakaoShareError:nil];
    } failure:^(NSError * _Nonnull error) {
        [weakSelf configKakaoShareError:error];
    }];
}

- (void)shareImage:(UIImage *)image title:(NSString *)title
{
    if (!image) {
        NSError *userError = [BDUGShareError errorWithDomain:BDUGKakaoTalkShareErrorDomain code:BDUGShareErrorTypeNoImage userInfo:nil];
        [self callBackError:userError];
        return;
    }
    __weak typeof(self) weakSelf = self;
    [[KLKImageStorage sharedStorage] uploadWithImage:image success:^(KLKImageInfo * _Nonnull original) {
        KLKLinkObject *link = [KLKLinkObject linkObjectWithBuilderBlock:^(KLKLinkBuilder * _Nonnull linkBuilder) {
            
        }];
        KLKContentObject *content = [KLKContentObject contentObjectWithTitle:title
                                                                    imageURL:original.URL
                                                                        link:link];
        [[KLKTalkLinkCenter sharedCenter] sendDefaultWithTemplate:[KLKFeedTemplate feedTemplateWithContent:content] success:^(NSDictionary<NSString *,NSString *> * _Nullable warningMsg, NSDictionary<NSString *,NSString *> * _Nullable argumentMsg) {
            [weakSelf configKakaoShareError:nil];
        } failure:^(NSError * _Nonnull error) {
            [weakSelf configKakaoShareError:error];
        }];
    } failure:^(NSError * _Nonnull error) {
        [weakSelf configKakaoShareError:error];
    }];
}

#pragma mark -

- (void)configKakaoShareError:(NSError *)error
{
    if (!error) {
        [self callBackError:nil];
    } else if ([error.domain isEqualToString:KCMErrorDomain]) {
        BDUGShareErrorType errorType;
        switch (error.code) {
            case KCMErrorCodeCancelled: {
                errorType = BDUGShareErrorTypeUserCancel;
            }
                break;
            case KCMErrorCodeNotSupported: {
                errorType = BDUGShareErrorTypeAppNotSupportAPI;
            }
                break;
            default: {
                errorType = BDUGShareErrorTypeOther;
            }
                break;
        }
        NSError *error = [BDUGShareError errorWithDomain:BDUGKakaoTalkShareErrorDomain code:errorType userInfo:nil];
        [self callBackError:error];
    } else {
        NSError *error = [BDUGShareError errorWithDomain:BDUGKakaoTalkShareErrorDomain code:BDUGShareErrorTypeOther userInfo:nil];
        [self callBackError:error];
    }
}

- (void)callBackError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(kakaoTalkShare:sharedWithError:)]) {
        [_delegate kakaoTalkShare:self sharedWithError:error];
    }
}

@end

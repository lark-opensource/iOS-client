//
//  BDDYCSessionChallenge.m
//  BDDynamically
//
//  Created by zuopengliu on 7/6/2018.
//

#import "BDDYCSessionChallenge.h"



@implementation BDDYCSessionDelegate

+ (instancetype)shared
{
    static BDDYCSessionDelegate *sharedInst;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInst = [self new];
    });
    return sharedInst;
}


#pragma mark - NSURLSessionDelegate
 
- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                             NSURLCredential * _Nullable credential))completionHandler
{
    if (![challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge,nil);
        return;
    }

    if (challenge.previousFailureCount != 0) {
        // 失败多次，取消授权
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        return;
    }

    // 证书是否可信。
    SecTrustResultType trustResult = kSecTrustResultInvalid;
    OSStatus status = SecTrustEvaluate(challenge.protectionSpace.serverTrust, &trustResult);
    BOOL allowConnection = NO;
    if (status == noErr) {
        allowConnection = (trustResult == kSecTrustResultProceed || trustResult == kSecTrustResultUnspecified);
    }
    
    if (allowConnection) {
        // 证书可信
        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge,nil);
    }
}

@end



@implementation NSURLSession (BDDYCSession)

+ (NSURLSessionDataTask *)bddyc_dataTaskWithRequest:(NSURLRequest *)request
                                  completionHandler:(void (^)(NSData * _Nullable data,
                                                              NSURLResponse * _Nullable response,
                                                              NSError * _Nullable error))completionHandler
{
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                          delegate:[BDDYCSessionDelegate shared]
                                                     delegateQueue:nil];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:completionHandler];
    return task;
}

@end

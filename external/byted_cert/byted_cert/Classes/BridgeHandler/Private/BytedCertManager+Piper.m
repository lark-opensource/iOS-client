//
//  BytedCertManager+Piper.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/22.
//

#import "BytedCertManager+Piper.h"
#import "BDCTCertificationFlow.h"
#import "BDCTEventTracker.h"
#import "BytedCertError.h"
#import "BytedCertInterface.h"
#import "BytedCertManager+Private.h"
#import "BDCTFlowContext.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <BDAssert/BDAssert.h>


@implementation BytedCertManager (Piper)

- (void)p_beginAuthorizationWithParams:(NSDictionary *)params {
    BytedCertParameter *parameter = [params btd_objectForKey:@"parameter" default:nil];
    UIViewController *fromViewController = [params btd_objectForKey:@"fromViewController" default:nil];
    BOOL forcePresent = [params btd_boolValueForKey:@"forcePresent"];
    void (^completionBlock)(NSError *, NSDictionary *) = [params btd_objectForKey:@"completion" default:nil];
    [self beginAuthorizationWithParameter:parameter fromViewController:fromViewController forcePresent:forcePresent completion:completionBlock];
}

- (void)beginAuthorizationWithParameter:(BytedCertParameter *)parameter completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion {
    [self beginAuthorizationWithParameter:parameter fromViewController:nil completion:completion];
}

- (void)beginAuthorizationWithParameter:(BytedCertParameter *)parameter fromViewController:(UIViewController *)fromVC completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion {
    [self beginAuthorizationWithParameter:parameter fromViewController:fromVC forcePresent:NO completion:completion];
}

- (void)beginAuthorizationWithParameter:(BytedCertParameter *)parameter fromViewController:(UIViewController *)fromVC forcePresent:(BOOL)forcePresent completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion {
    [self beginAuthorizationWithParameter:parameter fromViewController:fromVC forcePresent:forcePresent superFlow:nil completion:completion];
}

- (void)beginAuthorizationWithParameter:(BytedCertParameter *)parameter fromViewController:(UIViewController *_Nullable)fromVC forcePresent:(BOOL)forcePresent superFlow:(BDCTFlow *)superFlow completion:(void (^)(NSError *_Nullable, NSDictionary *_Nullable))completion {
    BDCTCertificationFlow *flow = [[BDCTCertificationFlow alloc] initWithContext:[BDCTFlowContext contextWithParameter:parameter]];
    [flow setFromViewController:fromVC];
    [flow setForcePresent:forcePresent];
    [flow setSuperFlow:superFlow];
    [flow setCompletionBlock:^(NSError *_Nullable error, NSDictionary *_Nullable result) {
        !completion ?: completion(error, result);
    }];
    [flow begin];
}

+ (void)handleWebEventWithParams:(NSDictionary *)params completion:(void (^)(BOOL, NSDictionary *_Nullable result))completion {
    __block BOOL isHandled = NO;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if ([[BytedCertInterface sharedInstance].bytedCertProgressDelegate respondsToSelector:@selector(handleWebEventWithJsbParams:jsbCallback:)]) {
        [[BytedCertInterface sharedInstance].bytedCertProgressDelegate handleWebEventWithJsbParams:params jsbCallback:^(TTBridgeMsg msg, NSDictionary *_Nullable params, void (^_Nullable resultBlock)(NSString *_Nonnull)) {
            completion(msg == TTBridgeMsgSuccess, nil);
        }];
        isHandled = YES;
    }
    if (!isHandled) {
        [[BytedCertInterface sharedInstance].progressDelegateArray enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([obj respondsToSelector:@selector(handleWebEventWithJsbParams:jsbCallback:)]) {
                [obj handleWebEventWithJsbParams:params jsbCallback:^(TTBridgeMsg msg, NSDictionary *_Nullable params, void (^_Nullable resultBlock)(NSString *_Nonnull)) {
                    completion(msg == TTBridgeMsgSuccess, nil);
                }];
                *stop = YES;
                isHandled = YES;
            }
        }];
    } else {
        [[BytedCertInterface sharedInstance].progressDelegateArray enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            BDAssert(![obj respondsToSelector:@selector(handleWebEventWithJsbParams:jsbCallback:)], @"BytedCertDelegate handleWebEvent method implement repeatedly");
        }];
    }
#pragma clang diagnostic pop

    if (!isHandled) {
        if ([BytedCertManager.delegate respondsToSelector:@selector(bytedCertManager:handlerWebEventWithParams:completion:)]) {
            [BytedCertManager.delegate bytedCertManager:BytedCertManager.shareInstance handlerWebEventWithParams:params completion:^(BOOL completed) {
                completion(completed, nil);
            }];
            isHandled = YES;
        }
    } else {
        BDAssert(![BytedCertManager.delegate respondsToSelector:@selector(bytedCertManager:handlerWebEventWithParams:completion:)], @"BytedCertDelegate handleWebEvent method implement repeatedly");
    }
    if (!isHandled) {
        if ([BytedCertManager.delegate respondsToSelector:@selector(bytedCertManager:handlerWebEventWithParams:)]) {
            BOOL isCompleted = [BytedCertManager.delegate bytedCertManager:BytedCertManager.shareInstance handlerWebEventWithParams:params];
            completion(isCompleted, nil);
            isHandled = YES;
        }
    } else {
        BDAssert(![BytedCertManager.delegate respondsToSelector:@selector(bytedCertManager:handlerWebEventWithParams:)], @"BytedCertDelegate handleWebEvent method implement repeatedly");
    }
    if (!isHandled) {
        if ([BytedCertManager.delegate respondsToSelector:@selector(bytedCertManager:handlerWebEventForResultWithParams:completion:)]) {
            [BytedCertManager.delegate bytedCertManager:BytedCertManager.shareInstance handlerWebEventForResultWithParams:params completion:completion];
            isHandled = YES;
        }
    } else {
        BDAssert(![BytedCertManager.delegate respondsToSelector:@selector(bytedCertManager:handlerWebEventForResultWithParams:completion:)], @"BytedCertDelegate handleWebEvent method implement repeatedly");
    }
    if (!isHandled) {
        completion(NO, nil);
    }
}

@end

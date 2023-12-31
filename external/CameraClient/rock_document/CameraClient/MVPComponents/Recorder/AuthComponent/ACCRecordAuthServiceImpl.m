//
//  ACCRecordAuthServiceImpl.m
//  Pods
//
//  Created by liyingpeng on 2020/5/19.
//

#import "ACCRecordAuthServiceImpl.h"
#import <CreationKitInfra/ACCDeviceAuth.h>

@interface ACCRecordAuthServiceImpl ()

@property (nonatomic, strong, readwrite) RACSignal *confirmAllowUseCameraSignal;
@property (nonatomic, strong, readwrite) RACSignal <NSNumber *> *passCheckAuthSignal;

@property (nonatomic, strong, readwrite) RACSubject *confirmAllowUseCameraSubject;
@property (nonatomic, strong, readwrite) RACSubject <NSNumber *> *passCheckAuthSubject;

@end

@implementation ACCRecordAuthServiceImpl

#pragma mark - life circle

- (void)dealloc
{
    [self.confirmAllowUseCameraSubject sendCompleted];
    [self.passCheckAuthSubject sendCompleted];
}

#pragma mark - getter &setter

- (RACSubject *)confirmAllowUseCameraSubject {
    if (!_confirmAllowUseCameraSubject) {
        _confirmAllowUseCameraSubject = [RACSubject subject];
    }
    return _confirmAllowUseCameraSubject;
}

- (RACSubject *)passCheckAuthSubject {
    if (!_passCheckAuthSubject) {
        _passCheckAuthSubject = [RACSubject subject];
    }
    return _passCheckAuthSubject;
}

- (RACSignal *)confirmAllowUseCameraSignal {
    return self.confirmAllowUseCameraSubject;
}

- (RACSignal<NSNumber *> *)passCheckAuthSignal {
    return self.passCheckAuthSubject;
}

#pragma mark - public

- (void)setAuthorityTitle:(NSString *)title {
    self.customAuthorityTitle = title;
}

- (void)setAuthorityMessage:(NSString *)message {
    self.customAuthorityMessage = message;
}

#pragma mark - private

- (void)trigger_confirmAllowUseCamera:(BOOL)isAllowed {
    [self.confirmAllowUseCameraSubject sendNext:@(isAllowed)];
}

- (void)trigger_passCheckAuth:(ACCRecordAuthComponentAuthType)authType {
    [self.passCheckAuthSubject sendNext:@(authType)];
}

@end

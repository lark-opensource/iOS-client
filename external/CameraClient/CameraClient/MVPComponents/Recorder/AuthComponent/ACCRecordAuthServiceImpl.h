//
//  ACCRecordAuthServiceImpl.h
//  Pods
//
//  Created by liyingpeng on 2020/5/19.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitInfra/ACCRecordAuthDefine.h>
#import "ACCRecordAuthService.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecordAuthServiceImpl : NSObject <ACCRecordAuthService>

@property (nonatomic, strong, readonly) RACSignal *confirmAllowUseCameraSignal;
@property (nonatomic, strong, readonly) RACSignal <NSNumber *> *passCheckAuthSignal;
@property (nonatomic, copy) NSString *customAuthorityTitle;
@property (nonatomic, copy) NSString *customAuthorityMessage;

- (void)setAuthorityTitle:(NSString *)title;
- (void)setAuthorityMessage:(NSString *)message;

- (void)trigger_confirmAllowUseCamera:(BOOL)isAllowed;
- (void)trigger_passCheckAuth:(ACCRecordAuthComponentAuthType)authType;


@end

NS_ASSUME_NONNULL_END

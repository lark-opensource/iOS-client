//
//  EMAAppEngineAccount.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2020/2/19.
//

#import "EMAAppEngineAccount.h"
#import "EMAEncryptionTool.h"
#import "EMADebugUtil.h"
#import "BDPUtils.h"

@interface EMAAppEngineAccount ()

@property (nonatomic, copy, readwrite) NSString *accountToken;

@property (nonatomic, copy, readwrite) NSString *userID;

@property (nonatomic, copy, readwrite) NSString *tenantID;

@property (nonatomic, copy, readwrite) NSString *encyptedTenantID;

@property (nonatomic, copy, readwrite) NSString *userSession;

@end

@implementation EMAAppEngineAccount

- (instancetype)initWithAccount:(NSString * _Nonnull)accountToken
                         userID:(NSString * _Nonnull)userID
                    userSession:(NSString * _Nonnull)userSession
                       tenantID:(NSString * _Nonnull)tenantID {
    self = [super init];
    if (self) {
        _accountToken = accountToken;
        _userID = userID;
        _encyptedUserID = [EMAEncryptionTool encyptID:userID];
        _userSession = userSession;
        _tenantID = tenantID;
        _encyptedTenantID = [EMAEncryptionTool encyptID:tenantID];
    }
    return self;
}

- (NSString *)userSession {
    NSString *debugSession = [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDChangeHostSessionID].stringValue;
    if (!BDPIsEmptyString(debugSession)) {
        return debugSession;
    }
    return _userSession;
}

@end

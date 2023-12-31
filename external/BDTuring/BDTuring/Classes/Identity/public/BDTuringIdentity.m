//
//  BDTuringIdentity.m
//  BDTuring
//
//  Created by bob on 2020/3/6.
//

#import "BDTuringIdentity.h"
#import "BDTuringService.h"
#import "BDTuringServiceCenter.h"
#import "BDTuringIdentityDefine.h"
#import "BDTuringEventService.h"

#import "BDTuringIdentityModel.h"
#import "BDTuringIdentityResult.h"


@interface BDTuringIdentity ()<BDTuringVerifyService>

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *serviceName;

@end

@implementation BDTuringIdentity

+ (instancetype)identityWithAppID:(NSString *)appID {
    BDTuringIdentity *identity = [[self alloc] initWithAppID:appID];
    [[BDTuringServiceCenter defaultCenter] registerService:identity];
    
    return identity;
}

- (instancetype)initWithAppID:(NSString *)appID {
    self = [super init];
    if (self) {
        self.appID = appID;
        self.serviceName = NSStringFromClass([BDTuringIdentityModel class]);
    }
    
    return self;
}

- (void)popVerifyViewWithModel:(BDTuringIdentityModel *)model {
    id<BDTuringIdentityHandler> handler = self.handler;
    NSCAssert(handler != nil && model != nil, @"handler and model should not be nil!");
    if (![handler respondsToSelector:@selector(popVerifyViewWithModel:)]) {
        [model handleResult:[BDTuringIdentityResult unsupportResult]];
        return;
    }
    
    [handler popVerifyViewWithModel:model];
}

@end

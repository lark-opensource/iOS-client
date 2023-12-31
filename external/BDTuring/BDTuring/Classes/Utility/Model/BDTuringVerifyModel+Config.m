//
//  BDTuringVerifyModel+Config.m
//  BDTuring
//
//  Created by bob on 2020/7/13.
//

#import "BDTuringVerifyModel+Config.h"

#import "BDTuringVerifyState.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringMacro.h"
#import "BDTuringUtility.h"


@implementation BDTuringVerifyModel (Config)

@dynamic appID;
@dynamic verifyType;
@dynamic plugin;
@dynamic region;
@dynamic showToast;
@dynamic userID;
@dynamic state;
@dynamic handlerName;
@dynamic supportLandscape;

- (void)createState {
    BDTuringVerifyState *state = [BDTuringVerifyState new];
    self.state = state;
}

- (void)appendCommonKVParameters:(NSMutableDictionary *)paramters {
    [paramters setValue:self.region forKey:kBDTuringRegion];
    NSString *userID = self.userID;
    if (BDTuring_isValidString(userID)) {
        [paramters setValue:userID forKey:kBDTuringUserID];
    }
}

- (void)appendKVToQueryParameters:(NSMutableDictionary *)paramters {
    [self appendCommonKVParameters:paramters];
    NSInteger showToast = self.showToast;
    if (showToast > 0) {
        [paramters setValue:@(showToast) forKey:kBDTuringShowToast];
    }
}

- (void)appendKVToEventParameters:(NSMutableDictionary *)parameters {
    [self appendCommonKVParameters:parameters];
    BDTuringVerifyType type = self.verifyType;
    if (type > 0) {
        [parameters setValue:@(type) forKey:kBDTuringType];
    }
    NSDictionary *h5State = self.state.h5State;
    if (BDTuring_isValidDictionary(h5State)) {
        [parameters addEntriesFromDictionary:h5State];
    }
}

@end

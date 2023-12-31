//
//  HMDTTMonitorUserInfo+Private.m
//  Heimdallr-8bda3036
//
//  Created by xushuangqing on 2022/6/17.
//

#import "HMDTTMonitorUserInfo+Private.h"
#import "HMDMacro.h"
#import "NSDictionary+HMDJSON.h"

@implementation HMDTTMonitorUserInfo (Private)

- (NSDictionary<NSString *,id> *)currentCommonParams {
    NSDictionary<NSString *, id> *params = nil;
    HMDTTMonitorCommonParamsBlock block = self.commonParamsBlock;
    if (block) {
        params = block();
    }
    if (!HMDIsEmptyDictionary(params) && [params hmd_isValidJSONObject]) {
        return params;
    }
    
    params = self.commonParams;
    if (!HMDIsEmptyDictionary(params) && [params hmd_isValidJSONObject]) {
        return params;
    }
    return nil;
}

@end

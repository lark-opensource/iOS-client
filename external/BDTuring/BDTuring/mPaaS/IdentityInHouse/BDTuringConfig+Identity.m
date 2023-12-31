//
//  BDTuringConfig+Identity.m
//  BDTuring
//
//  Created by bob on 2020/3/6.
//

#import "BDTuringConfig+Identity.h"

#import "BDTuringIdentityDefine.h"
#import "NSDictionary+BDTuring.h"
#import "BDTuringSettings.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringIdentityModel.h"

#import <byted_cert/BytedCertDefine.h>


@implementation BDTuringConfig (Identity)

- (NSMutableDictionary *)identityParameterWithModel:(BDTuringIdentityModel *)model {
    NSMutableDictionary *params = [NSMutableDictionary new];
    [params setValue:@(model.mode) forKey:BytedCertParamMode];
    [params setValue:model.scene forKey:BytedCertParamScene];
    [params setValue:model.ticket forKey:BytedCertParamTicket];
    NSString *appID = self.appID;
    [params setValue:appID forKey:BytedCertParamAppId];
    
    return params;
}

@end

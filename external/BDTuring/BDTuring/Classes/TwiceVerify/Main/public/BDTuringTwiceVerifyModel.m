//
//  BDTuringTwiceVerifyModel.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/11/30.
//

#import "BDTuringTwiceVerifyModel.h"
#import "NSDictionary+BDTuring.h"
#import "BDTuringTVDefine.h"
#import "NSMutableDictionary+BDTuring.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDTuringVerifyState.h"
#import "BDTuringVerifyModel+Parameter.h"

@interface BDTuringTwiceVerifyModel() <BDTuringParameterModel>

@end

@implementation BDTuringTwiceVerifyModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.handlerName = NSStringFromClass([self class]);
    }
    
    return self;
}


+ (instancetype)modelWithParameter:(NSDictionary *)parameter {
    BDTuringTwiceVerifyModel *model = [BDTuringTwiceVerifyModel new];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    NSArray *verifyWays = [parameter turing_arrayValueForKey:@"verify_ways"];
    NSString *type = nil;
    if ([verifyWays isKindOfClass:[NSArray class]] && verifyWays.count == 1) {
        type = [[verifyWays firstObject] turing_stringValueForKey:@"verify_way"];
    } else {
        type = [parameter turing_stringValueForKey:@"subtype"];
    }
    
    if (type == nil) {
        return nil;
    }
    [params setValue:type forKey:kBDTuringTVDecisionConfig];
    NSString *verify_ticket = [parameter turing_stringValueForKey:kBDTuringTVVerifyTicket];
    if (verify_ticket) {
        [params setValue:verify_ticket forKey:kBDTuringTVVerifyTicket];
    }
    
    NSString *verifyData = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:parameter options:0 error:nil] encoding:NSUTF8StringEncoding];
    if (verifyData) {
        [params setValue:verifyData forKey:kBDTuringTVVerifyData];
    }
    
    model.params = params;
    return model;
}

@end

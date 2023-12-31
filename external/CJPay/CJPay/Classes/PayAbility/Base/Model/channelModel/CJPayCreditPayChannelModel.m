//
//  CJPayCreditPayChannelModel.m
//  CJPaySandBox_3
//
//  Created by wangxiaohong on 2023/3/9.
//

#import "CJPayCreditPayChannelModel.h"
#import "CJPaySubPayTypeData.h"

@implementation CJPayCreditPayChannelModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"code": @"ptcode",
                @"extParamStr": @"ext_param",
                @"status": @"status",
                @"payTypeData": @"pay_type_data"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)buildShowConfig {
    CJPayDefaultChannelShowConfig *configModel = [CJPayDefaultChannelShowConfig new];
    configModel.iconUrl = self.iconUrl;
    configModel.title = self.title;
    configModel.subTitle = self.msg;
    configModel.payChannel = self;
    configModel.status = self.status;
    configModel.canUse = [self.status isEqualToString:@"1"];
    configModel.cjIdentify = self.code;
    configModel.type = BDPayChannelTypeCreditPay;
    configModel.payTypeData = [self.payTypeData copy];
    configModel.retainInfoV2 = self.retainInfoV2;
    return @[configModel];
}

@end

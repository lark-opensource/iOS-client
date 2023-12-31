//
//  CJPayChannelModel.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/21.
//

#import "CJPayChannelModel.h"
#import "CJPayTypeInfo.h"

@implementation CJPayChannelInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"channelData": @"channel_data",
                @"payType": @"channel_pay_type",
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

@implementation CJPayChannelModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"mark" : @"mark",
                @"marks" : @"mark_array",
                @"msg" : @"msg",
                @"status" : @"status",
                @"title" : @"title",
                @"iconUrl": @"icon_url",
                @"payTypeItemInfo": @"paytype_item_info",
                @"code": @"ptcode",
                @"identityVerifyWay": @"identity_verify_way",
                @"subTitleColorStr": @"sub_title_color",
                @"tipsMsg" : @"tips_msg",
                @"signStatus" : @"sign_status",
                @"retainInfoV2": @"retain_info_v2",
                @"index": @"index"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

@implementation CJPayChannelModel(Biz)

- (NSArray<CJPayDefaultChannelShowConfig *> *)buildShowConfig {
    CJPayDefaultChannelShowConfig *configModel = [CJPayDefaultChannelShowConfig new];
    configModel.iconUrl = self.iconUrl;
    configModel.title = self.title;
    configModel.subTitle = self.msg;
    configModel.subTitleColor = self.subTitleColorStr;
    configModel.payChannel = self;
    configModel.status = self.status;
    configModel.mark = self.mark;
    configModel.cjIdentify = self.cjIdentify;
    configModel.marks = self.marks;
    configModel.canUse = [self.status isEqualToString:@"1"];
    configModel.type =  [CJPayTypeInfo getChannelTypeBy:self.code];
    configModel.retainInfoV2 = self.retainInfoV2;
    configModel.index = self.index;
    return @[configModel];
}


- (NSDictionary *)requestNeedParams{
    return @{@"ptcode": self.code ?: @""};
    
}

@end


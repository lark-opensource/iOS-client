//
//  CJPayMemAuthInfo.m
//  BDPay
//
//  Created by 易培淮 on 2020/6/4.
//

#import "CJPayMemAuthInfo.h"
#import "CJPaySettings.h"
#import "CJPaySettingsManager.h"

@implementation CJPayMemAuthInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"payUID":@"pay_uid",
        @"memberLevel":@"member_level",
        @"memberType":@"member_type",
        @"isSetPWD":@"is_set_pwd",
        @"isAuthed":@"is_authed",
        @"isOpenAccount":@"is_open_account",
        @"mobileMask":@"mobile_mask",
        @"contactAddress":@"contact_address",
        @"country":@"country",
        @"countryName":@"country_name",
        @"customerId":@"customer_id",
        @"idCodeMask":@"id_code_mask",
        @"idExpireDate":@"id_expire_date",
        @"idNameMask":@"id_name_mask",
        @"idPhotoStatus":@"id_photo_status",
        @"idType":@"id_type",
        @"isIdPhotoUploaded":@"is_id_photo_uploaded",
        @"job":@"job",
        @"sex":@"sex",
        @"sexName":@"sex_name"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

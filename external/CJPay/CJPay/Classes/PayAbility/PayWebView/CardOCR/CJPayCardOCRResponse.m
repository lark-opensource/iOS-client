//
//  CJPayCardOCRResponse.m
//  CJPay
//
//  Created by 尚怀军 on 2020/5/18.
//

#import "CJPayCardOCRResponse.h"

#import "CJPayUIMacro.h"

@implementation CJPayCardOCRResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
                                    @"croppedImgStr" : @"response.cropped_img",
                                    @"cardNoStr" : @"response.card_no"
                                    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

@end

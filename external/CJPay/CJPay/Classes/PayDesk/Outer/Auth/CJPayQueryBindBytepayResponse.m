//
//  CJPayQueryBindBytepayResponse.m
//  Pods
//
//  Created by 徐天喜 on 2022/8/31.
//

#import "CJPayQueryBindBytepayResponse.h"

@implementation CJPayQueryBindBytepayResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"isComplete" : @"response.is_complete",
        @"isLnyxURL": @"response.is_redirect_url_lynx",
        @"redirectURL": @"response.redirect_url",
        @"buttonInfo": @"response.button_info",
    }];
    
    [dic addEntriesFromDictionary:[self basicDict]];

    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dic];
}

- (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

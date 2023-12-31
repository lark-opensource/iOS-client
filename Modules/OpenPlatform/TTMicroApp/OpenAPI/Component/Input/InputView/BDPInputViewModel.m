//
//  BDPInputViewModel.m
//  Timor
//
//  Created by 王浩宇 on 2018/12/4.
//

#import "BDPInputViewModel.h"
#import <OPFoundation/BDPUtils.h>

#import <ECOInfra/NSDictionary+BDPExtension.h>

@implementation BDPInputViewModel

// 补齐微信输入组件input和textarea的adjust-position的功能
- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    self = [super initWithDictionary:dict error:err];
    if (self) {
        NSString *adjustPositionStr = [dict bdp_stringValueForKey:@"adjustPosition"];
        if (BDPIsEmptyString(adjustPositionStr)) {
            self.adjustPosition = YES;
        }
    }
    
    return self;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (NSAttributedString *)attributedPlaceholder
{
    NSString *placeHolder = self.placeholder;
    if (placeHolder) {
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:placeHolder attributes:self.placeholderStyle.attributedStyle];
        return attributedString;
    }
    return nil;
}

@end

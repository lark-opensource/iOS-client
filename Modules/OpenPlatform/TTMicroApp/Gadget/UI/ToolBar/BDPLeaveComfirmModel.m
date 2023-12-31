//
//  BDPLeaveComfirmModel.m
//  TTMicroApp
//
//  Created by bytedance on 2022/3/21.
//

#import "BDPLeaveComfirmModel.h"

@implementation BDPLeaveComfirmModel

- (instancetype)initWithTitle:(NSString *)title
                      content:(NSString *)content
                  confirmText:(NSString *)confirmText
                   cancelText:(NSString *)cancelText
                       effect:(NSArray *)effect
                 confirmColor:(NSString *)confirmColor
                  cancelColor:(NSString *)cancelColor {
    if (self = [super init]) {
        _title = title;
        _content = content;
        _confirmText = confirmText;
        _cancelText = cancelText;
        _confirmColor = confirmColor;
        _cancelColor = cancelColor;
        
        NSDictionary *effectMap = @{
            @"back":@(BDPLeaveComfirmActionBack),
            @"close":@(BDPLeaveComfirmActionClose)
        };
        
        __block BDPLeaveComfirmAction effects = 0;
        
        [effect enumerateObjectsUsingBlock:^(NSString *ele, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([ele isKindOfClass:[NSString class]] && ele.length > 0) {
                effects |= [effectMap[ele] integerValue];
            }
        }];
        _effects = effects;
    }
    return self;
}

@end

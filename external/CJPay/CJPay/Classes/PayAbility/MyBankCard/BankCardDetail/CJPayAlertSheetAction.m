//
// Created by 张海阳 on 2019/10/27.
//

#import "CJPayAlertSheetAction.h"
#import "CJPayUIMacro.h"


@implementation CJPayAlertSheetAction

+ (instancetype)actionWithRegularTitle:(NSString *)title handler:(CJPayAlertSheetActionHandler)handler {
    CJPayAlertSheetAction *action = [CJPayAlertSheetAction new];
    action.attributedTitle = [[NSAttributedString alloc] initWithString:title
                                                             attributes:@{
                                                                     NSFontAttributeName: [UIFont cj_fontOfSize:15],
                                                                     NSForegroundColorAttributeName: [UIColor cj_161823ff]
                                                             }];
    action.handler = handler;
    return action;
}

@end


@implementation CJPayAlertSheetActionButton

@end

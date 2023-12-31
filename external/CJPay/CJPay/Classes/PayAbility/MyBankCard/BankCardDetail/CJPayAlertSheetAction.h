//
// Created by 张海阳 on 2019/10/27.
//

#import <Foundation/Foundation.h>


@interface CJPayAlertSheetAction : NSObject

@end


typedef void(^CJPayAlertSheetActionHandler)(CJPayAlertSheetAction *);


@interface CJPayAlertSheetAction ()

+ (instancetype)actionWithRegularTitle:(NSString *)title handler:(CJPayAlertSheetActionHandler)handler;

@property (nonatomic, copy) CJPayAlertSheetActionHandler handler;
@property (nonatomic, copy) NSAttributedString *attributedTitle;

@end


@interface CJPayAlertSheetActionButton : UIButton

@property (nonatomic, weak) CJPayAlertSheetAction *alertSheetAction;

@end

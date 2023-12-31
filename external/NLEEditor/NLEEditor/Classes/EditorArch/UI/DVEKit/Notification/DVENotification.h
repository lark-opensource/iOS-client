//
//  DVENotification.h
//  NLEEditor
//
//  Created by bytedance on 2021/8/9.
//

#import <Foundation/Foundation.h>
#import "DVENotificationAlertView.h"
#import "DVENotificationEditView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVENotification : NSObject

/// 优先注入再默认实现
+ (void)showAlertWithTitle:(NSString *)title
               description:(NSString *)description
                 leftTitle:(NSString *)leftTitle
                rightTitle:(NSString *)rightTitle
                 leftBlock:(DVEActionBlock _Nullable)leftBlock
                rightBlock:(DVEActionBlock _Nullable)rightBlock;

/// 优先注入再默认实现，closeBlock 暂时不需要对外提供注入
+ (void)showAlertWithTitle:(NSString *)title
               description:(NSString *)description
                 leftTitle:(NSString *)leftTitle
                rightTitle:(NSString *)rightTitle
                 leftBlock:(DVEActionBlock _Nullable)leftBlock
                rightBlock:(DVEActionBlock _Nullable)rightBlock
                closeBlock:(DVEActionBlock _Nullable)closeBlock;

+ (DVENotificationEditView *)showTitle:(NSString * _Nullable)title
                           editMessage:(NSString *)editMessage
                            leftAction:(NSString *)leftAction
                           rightAction:(NSString *)rightAction;

@end

NS_ASSUME_NONNULL_END

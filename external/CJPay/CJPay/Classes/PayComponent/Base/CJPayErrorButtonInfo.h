//
// Created by 张海阳 on 2019-07-01.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayErrorButtonInfo : JSONModel

@property (nonatomic, copy) NSString *page_desc;
@property (nonatomic, copy) NSString *button_desc;
@property (nonatomic, copy) NSString *button_type; // 为4时，展示错误文案提示
@property (nonatomic, copy) NSNumber *action;
@property (nonatomic, copy) NSString *left_button_desc;
@property (nonatomic, copy) NSNumber *left_button_action;
@property (nonatomic, copy) NSString *right_button_desc;
@property (nonatomic, copy) NSNumber *right_button_action;
@property (nonatomic, copy) NSString *button_status;
@property (nonatomic, copy) NSString *findPwdUrl;
@property (nonatomic, copy) NSString *mainTitle;
// 记录错误码，埋点用
@property (nonatomic, copy) NSString *code;
// 记录场景，埋点用
@property (nonatomic, copy) NSString *trackCase;

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *merchantID;

@end

NS_ASSUME_NONNULL_END

//
//  OPNoticeModel.h
//  TTMicroApp
//
//  Created by ChenMengqi on 2021/8/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, OPNoticeDisplayRule) {
    ///首次展示
    OPNoticeDisplayRuleFirstTime = 1,
    ///每次展示
    OPNoticeDisplayRuleEveryTime = 2
};

@interface OPNoticeUrlModel : NSObject

@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) BOOL has_link;


@end

@interface OPNoticeModel : NSObject

@property (nonatomic, copy) NSString *content;
///生效时间
@property (nonatomic, copy) NSString *effective_time;
///失效时间
@property (nonatomic, copy) NSString *failure_time;
///唯一id，租户管理员更新时会重新生成
@property (nonatomic, copy) NSString *uuid;

@property (nonatomic, assign) OPNoticeDisplayRule display_rule;

@property (nonatomic, strong) OPNoticeUrlModel *link;


@end

NS_ASSUME_NONNULL_END

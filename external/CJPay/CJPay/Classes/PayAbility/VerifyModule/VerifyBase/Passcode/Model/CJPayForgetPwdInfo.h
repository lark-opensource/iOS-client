//
//  CJPayForgetPwdInfo.h
//  Pods
//
//  Created by wangxiaohong on 2021/7/28.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayForgetPwdInfo : JSONModel

@property (nonatomic, copy) NSString *action;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, assign) NSInteger times;

/// 取值： next_to_tips， top_right， center(停用)
@property (nonatomic, copy) NSString *style;

@end

NS_ASSUME_NONNULL_END

//
//  CJPayOuterBaseViewController.h
//  Aweme
//
//  Created by wangxiaohong on 2022/10/11.
//

#import "CJPayFullPageBaseViewController.h"
#import "CJPayOuterPayUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayOuterBaseViewController : CJPayFullPageBaseViewController

@property (nonatomic, strong, readonly) UILabel *tipLabel;
@property (nonatomic, strong, readonly) UILabel *userNicknameLabel; // 用户昵称
@property (nonatomic, strong, readonly) UIImageView *userAvatarImageView; // 用户头像
@property (nonatomic, strong, readonly) UIView *userInfoView; //承载用户昵称和用户头像

@property (nonatomic, strong, readonly) UILabel *singleLineUserNicknameLabel; // 用户昵称
@property (nonatomic, strong, readonly) UIImageView *singleLineUserAvatarImageView; // 用户头像
@property (nonatomic, strong, readonly) UIView *singleLineUserInfoView; //承载用户昵称和用户头像

@property (nonatomic, copy) NSDictionary *schemaParams;
@property (nonatomic, copy) NSString *returnURL;

@property (nonatomic, copy, readonly) NSString *jumpBackUrlStr;

- (void)didFinishParamsCheck:(BOOL)isSuccess;

- (void)alertRequestErrorWithMsg:(NSString *)alertText clickAction:(void(^)(void))clickAction;
- (void)closeCashierDeskAndJumpBackWithResult:(CJPayDypayResultType)resultType;
    
@end

NS_ASSUME_NONNULL_END

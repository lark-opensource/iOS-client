//
//  CJPayAuthUtil.h
//  CJPaySandBox
//
//  Created by wangxiaohong on 2023/6/10.
//

#import <Foundation/Foundation.h>
#import "CJPayTrackerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CJPayAuthResultType) {
    CJPayAuthResultTypeSuccess = 0, //开户成功
    CJPayAuthResultTypeAuthed = 1, //已开户
    CJPayAuthResultTypeCancel = 2,
    CJPayAuthResultTypeFail = 3,
};

@class CJPayUserInfo;
@interface CJPayAuthUtil : NSObject

+ (void)authWithUserInfo:(CJPayUserInfo *)userInfo
                  fromVC:(UIViewController *)fromVC
           trackDelegate:(id<CJPayTrackerProtocol>)trackDelegate
              completion:(void (^)(CJPayAuthResultType resultType, NSString * _Nonnull msg, NSString * _Nonnull token, BOOL isBindCardSuccess))completion;

@end

NS_ASSUME_NONNULL_END

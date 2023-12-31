//
//  CJPayBindCardRetainUtil.h
//  CJPaySandBox
//
//  Created by wangxiaohong on 2022/12/1.
//

#import <Foundation/Foundation.h>
#import "CJPayBindCardRetainInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBindCardSetPasswordRetainInfo;
@interface CJPayBindCardRetainUtil : NSObject

//绑卡第一个页面挽留
+ (void)showRetainWithModel:(CJPayBindCardRetainInfo *)retainModel fromVC:(UIViewController *)fromVC;

@end

NS_ASSUME_NONNULL_END

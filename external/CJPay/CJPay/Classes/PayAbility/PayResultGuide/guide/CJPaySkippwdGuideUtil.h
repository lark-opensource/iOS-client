//
//  CJPaySkippwdGuideUtil.h
//  Pods
//
//  Created by 利国卿 on 2022/4/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayBaseVerifyManager;
@class CJPayBDOrderResultResponse;

@interface CJPaySkippwdGuideUtil : NSObject

//判断是否需要展示免密相关引导
+ (BOOL)shouldShowGuidePageWithResultResponse:(CJPayBDOrderResultResponse *)resultResponse;
//跳转免密引导页面
+ (void)showGuidePageVCWithVerifyManager:(CJPayBaseVerifyManager *)verifyManager
               pushAnimated:(BOOL)animated
            completionBlock:(void (^)(void))completionBlock;

@end

NS_ASSUME_NONNULL_END

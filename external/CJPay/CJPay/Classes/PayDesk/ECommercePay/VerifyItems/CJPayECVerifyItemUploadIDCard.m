//
//  CJPayECVerifyItemUploadIDCard.m
//  Pods
//
//  Created by 尚怀军 on 2021/3/19.
//

#import "CJPayECVerifyItemUploadIDCard.h"
#import "CJPaySDKMacro.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayRetainUtil.h"
#import "CJPayBizWebViewController.h"

@implementation CJPayECVerifyItemUploadIDCard

- (void)startUploadIDCardWithConfirmResponse:(CJPayOrderConfirmResponse *)response {
    if (!Check_ValidString(response.jumpUrl)) {
        CJPayLogInfo(@"jumpurl empty, code %@", response.code);
        return;
    }
    // 拉起h5上传身份证的页面
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params cj_setObject:@"120" forKey:@"service"];
    [params cj_setObject:@"sdk" forKey:@"source"];
    
    // 告知前端是否需要展示挽留
    CJPayRetainUtilModel *retainUtilModel = [self buildRetainUtilModel];
    NSString *needRetain = ([CJPayRetainUtil needShowRetainPage:retainUtilModel] && retainUtilModel.retainInfo.needVerifyRetain) ? @"1" : @"0";
    [params cj_setObject:needRetain forKey:@"cj_need_retain"];
    
    @CJWeakify(self)
    CJPayBizWebViewController *webvc = [[CJPayWebViewUtil sharedUtil] buildWebViewControllerWithUrl:response.jumpUrl fromVC:[self.manager.homePageVC topVC]
                                                                                             params:params
                                                                                  nativeStyleParams:@{}
                                                                                      closeCallBack:^(id  _Nonnull data) {
        @CJStrongify(self)
        [self handleWebCloseCallBackWithData:data];
    }];
    
    [self.manager.homePageVC push:webvc animated:YES];
}

@end

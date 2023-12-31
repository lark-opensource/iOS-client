//
//  CJPayABTestRegister.m
//  Pods
//
//  Created by renqiang on 2021/6/1.
//

#import "CJPayABTestRegister.h"
#import "CJPayABTestManager.h"
#import "CJPayABTestNewPluginImpl.h"
#import <BDCommonABTestSDK/BDCommonABTestManager.h>


@implementation CJPayABTestRegister

+ (void)registerExperiment {
    BDCommonABSDKExtraInitMethod
    
    // 注册测试实验key

    // 银行卡管理 - 独立绑卡营销实验
    [CJPayRegisterABTest registerABTestWithKey:CJPayABBindcardPromotion defaultValue:@"default"];
    
    // 绑卡专项接入静默活体
    [CJPayRegisterABTest registerABTestWithKey:CJPayABBindcardFaceRecog defaultValue:@"liveproduct_b"];

    // 实名授权实验 0:线上 1:降噪样式 2:静默流程
    [CJPayRegisterABTest registerABTestWithKey:CJPayABBizAuth defaultValue:@"0"];
        
    // 进入绑卡首页接口合并优化，0：线上，1：接口合并
    [CJPayRegisterABTest registerABTestWithKey:CJPayABBindcardRequestCombine defaultValue:@"0"];

    //云闪付绑卡上固定入口,0:线上无闪付，1：实验有云闪付
    [CJPayRegisterABTest registerABTestWithKey:CJPayABUnionCard defaultValue:@"0"];
    
    //未实名用户绑卡接口优化，0：线上，1：优化后
    [CJPayRegisterABTest registerABTestWithKey:CJPayABBindCardNotRealnameApi defaultValue:@"0"];
    
    //本地生活生物支付确认支付页，0：线上，1：去掉支付页
    [CJPayRegisterABTest registerABTestWithKey:CJPayABFontpPayBioConfirmPage defaultValue:@"0"];
    
    //OCR对焦曝光优化
    [CJPayRegisterABTest registerABTestWithKey:CJPayABOCRAutoExpose defaultValue:@"0"];
    
    //OCR本地VisionKit识别改造
    [CJPayRegisterABTest registerABTestWithKey:CJPayABLocalOCR defaultValue:@""];
    
    [CJPayRegisterABTest registerABTestWithKey:CJPayABIsDouPayProcess defaultValue:@"0"];

    [CJPayRegisterABTest registerABTestWithKey:CJPayEnableLaunchOptimize defaultValue:@"0"];
    
    [CJPayRegisterABTest registerABTestWithKey:CJPaySyncChannelsConfig defaultValue:@""];
}

@end

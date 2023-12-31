//
//  BytedCertManager+MetaSec.m
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/6/28.
//

#import "BytedCertManager+MetaSec.h"
#import "BytedCertManager+Private.h"
#import <BDAssert/BDAssert.h>
#import <MetaSecML/MSManager.h>


@implementation BytedCertManager (MetaSec)
+ (void)metaSecReportForBeforCameraStart {
    return;
}

+ (void)metaSecReportForOnCameraRunning {
    return;
}

+ (MSManagerML *)appMSManagerML {
    MSManagerML *msManager = [MSManagerML get:[BytedCertManager aid]];
    if (!msManager) {
        BDAssert(NO, @"通过appid获取MSMangerML失败");
    }
    return msManager;
}
@end

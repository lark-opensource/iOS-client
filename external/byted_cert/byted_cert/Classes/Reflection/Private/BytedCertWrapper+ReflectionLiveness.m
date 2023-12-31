//
//  BytedCertWrapper+ReflectionLiveness.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/17.
//

#import "BytedCertWrapper+ReflectionLiveness.h"
#import "BytedCertWrapper+Download.h"
#import "BDCTStringConst.h"
#import "BytedCertDefine.h"


@implementation BytedCertWrapper (ReflectionLiveness)

+ (BOOL)isReflectionLivenessModelReady {
    return [self reflectionLivenessModelStatus] == 0;
}

+ (int)reflectionLivenessModelStatus {
    return [self.sharedInstance checkChannelAvailable:bdct_reflection_model_pre() channel:BytedCertParamTargetReflection];
}

@end

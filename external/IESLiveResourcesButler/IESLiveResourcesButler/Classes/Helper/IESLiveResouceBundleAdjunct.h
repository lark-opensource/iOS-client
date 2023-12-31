//
//  IESLiveResouceBundleAdjunct.h
//  Pods
//
//  Created by Zeus on 2017/2/9.
//
//  IESLiveResouceBundleAdjunct是一个可以挂载在主资源包上的补丁包
//  可以通过下载补丁包更新本地的资源包
//

#import "IESLiveResouceBundle+Hooker.h"

@interface IESLiveResouceBundleAdjunct : IESLiveResouceBundle <IESLiveResouceBundleHookerProtocol>

@end

@interface IESLiveResouceBundle (Adjunct)

- (void)applyAdjunct:(IESLiveResouceBundleAdjunct *)adjunct;

+ (void)applyAdjunct:(IESLiveResouceBundleAdjunct *)adjunct forCategory:(NSString *)category;

@end

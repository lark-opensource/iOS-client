//
//  ACCResourceUnion.m
//  CameraClient
//
//  Created by Liu Deping on 2019/11/1.
//

#import "ACCResourceUnion.h"
#import <IESLiveResourcesButler/IESLiveResouceBundle.h>
#import "ACCResourceBundleProtocol.h"
#import "ACCServiceLocator.h"
#import "ACCMacros.h"

static IESLiveResouceBundle *resourceBundle;

@implementation ACCResourceUnion

+ (IESLiveResouceBundle *)cameraResourceBundle
{

    if (!resourceBundle) {
        let bundleService = IESAutoInline(ACCBaseServiceProvider(), ACCResourceBundleProtocol);
        NSString *bundleName = [[bundleService currentResourceBundleName] stringByAppendingPathExtension:@"bundle"];
        if (![resourceBundle.bundleName isEqualToString:bundleName]) {
            resourceBundle = [IESLiveResouceBundle assetBundleWithBundleName:bundleName];
        }
    }
    
    NSAssert(resourceBundle != nil, @"CameraClient resource bundle is not set");
    
    return resourceBundle;
}

@end

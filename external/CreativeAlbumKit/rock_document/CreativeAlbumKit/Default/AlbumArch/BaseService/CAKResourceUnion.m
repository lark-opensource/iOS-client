//
//  CAKResourceUnion.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/8.
//

#import "CAKResourceUnion.h"
#import <CreativeKit/ACCMacros.h>
#import "CAKServiceLocator.h"
#import "CAKResourceBundleProtocol.h"
#import <IESLiveResourcesButler/IESLiveResouceBundle.h>

static IESLiveResouceBundle *resourceBundle;

@implementation CAKResourceUnion

+ (IESLiveResouceBundle *)albumResourceBundle
{
    if (!resourceBundle) {
        let bundleService = IESAutoInline(CAKBaseServiceProvider(), CAKResourceBundleProtocol);
        NSString *bundleName = [[bundleService currentResourceBundleName] stringByAppendingPathExtension:@"bundle"];
        if (![resourceBundle.bundleName isEqualToString:bundleName]) {
            resourceBundle = [IESLiveResouceBundle assetBundleWithBundleName:bundleName];
        }
    }
    
    NSAssert(resourceBundle != nil, @"CreativeAlbumKit resource bundle is not set");
    
    return resourceBundle;
}

@end

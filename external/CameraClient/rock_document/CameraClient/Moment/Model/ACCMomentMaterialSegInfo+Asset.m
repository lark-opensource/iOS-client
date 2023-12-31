//
//  ACCMomentMaterialSegInfo+Asset.m
//  AWEStudio-Pods-Aweme
//
//  Created by Chen Long on 2020/6/8.
//

#import "ACCMomentMaterialSegInfo+Asset.h"

#import <objc/runtime.h>


@implementation ACCMomentMaterialSegInfo (Asset)

- (AWEAssetModel *)assetModel
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setAssetModel:(AWEAssetModel *)assetModel
{
    objc_setAssociatedObject(self, @selector(assetModel), assetModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

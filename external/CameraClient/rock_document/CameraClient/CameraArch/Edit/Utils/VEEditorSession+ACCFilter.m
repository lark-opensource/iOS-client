//
//  VEEditorSession+ACCFilter.m
//  CameraClient
//
//  Created by haoyipeng on 2020/8/19.
//

#import "VEEditorSession+ACCFilter.h"
#import <TTVideoEditor/VEEditorSession+Effect.h>
#import <CreationKitArch/IESEffectModel+ComposerFilter.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <objc/runtime.h>

@implementation VEEditorSession (ACCFilter)

- (void)acc_applyFilterEffect:(IESEffectModel *)effect
                    intensity:(float)intensity
                    videoData:(HTSVideoData *)videoData {
    if (effect) {
        if (effect.isComposerFilter) {
            [self replaceToComposerFilter:effect intensity:intensity videoData:videoData];
        } else {
            NSString *path = [effect filePathForCameraPosition:AVCaptureDevicePositionFront] ?: @"";
            [self acc_applyFilterEffectWithPath:path intensity:intensity];
        }
    } else {
        [self acc_removeAllFilterWithVideoData:videoData];
    }
}

- (BOOL)acc_switchColorLeftFilter:(IESEffectModel *)leftFilter
                      rightFilter:(IESEffectModel *)rightFilter
                       inPosition:(float)position
                  inLeftIntensity:(float)leftIntensity
                 inRightIntensity:(float)rightIntensity
                        videoData:(HTSVideoData *)videoData {
    
    if (leftFilter.isComposerFilter || rightFilter.isComposerFilter) {
        NSString *leftPath = leftFilter.resourcePath ?: @"";
        NSString *rightPath = rightFilter.resourcePath ?: @"";
        if (position == 1) {
            [self updateMutipleComposerNodes:@[leftPath, rightPath]
                                               keys:@[kLeftSlidePosition, kRightSlidePosition]
                                             values:@[@(position), @(position)]];
            [self replaceToComposerFilter:leftFilter intensity:leftIntensity videoData:videoData];
        } else if (position == 0) {
            [self updateMutipleComposerNodes:@[leftPath, rightPath]
                                               keys:@[kLeftSlidePosition, kRightSlidePosition]
                                             values:@[@(position), @(position)]];
            [self replaceToComposerFilter:rightFilter intensity:rightIntensity videoData:videoData];
        } else if (position < 1) {
            if (![self hadAppendFilter:leftFilter]) {
                [self acc_appendFilterEffect:leftFilter
                                    position:position
                                  isLeftSide:YES];
                [self updateComposerNode:leftFilter.resourcePath
                                            key:leftFilter.filterConfigItem.tag
                                          value:leftIntensity];
            }
            if (![self hadAppendFilter:rightFilter]) {
                [self acc_appendFilterEffect:rightFilter
                                    position:(1.0 - position)
                                  isLeftSide:NO];
                [self updateComposerNode:rightFilter.resourcePath
                                            key:rightFilter.filterConfigItem.tag
                                          value:rightIntensity];
            }
            [self updateMutipleComposerNodes:@[leftPath, rightPath]
                                               keys:@[kLeftSlidePosition, kRightSlidePosition]
                                             values:@[@(position), @(position)]];
        }
    } else {
        NSString *leftPath = [leftFilter filePathForCameraPosition:AVCaptureDevicePositionFront] ?: @"";
        NSString *rightPath = [rightFilter filePathForCameraPosition:AVCaptureDevicePositionFront] ?: @"";
        
        [self switchColorFilterIntensity:leftPath
                            inFilterPath:rightPath
                              inPosition:position
                         inLeftIntensity:leftIntensity
                        inRightIntensity:rightIntensity];
    }
    return YES;
}

- (void)acc_appendFilterEffect:(IESEffectModel *)effect
                      position:(float)position
                    isLeftSide:(BOOL)isLeftSide {
    if (effect.isComposerFilter) {
        NSArray<VEComposerInfo *> *nodes = [effect appendedNodeInfosWithPosition:position
                                                                      isLeftSide:isLeftSide];
        
        [self appendComposerNodesWithTags:nodes];
        self.appendedFilterDic[effect] = @(1);
    }
}


- (void)replaceToComposerFilter:(IESEffectModel *)effect
                      intensity:(float)intensity
                      videoData:(HTSVideoData *)videoData {
    if (!effect) {
        return;
    }
    NSMutableArray *nodes = [@[] mutableCopy];
    for (IESEffectModel *appendedEffect in [self.appendedFilterDic allKeys]) {
        if (![appendedEffect.effectIdentifier isEqualToString:effect.effectIdentifier]) {
            [nodes addObjectsFromArray:[appendedEffect nodeInfos]];
        }
    }
    
    [self replaceComposerNodesWithNewTag:[effect nodeInfosWithIntensity:intensity]
                                     old:nodes];
    self.appendedFilterDic = [@{effect: @(1)} mutableCopy];
    [self acc_dumpVideoData:videoData];
}

- (BOOL)hadAppendFilter:(IESEffectModel *)effect {
    if (effect) {
        return self.appendedFilterDic[effect] != nil;
    } else {
        return NO;
    }
}

- (void)acc_appendFilterEffect:(IESEffectModel *)effect
                     intensity:(float)intensity
                     videoData:(HTSVideoData *)videoData {
    if (effect.isComposerFilter) {
        NSArray<VEComposerInfo *> *nodes = [effect nodeInfosWithIntensity:intensity];
        
        [self appendComposerNodesWithTags:nodes];
        [self acc_dumpVideoData:videoData];
    }
}

- (void)acc_removeAllFilterWithVideoData:(HTSVideoData *)videoData {
    if ([self.appendedFilterDic allKeys].count > 0) {
        for (IESEffectModel *appendedEffect in [self.appendedFilterDic allKeys]) {
            [self acc_removeFilterEffect:appendedEffect videoData:videoData];
        }
        
        self.appendedFilterDic = [NSMutableDictionary dictionary];
    }
    [self applyFilterWithPath:@""];
}

- (void)acc_removeFilterEffect:(IESEffectModel *)effect videoData:(HTSVideoData *)videoData {
    if (effect.isComposerFilter) {
        [self acc_removeComposerFilterEffect:effect videoData:videoData];
    } else {
        [self applyFilterWithPath:@""];
    }
}

- (void)acc_removeComposerFilterEffect:(IESEffectModel *)effect videoData:(HTSVideoData *)videoData {
    if (effect.isComposerFilter) {
        NSArray<VEComposerInfo *> *nodes = [effect nodeInfos];
        [self removeComposerNodesWithTags:nodes];
        [self.appendedFilterDic removeObjectForKey:effect];
        
        [self acc_dumpVideoData:videoData];
    }
}

- (void)acc_applyFilterEffect:(IESEffectModel *)effect videoData:(HTSVideoData *)videoData {
    [self acc_applyFilterEffect:effect intensity:1.f videoData:videoData];
}

// 获得滤镜强度
- (float)acc_filterEffectOriginIndensity:(nullable IESEffectModel *)effect {
    if (effect.isComposerFilter) {
        return effect.filterConfigItem.defaultIntensity;
    } else {
        NSString *path = [effect filePathForCameraPosition:AVCaptureDevicePositionFront] ?: @"";
        if (path == nil) {
            return 0;
        }
    
        float indensity;
        BOOL success = [self getColorFilterIntensity:path outIntensity:&indensity];
        if (success) {
            return indensity;
        } else {
            return 0;
        }
    }
}

// 调整滤镜强度
- (void)acc_applyFilterEffectWithPath:(NSString *)path intensity:(float)intensity
{
    if (path == nil || path.length == 0) {
        path = @"";
        [self applyFilterWithPath:path];
    } else {
       [self setColorFilterIntensity:path inIntensity:intensity];
    }
}

- (NSMutableDictionary *)appendedFilterDic {
    id cached = objc_getAssociatedObject(self, @selector(appendedFilterDic));
    if (!cached) {
        NSMutableDictionary *dic = [@{} mutableCopy];
        [self setAppendedFilterDic:dic];
        return dic;
    } else {
        return cached;
    }
}

- (void)setAppendedFilterDic:(NSMutableDictionary *)appendedFilterDic {
    objc_setAssociatedObject(self, @selector(appendedFilterDic), appendedFilterDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)acc_dumpVideoData:(HTSVideoData *)videoData
{
    [self dumpComposerNodes:videoData];
}

@end

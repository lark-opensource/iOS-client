//
//  ACCFilterWrapper.m
//  Pods
//
//  Created by liyingpeng on 2020/5/28.
//

#import "ACCFilterWrapper.h"
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitArch/IESEffectModel+ComposerFilter.h>
#import <CreationKitRTProtocol/ACCCameraDefine.h>
#import "ACCCameraFactory.h"
#import <CreativeKit/ACCMacros.h>
#import <TTVideoEditor/VERecorder.h>

@interface ACCFilterWrapper () <ACCCameraBuildListener>

@property (nonatomic, weak) id<VERecorderPublicProtocol> camera;
@property (nonatomic, strong) NSMutableDictionary<IESEffectModel *, NSNumber *> *appendedFilterDic;
@end

@implementation ACCFilterWrapper

@synthesize camera = _camera;

- (void)setCameraProvider:(id<ACCCameraProvider>)cameraProvider {
    [cameraProvider addCameraListener:self];
}

#pragma mark - ACCCameraBuildListener

- (void)onCameraInit:(id<VERecorderPublicProtocol>)camera {
    self.camera = camera;
}

#pragma mark - setter & getter
- (void)setCamera:(id<VERecorderPublicProtocol>)camera {
    _camera = camera;
    _appendedFilterDic = [@{} mutableCopy];
}

- (void)acc_applyFilterEffectWithPath:(NSString *)path
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (path == nil) {
        path = @"";
    }
    
    [self.camera applyEffect:path type:IESEffectFilter];
}

- (void)acc_applyFilterEffectWithPath:(NSString *)path intensity:(float)intensity
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (path == nil || path.length == 0) {
        path = @"";
        [self acc_applyFilterEffectWithPath:path];
    } else {
        [self.camera setColorFilterIntensity:path inIntensity:intensity];
    }
}

- (float)acc_filterEffectOriginIndensity:(NSString *)path
{
    if (path == nil) {
        return 0;
    }
    
    float indensity;
    BOOL success = [self.camera getColorFilterIntensity:path outIntensity:&indensity];
    if (success) {
        return indensity;
    } else {
        return 0;
    }
}

- (BOOL)switchColorFilterIntensity:(NSString *)leftFilterPath
                      inFilterPath:(NSString *)rightFilterPath
                        inPosition:(float)position
                   inLeftIntensity:(float)leftIntensity
                  inRightIntensity:(float)rightIntensity
{
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    return [self.camera switchColorFilterIntensity:leftFilterPath
                                      inFilterPath:rightFilterPath
                                        inPosition:position
                                   inLeftIntensity:leftIntensity
                                  inRightIntensity:rightIntensity];
}

- (void)acc_applyFilterEffect:(IESEffectModel *)effect
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (effect) {
        if (effect.isComposerFilter) {
            [self acc_applyFilterEffect:effect intensity:1.f];
        } else {
            NSString *path = [effect filePathForCameraPosition:self.camera.currentCameraPosition] ?: @"";
            [self acc_applyFilterEffectWithPath:path];
        }
    } else {
        [self acc_removeAllFilter];
    }
}

- (void)acc_removeFilterEffect:(IESEffectModel *)effect
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (effect.isComposerFilter) {
        [self acc_removeComposerFilterEffect:effect];
    } else {
        [self acc_applyFilterEffectWithPath:@""];
    }
}

- (void)acc_removeAllFilter
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    for (IESEffectModel *appendedEffect in [self.appendedFilterDic allKeys]) {
        [self acc_removeFilterEffect:appendedEffect];
    }
    
    self.appendedFilterDic = [NSMutableDictionary dictionary];
    [self acc_applyFilterEffectWithPath:@""];
}

- (void)acc_removeComposerFilterEffect:(IESEffectModel *)effect
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (effect.isComposerFilter) {
        NSArray<VEComposerInfo *> *nodes = [effect nodeInfos];
        [self.camera removeComposerNodesWithTags:nodes];
        [self.appendedFilterDic removeObjectForKey:effect];
    }
}

- (void)acc_applyFilterEffect:(IESEffectModel *)effect
                    intensity:(float)intensity
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (effect) {
        if (effect.isComposerFilter) {
            [self replaceToComposerFilter:effect intensity:intensity];
        } else {
            NSString *path = [effect filePathForCameraPosition:self.camera.currentCameraPosition] ?: @"";
            [self acc_applyFilterEffectWithPath:path intensity:intensity];
        }
    } else {
        [self acc_removeAllFilter];
    }
}

- (void)replaceToComposerFilter:(IESEffectModel *)effect
                      intensity:(float)intensity {
    if (!effect) {
        return;
    }
    if (![self p_verifyCameraContext]) {
        return;
    }
    NSMutableArray *nodes = [@[] mutableCopy];
    for (IESEffectModel *appendedEffect in [self.appendedFilterDic allKeys]) {
        if (![appendedEffect.effectIdentifier isEqualToString:effect.effectIdentifier]) {
            [nodes addObjectsFromArray:[appendedEffect nodeInfos]];
        }
    }
    
    [self.camera replaceComposerNodesWithNewTag:[effect nodeInfosWithIntensity:intensity]
                                            old:nodes];
    self.appendedFilterDic = [@{effect: @(1)} mutableCopy];
}

- (BOOL)hadAppendFilter:(IESEffectModel *)effect {
    if (effect) {
        return self.appendedFilterDic[effect] != nil;
    } else {
        return NO;
    }
}

- (void)acc_appendFilterEffect:(IESEffectModel *)effect
                      position:(float)position
                    isLeftSide:(BOOL)isLeftSide
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if (effect.isComposerFilter) {
        NSArray<VEComposerInfo *> *nodes = [effect appendedNodeInfosWithPosition:position isLeftSide:isLeftSide];
        
        [self.camera appendComposerNodesWithTags:nodes];
        self.appendedFilterDic[effect] = @(1);
    }
}

- (BOOL)switchColorLeftFilter:(IESEffectModel *)leftFilter
                  rightFilter:(IESEffectModel *)rightFilter
                   inPosition:(float)position
              inLeftIntensity:(float)leftIntensity
             inRightIntensity:(float)rightIntensity
{
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    
    if (leftFilter.isComposerFilter || rightFilter.isComposerFilter) {
        NSString *leftPath = leftFilter.resourcePath ?: @"";
        NSString *rightPath = rightFilter.resourcePath ?: @"";
        if (position == 1) {
            [self.camera updateMutipleComposerNodes:@[leftPath, rightPath]
                                               keys:@[kLeftSlidePosition, kRightSlidePosition]
                                             values:@[@(position), @(position)]];
            [self replaceToComposerFilter:leftFilter intensity:leftIntensity];
        } else if (position == 0) {
            [self.camera updateMutipleComposerNodes:@[leftPath, rightPath]
                                               keys:@[kLeftSlidePosition, kRightSlidePosition]
                                             values:@[@(position), @(position)]];
            [self replaceToComposerFilter:rightFilter intensity:rightIntensity];
        } else if (position < 1) {
            if (![self hadAppendFilter:leftFilter]) {
                [self acc_appendFilterEffect:leftFilter
                                    position:position
                                  isLeftSide:YES];
                [self.camera updateComposerNode:leftFilter.resourcePath
                                            key:leftFilter.filterConfigItem.tag
                                          value:leftIntensity];
            }
            if (![self hadAppendFilter:rightFilter]) {
                [self acc_appendFilterEffect:rightFilter
                                    position:(1.0 - position)
                                  isLeftSide:NO];
                [self.camera updateComposerNode:rightFilter.resourcePath
                                            key:rightFilter.filterConfigItem.tag
                                          value:rightIntensity];
            }
            [self.camera updateMutipleComposerNodes:@[leftPath, rightPath]
                                               keys:@[kLeftSlidePosition, kRightSlidePosition]
                                             values:@[@(position), @(position)]];
        }
        
    } else {
        NSString *leftPath = [leftFilter filePathForCameraPosition:self.camera.currentCameraPosition] ?: @"";
        NSString *rightPath = [rightFilter filePathForCameraPosition:self.camera.currentCameraPosition] ?: @"";
        
        [self switchColorFilterIntensity:leftPath
                            inFilterPath:rightPath
                              inPosition:position
                         inLeftIntensity:leftIntensity
                        inRightIntensity:rightIntensity];
    }
    return YES;
}

#pragma mark - Private Method

- (BOOL)p_verifyCameraContext
{
    if (![self.camera cameraContext]) {
        return YES;
    }
    BOOL result = [self.camera cameraContext] == ACCCameraVideoRecordContext;
    if (!result) {
        ACC_LogError(@"Camera operation error, context not equal to ACCCameraVideoRecordContext point");
    }
    return result;
}

@end

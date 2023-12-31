//
//  ACCNLEEditFilterWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by HuangHongsen on 2021/2/7.
//

#import "ACCNLEEditFilterWrapper.h"
#import <NLEPlatform/NLEInterface.h>
#import <NLEPlatform/NLESegmentFilter+iOS.h>
#import <NLEPlatform/NLESegmentComposerFilter+iOS.h>
#import <NLEPlatform/NLEFilter+iOS.h>
#import <NLEPlatform/NLETrack+iOS.h>
#import "NLEModel_OC+Extension.h"
#import <CreationKitArch/IESEffectModel+ComposerFilter.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import "VEEditorSession+ACCFilter.h"
#import <CreationKitArch/IESEffectModel+ComposerFilter.h>
#import "NLEResourceAV_OC+Extension.h"
#import "NLEEditor_OC+Extension.h"

static NSString * const ACCNLEEditFilterKey = @"ACCNLEEditFilterKey";

@interface ACCNLEEditFilterWrapper ()<ACCEditBuildListener>

@property (nonatomic, weak) NLEInterface_OC *nle;
@property (nonatomic, weak) NLETrackSlot_OC *filterSlot;

@property (nonatomic, strong) NSMutableArray *appendedFilters;

@end

@implementation ACCNLEEditFilterWrapper

- (void)setEditSessionProvider:(nonnull id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

- (void)applyFilterEffect:(nullable IESEffectModel *)effect
{
    [self applyFilterEffect:effect intensity:1.f];
}

- (void)applyFilterEffect:(nullable IESEffectModel *)effect
                intensity:(float)intensity
{
    [self applyNLEFilterEffect:effect intensity:intensity];
}

- (float)filterEffectOriginIndensity:(nullable IESEffectModel *)effect {
    if (effect.isComposerFilter) {
        return effect.filterConfigItem.defaultIntensity;
    } else {
        NSString *path = [effect filePathForCameraPosition:AVCaptureDevicePositionFront] ?: @"";
        if (path.length == 0) {
            return 0;
        }

        float indensity;
        BOOL success = [self.nle getColorFilterIntensity:path outIntensity:&indensity];
        if (success) {
            return indensity;
        } else {
            return 0;
        }
    }
    return 0.f;
}

- (BOOL)switchColorLeftFilter:(nonnull IESEffectModel *)leftFilter
                  rightFilter:(nonnull IESEffectModel *)rightFilter
                   inPosition:(float)position {
    return [self switchColorLeftFilter:leftFilter
                           rightFilter:rightFilter
                            inPosition:position
                       inLeftIntensity:1.f
                      inRightIntensity:1.f];
}

// composer filter
- (BOOL)switchColorLeftFilter:(nonnull IESEffectModel *)leftFilter
                  rightFilter:(nonnull IESEffectModel *)rightFilter
                   inPosition:(float)position
              inLeftIntensity:(float)leftIntensity
             inRightIntensity:(float)rightIntensity {
    BOOL result = NO;
    if (leftFilter.isComposerFilter || rightFilter.isComposerFilter) {
        NSString *leftPath = leftFilter.resourcePath ?: @"";
        NSString *rightPath = rightFilter.resourcePath ?: @"";
        if (position == 1) {
            [self.nle updateMutipleComposerNodes:@[leftPath, rightPath]
                                               keys:@[kLeftSlidePosition, kRightSlidePosition]
                                             values:@[@(position), @(position)]];
            [self replaceToComposerFilter:leftFilter intensity:leftIntensity];
        } else if (position == 0) {
            [self.nle updateMutipleComposerNodes:@[leftPath, rightPath]
                                               keys:@[kLeftSlidePosition, kRightSlidePosition]
                                             values:@[@(position), @(position)]];
            [self replaceToComposerFilter:rightFilter intensity:rightIntensity];
        } else if (position < 1) {
            if (![self hadAppendFilter:leftFilter]) {
                [self appendFilter:leftFilter
                          position:position
                      isLeftFilter:YES];
                [self.nle updateComposerNode:leftFilter.resourcePath
                                            key:leftFilter.filterConfigItem.tag
                                          value:leftIntensity];
            }
            if (![self hadAppendFilter:rightFilter]) {
                [self appendFilter:rightFilter
                          position:(1.0 - position)
                      isLeftFilter:NO];
                [self.nle updateComposerNode:rightFilter.resourcePath
                                            key:rightFilter.filterConfigItem.tag
                                          value:rightIntensity];
            }
            [self.nle updateMutipleComposerNodes:@[leftPath, rightPath]
                                               keys:@[kLeftSlidePosition, kRightSlidePosition]
                                             values:@[@(position), @(position)]];
        }
    } else {
        NSString *leftPath = [leftFilter filePathForCameraPosition:AVCaptureDevicePositionFront] ?: @"";
        NSString *rightPath = [rightFilter filePathForCameraPosition:AVCaptureDevicePositionFront] ?: @"";
        result = [self switchColorFilterIntensity:leftPath
                                   inFilterPath:rightPath
                                     inPosition:position
                                inLeftIntensity:leftIntensity
                               inRightIntensity:rightIntensity];
    }
    
    if (position == 1) {
        [self applyNLEFilterEffect:leftFilter intensity:leftIntensity];
    } else if (position == 0) {
        [self applyNLEFilterEffect:rightFilter intensity:rightIntensity];
    }
    
    return result;
}

// normal filter
- (BOOL)switchColorFilterIntensity:(NSString *)leftFilterPath
                      inFilterPath:(NSString *)rightFilterPath
                        inPosition:(float)position
                   inLeftIntensity:(float)leftIntensity
                  inRightIntensity:(float)rightIntensity {
    return
    [self.nle switchColorFilterIntensity:leftFilterPath
                            inFilterPath:rightFilterPath
                              inPosition:position
                         inLeftIntensity:leftIntensity
                        inRightIntensity:rightIntensity];
}

#pragma mark - ACCEditBuildListener
- (void)onEditSessionInit:(ACCEditSessionWrapper *)editorSession {}

- (void)onNLEEditorInit:(NLEInterface_OC *)editor {
    self.nle = editor;
}

#pragma mark - Private helper

/// 删除所有主动添加的滤镜，这里的滤镜可能会存在多个
- (void)p_removeFilters
{
    NSArray <NLETrack_OC *> *tracks = [[self.nle.editor getModel] tracksWithType:NLETrackFILTER];
    for (NLETrack_OC *track in tracks) {
        NSString *value = [track getExtraForKey:ACCNLEEditFilterKey];
        if (value.length > 0) {
            [[self.nle.editor getModel] removeTrack:track];
        }
    }
    [self.appendedFilters removeAllObjects];
}

- (void)removeOldFilterIfNeed:(IESEffectModel *)effect
{
    // 如果第一次为nil，获取存在的filter slot，强制删除，刷新。
    // MV模式恢复草稿时，NLE不会执行diff恢复逻辑，而是直接恢复video data
    // 导致没有恢复滤镜成功，滤镜不会保存到video data 的本地缓存数据中
    BOOL forceDelete = NO;
    if (!self.filterSlot) {
        // get filter slot from nle model
        self.filterSlot = [self getExistFilterSlot:effect];
        forceDelete = YES;
    }
    
    if (!self.filterSlot) {
        return;
    }
    
    // remove filter track if new add effect type not equal to nle model type
    NLEResourceNode_OC *resourceNode = [self.filterSlot.segment getResNode];
    BOOL isComposerFilter = effect.isComposerFilter;
    BOOL isComposerSlot = resourceNode.resourceType == NLEResourceTypeComposer;
    
    if (forceDelete
        || isComposerFilter != isComposerSlot
        || ![effect.resourcePath isEqualToString:[resourceNode acc_path]]) {
        [self p_removeFilters];
        self.filterSlot = nil;
    }
}

- (void)addNormalFilter:(IESEffectModel *)effect intensity:(float)intensity
{
    NLEResourceNode_OC *filterResource = [[NLEResourceNode_OC alloc] init];
    [filterResource acc_setGlobalResouceWithPath:effect.resourcePath];
    filterResource.resourceId = effect.resourceId;
    filterResource.resourceType = NLEResourceTypeFilter;

    NLESegmentFilter_OC *filterSegment = [[NLESegmentFilter_OC alloc] init];
    [filterSegment setEffectSDKFilter:filterResource];
    filterSegment.intensity = intensity;
    filterSegment.filterName = effect.effectName;

    NLETrack_OC *track = [[NLETrack_OC alloc] init];
    [track setExtra:@"1" forKey:ACCNLEEditFilterKey];
    NLETrackSlot_OC *slot = [[NLETrackSlot_OC alloc] init];
    slot.segment = filterSegment;
    [track addSlot:slot];
    [[self.nle.editor getModel] addTrack:track];
    
    self.filterSlot = slot;
}

- (void)addComposerFilter:(IESEffectModel *)effect intensity:(float)intensity
{
    NLEResourceNode_OC *filterResource = [[NLEResourceNode_OC alloc] init];
    [filterResource acc_setGlobalResouceWithPath:effect.resourcePath];
    filterResource.resourceId = effect.resourceId;
    filterResource.resourceType = NLEResourceTypeComposer;

    NLESegmentComposerFilter_OC *filterSegment = [[NLESegmentComposerFilter_OC alloc] init];
    [filterSegment setEffectSDKFilter:filterResource];
    filterSegment.intensity = intensity;
    filterSegment.filterName = effect.effectName;
    if (effect.filterConfigItem.tag) {
        filterSegment.effectTags = @{effect.filterConfigItem.tag : @(intensity)};
    }

    NLETrack_OC *track = [[NLETrack_OC alloc] init];
    [track setExtra:@"1" forKey:ACCNLEEditFilterKey];
    NLETrackSlot_OC *slot = [[NLETrackSlot_OC alloc] init];
    slot.segment = filterSegment;
    [track addSlot:slot];
    [[self.nle.editor getModel] addTrack:track];
    
    self.filterSlot = slot;
}

- (nullable NLETrackSlot_OC *)getExistFilterSlot:(IESEffectModel *)effect
{
    NSArray <NLETrack_OC *> *tracks = [[self.nle.editor getModel] tracksWithType:NLETrackFILTER];
    for (NLETrack_OC *track in tracks) {
        NSString *value = [track getExtraForKey:ACCNLEEditFilterKey];
        if (value.length > 0) {
            return track.slots.firstObject;
        }
    }
    
    return nil;
}

- (void)applyNLEFilterEffect:(nullable IESEffectModel *)effect
                   intensity:(float)intensity
{
    if (effect) {
        [self removeOldFilterIfNeed:effect];
        
        if (effect.isComposerFilter) {
            if (!self.filterSlot) {
                // create a new one
                [self addComposerFilter:effect intensity:intensity];
            }
            
            // update composer filter
            if ([self.filterSlot.segment isKindOfClass:[NLESegmentComposerFilter_OC class]]) {
                NLESegmentComposerFilter_OC *segmentFilter = (NLESegmentComposerFilter_OC *)self.filterSlot.segment;
                segmentFilter.intensity = intensity;
                [segmentFilter.effectSDKFilter acc_setGlobalResouceWithPath:effect.resourcePath];
                segmentFilter.effectSDKFilter.resourceFile = effect.resourcePath;
                if (effect.filterConfigItem.tag) {
                    segmentFilter.effectTags = @{effect.filterConfigItem.tag : @(intensity)};
                }
                segmentFilter.effectExtra = effect.extra;
            }
            [self.nle.editor acc_commitAndRender:nil];
        } else {
            if (!self.filterSlot) {
                // create a new one
                [self addNormalFilter:effect intensity:intensity];
            }
            
            // update normal filter
            if ([self.filterSlot.segment isKindOfClass:[NLESegmentFilter_OC class]]) {
                NLESegmentFilter_OC *segmentFilter = (NLESegmentFilter_OC *)self.filterSlot.segment;
                segmentFilter.intensity = intensity;
                [segmentFilter.effectSDKFilter acc_setGlobalResouceWithPath:effect.resourcePath];
            }
            [self.nle.editor acc_commitAndRender:nil];
        }
        self.appendedFilters = [@[effect] mutableCopy];
    } else {
        [self p_removeFilters];
        [self.nle.editor acc_commitAndRender:nil];
    }
}
    
#pragma mark - Private Helper
- (BOOL)hadAppendFilter:(IESEffectModel *)filter
{
    return [self.appendedFilters containsObject:filter];
}

- (void)appendFilter:(IESEffectModel *)filter position:(CGFloat)position isLeftFilter:(BOOL)isLeftFilter
{
    if (!filter) {
        return ;
    }
    NSArray<VEComposerInfo *> *nodes = [filter appendedNodeInfosWithPosition:position
                                                                  isLeftSide:isLeftFilter];
    
    [self.nle appendComposerNodesWithTags:nodes];
    [self.appendedFilters addObject:filter];
}

- (void)replaceToComposerFilter:(IESEffectModel *)filter intensity:(float)intensity
{
    if (!filter) {
        return;
    }
    NSMutableArray *nodes = [@[] mutableCopy];
    for (IESEffectModel *appendedEffect in self.appendedFilters) {
        if (![appendedEffect.effectIdentifier isEqualToString:filter.effectIdentifier]) {
            [nodes addObjectsFromArray:[appendedEffect nodeInfos]];
        }
    }
    
    [self.nle replaceComposerNodesWithNewTag:[filter nodeInfosWithIntensity:intensity]
                                     old:nodes];
    self.appendedFilters = [@[filter] mutableCopy];
}

- (NSMutableArray *)appendedFilters
{
    if (!_appendedFilters) {
        _appendedFilters = [NSMutableArray array];
    }
    return _appendedFilters;
}

@end

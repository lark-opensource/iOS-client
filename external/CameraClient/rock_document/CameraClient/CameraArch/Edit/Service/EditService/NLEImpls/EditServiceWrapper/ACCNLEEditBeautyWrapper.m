//
//  ACCNLEEditBeautyWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2021/2/27.
//

#import "ACCNLEEditBeautyWrapper.h"
#import <NLEPlatform/NLEInterface.h>
#import <NLEPlatform/NLESegmentFilter+iOS.h>
#import <NLEPlatform/NLESegmentComposerFilter+iOS.h>
#import <NLEPlatform/NLEFilter+iOS.h>
#import <NLEPlatform/NLETrack+iOS.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>
#import "NLEResourceAV_OC+Extension.h"
#import "NLEEditor_OC+Extension.h"

static NSString * const ACCNLEEditBeautyKey = @"ACCNLEEditBeautyKey";

@interface ACCNLEEditBeautyWrapper()<ACCEditBuildListener>

@property (nonatomic, weak) NLEInterface_OC *nle;
@property (nonatomic, strong) NSMapTable<NSString *, NLETrack_OC *> *mapTable;

@end

@implementation ACCNLEEditBeautyWrapper

#pragma mark - ACCEditWrapper

- (void)setEditSessionProvider:(nonnull id<ACCEditSessionProvider>)editSessionProvider {
    [editSessionProvider addEditSessionListener:self];
}

#pragma mark - ACCEditBeautyProtocol

- (void)replaceComposerBeauty:(AWEComposerBeautyEffectWrapper *)effectWrapper
                      withOld:(AWEComposerBeautyEffectWrapper *)oldWrapper
{
    [self removeComposerBeautyTrack:oldWrapper];

    NLETrack_OC *cacheTrack = [self trackForBeauty:effectWrapper];
    if (cacheTrack) {
        [self updateTrack:cacheTrack forBeauty:effectWrapper];
    } else {
        [self addComposerBeautyTrack:effectWrapper];
    }
    
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)appendComposerBeautys:(NSArray<AWEComposerBeautyEffectWrapper *> *)effects
{
    for (AWEComposerBeautyEffectWrapper *effectWrapper in effects) {
        NLETrack_OC *cacheTrack = [self trackForBeauty:effectWrapper];
        if (cacheTrack) {
            [self updateTrack:cacheTrack forBeauty:effectWrapper];
        } else {
            [self addComposerBeautyTrack:effectWrapper];
        }
    }
    
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)removeBeautyEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)effects
{
    for (AWEComposerBeautyEffectWrapper *effectWrapper in effects) {
        [self removeComposerBeautyTrack:effectWrapper];
    }
    
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)updateBeautyEffectItem:(AWEComposerBeautyEffectItem *)item
                    withEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                         ratio:(float)ratio
{
    NLESegmentComposerFilter_OC *segment = [self segmentForBeauty:effectWrapper];
    NSMutableDictionary *tags = [segment.effectTags mutableCopy];
    tags[item.tag] = @([item effectValueForRatio:ratio]);
    segment.effectTags = tags;
    
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)updateBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    NLESegmentComposerFilter_OC *segment = [self segmentForBeauty:effectWrapper];
    NSMutableDictionary *tags = [segment.effectTags mutableCopy];
    for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
        tags[item.tag] = @(effectWrapper.currentIntensity);
    }
    segment.effectTags = tags;
    
    [self.nle.editor acc_commitAndRender:nil];
}



#pragma mark - ACCEditBuildListener

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editorSession {}

- (void)onNLEEditorInit:(NLEInterface_OC *)editor {
    self.nle = editor;
    self.mapTable = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableWeakMemory];
}



#pragma mark - Private

- (NLESegmentComposerFilter_OC *)segmentForBeauty:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    NLETrack_OC *track = [self trackForBeauty:effectWrapper];
    if ([track.slots.firstObject.segment isKindOfClass:[NLESegmentComposerFilter_OC class]]) {
        NLESegmentComposerFilter_OC *segment = (NLESegmentComposerFilter_OC *)track.slots.firstObject.segment;
        return segment;
    }
    
    return nil;
}

- (NLETrack_OC *)trackForBeauty:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    // search from cache
    NLETrack_OC *cacheTrack = [self.mapTable objectForKey:effectWrapper.effect.resourceId];
    if (cacheTrack) {
        return cacheTrack;
    }
    
    // search from NLE
    NLEModel_OC *model = [self.nle.editor getModel];
    for (NLETrack_OC *track in model.getTracks) {
        if ([track getTrackType] != NLETrackFILTER || ![self isComposerBeautyTrack:track]) {
            continue;
        }
        
        if ([track.slots.firstObject.segment isKindOfClass:[NLESegmentComposerFilter_OC class]]) {
            NLESegmentComposerFilter_OC *segment = (NLESegmentComposerFilter_OC *)track.slots.firstObject.segment;
            
            NLEResourceNode_OC *resource = segment.effectSDKFilter;
            NSString *resourceId = effectWrapper.effect.resourceId;
            if ([resource.resourceId isEqualToString:resourceId]) {
                [self.mapTable setObject:track forKey:resource.resourceId];
                return track;
            }
        }
    }
    
    return nil;
}

- (void)removeComposerBeautyTrack:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    NLEModel_OC *model = [self.nle.editor getModel];
    NLETrack_OC *track = [self trackForBeauty:effectWrapper];
    [model removeTrack:track];
    [self.mapTable removeObjectForKey:effectWrapper.effect.resourceId];
}

- (void)addComposerBeautyTrack:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    CGFloat intensity = effectWrapper.currentIntensity;
    IESEffectModel *effect = effectWrapper.effect;
    NLEResourceNode_OC *filterResource = [[NLEResourceNode_OC alloc] init];
    filterResource.resourceId = effect.resourceId;
    [filterResource acc_setGlobalResouceWithPath:effect.filePath];
    filterResource.resourceType = NLEResourceTypeComposer;

    NLESegmentComposerFilter_OC *filterSegment = [[NLESegmentComposerFilter_OC alloc] init];
    [filterSegment setEffectSDKFilter:filterResource];
    filterSegment.intensity = intensity;
    filterSegment.filterName = effect.effectName;
    
    NSMutableDictionary *effectTags = [NSMutableDictionary dictionary];
    for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
        effectTags[item.tag] = @(intensity);
    }
    filterSegment.effectTags = [effectTags copy];

    NLETrack_OC *track = [[NLETrack_OC alloc] init];
    [track setExtra:@"1" forKey:ACCNLEEditBeautyKey];
    NLETrackSlot_OC *slot = [[NLETrackSlot_OC alloc] init];
    slot.segment = filterSegment;
    [track addSlot:slot];
    [[self.nle.editor getModel] addTrack:track];
}

- (void)updateTrack:(NLETrack_OC *)track
          forBeauty:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    if ([track.slots.firstObject.segment isKindOfClass:[NLESegmentComposerFilter_OC class]]) {
        NLESegmentComposerFilter_OC *segment = (NLESegmentComposerFilter_OC *)track.slots.firstObject.segment;
        IESEffectModel *effect = effectWrapper.effect;
        
        NSMutableDictionary *effectTags = [NSMutableDictionary dictionary];
        CGFloat intensity = effectWrapper.currentIntensity;
        for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
            effectTags[item.tag] = @(intensity);
        }
        segment.effectTags = [effectTags copy];
        
        segment.effectSDKFilter.resourceId = effect.resourceId;
        [segment.effectSDKFilter acc_setGlobalResouceWithPath:effect.filePath];
        segment.effectSDKFilter.resourceType = NLEResourceTypeComposer;
    }
}

- (BOOL)isComposerBeautyTrack:(NLETrack_OC *)track
{
    NSString *value = [track getExtraForKey:ACCNLEEditBeautyKey];
    return value.length > 0;
}

@end

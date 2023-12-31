//
//  ACCEditBeautyWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2021/1/20.
//

#import "ACCEditBeautyWrapper.h"

#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitRTProtocol/ACCEditSessionBuilderProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <TTVideoEditor/VEEditorSession+Effect.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>

@interface ACCEditBeautyWrapper () <ACCEditBuildListener>

@property (nonatomic, weak) VEEditorSession *player;

@end


@implementation ACCEditBeautyWrapper

- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

#pragma mark - ACCEditBuildListener

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editSession
{
    self.player = editSession.videoEditSession;
}

#pragma mark - ACCEditBeautyProtocol

- (void)applyComposerBeautyEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)effectWrappers
{
    NSMutableArray *nodes = [NSMutableArray new];
    BOOL useSavedValue = YES;
    NSString *logInfo = @"===Composer apply effect: ";
    for (AWEComposerBeautyEffectWrapper *effectWrapper in effectWrappers) {
        if (!effectWrapper.isFilter && effectWrapper.effect) {
            NSString *resourcePath = effectWrapper.effect.resourcePath;
            if (ACC_isEmptyString(resourcePath)) {
                continue;
            }
            if (ACC_isEmptyArray(effectWrapper.items)) {
                VEComposerInfo *info = [[VEComposerInfo alloc] init];
                info.node = resourcePath;
                info.tag = effectWrapper.effect.extra;
                [nodes acc_addObject:info];
            } else {
                float ratio = effectWrapper.currentRatio;
                for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
                    float value = useSavedValue ? [item effectValueForRatio:ratio] : item.defaultValue;
                    NSString *pathTag = [NSString stringWithFormat:@"%@;%@;%f", effectWrapper.effect.resourcePath, item.tag, value];
                    VEComposerInfo *info = [[VEComposerInfo alloc] init];
                    info.node = pathTag;
                    info.tag = effectWrapper.effect.extra;
                    [nodes acc_addObject:info];
                    ACCLog(@"apply composer beauty: %@ %f", item.tag, value);
                }
            }
            logInfo = [logInfo stringByAppendingFormat:@"%@", effectWrapper];
        }
    }
    ACCLog(@"%@", logInfo);
    [self.player appendComposerNodesWithTags:nodes];
    [self p_dumpComposerNodes];
}

- (void)removeBeautyEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)effects
{
    NSMutableArray *nodes = [NSMutableArray new];
    for (AWEComposerBeautyEffectWrapper *effectWrapper in effects) {
        if ([effectWrapper isEffectSet]) {
            for (AWEComposerBeautyEffectWrapper *child in effectWrapper.childEffects) {
                if ([child downloaded]) {
                    [nodes addObjectsFromArray:[child nodesWithIntensity:NO]];
                }
            }
        } else {
            if ([effectWrapper downloaded]) {
                [nodes addObjectsFromArray:[effectWrapper nodesWithIntensity:NO]];
            }
        }
    }
    [self.player removeComposerNodesWithTags:nodes];
    [self p_dumpComposerNodes];
}

- (void)updateBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
        [self updateBeautyEffectItem:item withEffect:effectWrapper ratio:item.currentRatio];
    }
    [self p_dumpComposerNodes];
}

- (void)updateBeautyEffectItem:(AWEComposerBeautyEffectItem *)item
                    withEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                         ratio:(float)ratio
{
    NSString *resourcePath = effectWrapper.effect.resourcePath;
    if (resourcePath.length > 0) {
        float value = [item effectValueForRatio:ratio];
        [self.player updateComposerNode:effectWrapper.effect.resourcePath key:item.tag value:value];
    }
}

- (void)appendComposerBeautys:(NSArray<AWEComposerBeautyEffectWrapper *> *)effects
{
    for (AWEComposerBeautyEffectWrapper *effectWrapper in effects) {
        NSArray *nodes = [effectWrapper nodes];
        [self.player appendComposerNodesWithTags:nodes];
        [self updateBeautyEffect:effectWrapper];
    }
    [self p_dumpComposerNodes];
}

- (void)replaceComposerBeauty:(nonnull AWEComposerBeautyEffectWrapper *)effectWrapper
                      withOld:(nullable AWEComposerBeautyEffectWrapper *)oldWrapper
{
    NSArray *nodes = [effectWrapper nodes];
    NSArray *oldNodes = [oldWrapper nodesWithIntensity:NO];
    [self.player replaceComposerNodesWithNewTag:nodes old:oldNodes];
    [self p_dumpComposerNodes];
}


/// 修改composer 数据，必须要及时dumpComposerNodes, 否则数据会丢失
- (void)p_dumpComposerNodes
{
    [self.player dumpComposerNodes:self.player.videoData];
}

@end

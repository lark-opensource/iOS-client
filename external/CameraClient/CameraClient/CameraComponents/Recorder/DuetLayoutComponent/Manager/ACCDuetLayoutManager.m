//
//  ACCDuetLayoutManager.m
//  CameraClient-Pods-Aweme
//
//  Created by 李辉 on 2020/2/7.
//

#import "ACCDuetLayoutManager.h"

#import <CreativeKit/ACCMacros.h>
#import <EffectPlatformSDK/EffectPlatform.h>

#import <CreativeKit/NSString+CameraClientResource.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>

static NSString *const kDuetPannelName = @"duet-layout";
static NSString *const kDuetLayoutTagLeftRight = @"left-right";

//新合拍发布的时候需要新增一个duet_layout字段，用于送审的时候区分当前是何种布局的合拍，以便查看对应的
//合拍内容是否合规等
static NSString *const kDuetLayoutApplyTypeLeftRightA = @"new_left";
static NSString *const kDuetLayoutDefaultResourceFileName = @"duetLeftRightLayout";

@interface ACCDuetLayoutManager ()

@property (nonatomic, strong) NSArray<VEComposerInfo *> *oldNodes;
@property (nonatomic, assign) BOOL hasAppliedDownloadedLayout;//是否已经应用了下载的布局
@property (nonatomic, weak) id<ACCDuetLayoutManagerDelegate> delegate;

@end

@implementation ACCDuetLayoutManager

- (instancetype)initWithDelegate:(nonnull id<ACCDuetLayoutManagerDelegate>)delegate
{
    if (self = [super init]) {
        self.delegate = delegate;
    }
    return self;
}

- (void)downloadDuetLayoutResources
{
    if (self.duetLayoutModels) {
        return;
    }
    @weakify(self);
    [EffectPlatform checkEffectUpdateWithPanel:kDuetPannelName effectTestStatusType:IESEffectModelTestStatusTypeDefault completion:^(BOOL needUpdate) {
        IESEffectPlatformResponseModel *responseModel = [EffectPlatform cachedEffectsOfPanel:kDuetPannelName];
        if (!needUpdate && responseModel.effects.count > 0) {
            @strongify(self);
            [self buildLayoutModelsWithEffects:responseModel.effects];
        } else {
            [EffectPlatform downloadEffectListWithPanel:kDuetPannelName saveCache:YES completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                @strongify(self);
                if (response && response.effects.count > 0) {
                    [self buildLayoutModelsWithEffects:response.effects];
                } else {
                    self.hasErrorWhenFetchingEffects = YES;
                    if ([self.delegate respondsToSelector:@selector(duetLayoutManager:loadEffectsFinished:)]) {
                        [self.delegate duetLayoutManager:self loadEffectsFinished:NO];
                    }
                }
            }];
        }
    }];
}

- (void)buildLayoutModelsWithEffects:(NSArray *)effects
{
    if (!effects) {
        return;
    }
    self.hasErrorWhenFetchingEffects = NO;
    if ([self.delegate respondsToSelector:@selector(duetLayoutManager:loadEffectsFinished:)]) {
        [self.delegate duetLayoutManager:self loadEffectsFinished:YES];
    }
    NSMutableArray *temp = [NSMutableArray new];
    for (IESEffectModel *effect in effects) {
        ACCDuetLayoutModel *model = [[ACCDuetLayoutModel alloc] initWithEffect:effect];
        if (model) {
            [temp addObject:model];
        }
    }
    self.duetLayoutModels = [temp copy];
    [self downloadFirstEffectResource];
}

- (NSArray <ACCDuetLayoutModel *> *)p_dueLayoutModelsWithEffects:(NSArray<IESEffectModel *> *)effects
{
    NSMutableArray <ACCDuetLayoutModel *> *ret = [NSMutableArray new];
    for (IESEffectModel *effect in [effects copy]) {
        ACCDuetLayoutModel *model = [[ACCDuetLayoutModel alloc] initWithEffect:effect];
        if (model) {
            [ret addObject:model];
        }
    }
    return [ret copy];
}

- (void)downloadFirstEffectResource
{
    if (self.firstDuetLayout) {
        self.firstTimeIndex = [self indexFromDuetLayout:self.firstDuetLayout];
    }
    if (self.duetLayoutModels.count > 0) {
        ACCDuetLayoutModel *model = [self.duetLayoutModels objectAtIndex:self.firstTimeIndex];
        IESEffectModel *effect = [model effect];
        if (!effect.downloaded) {
            effect.downloadStatus = AWEEffectDownloadStatusDownloading;
            [EffectPlatform downloadEffect:effect progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
                if (!error && filePath) {
                    effect.downloadStatus = AWEEffectDownloadStatusDownloaded;
                    [self hanldeFirstLayoutResourceDownloaded];
                }
            }];
        } else {
            [self hanldeFirstLayoutResourceDownloaded];
        }
    }
}

- (void)hanldeFirstLayoutResourceDownloaded
{
    if (self.hasAppliedDownloadedLayout) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(succeedDownloadFirstLayoutResource)]) {
        [self.delegate succeedDownloadFirstLayoutResource];
    }
    [self applyDuetLayoutWithIndex:self.firstTimeIndex];
    if (self.firstDuetLayout) {
        ACCDuetLayoutModel *model = [self layoutModelAtIndex:self.firstTimeIndex];
        NSInteger toggleIndex = [model duetLayoutIndexOf:self.firstDuetLayout];
        if (toggleIndex == 1) {
            [self toggleDuetLayoutWithIndex:self.firstTimeIndex];
        }
    }
}

- (ACCDuetLayoutModel *)layoutModelAtIndex:(NSInteger)index
{
    return index < self.duetLayoutModels.count ? [self.duetLayoutModels objectAtIndex:index] : nil;
}

#pragma mark - apply & update nodes
- (void)applyDuetLayoutWithIndex:(NSInteger)index
{
    self.hasAppliedDownloadedLayout = YES;
    ACCDuetLayoutModel *model = [self layoutModelAtIndex:index];
    NSArray *nodes = model.node ? @[model.node] : nil;
    if ([self.delegate respondsToSelector:@selector(duetLayoutManager:willApplyDuetLayoutModel:)]) {
        [self.delegate duetLayoutManager:self willApplyDuetLayoutModel:model];
    }
    [self notifyDuetLayoutWithIndex:index];
    [self cameraApplyComposerNodes:nodes];
}

- (void)toggleDuetLayoutWithIndex:(NSInteger)index
{
    ACCDuetLayoutModel *model = [self.duetLayoutModels objectAtIndex:index];
    if (!model) {
        return;
    }
    NSString *key = @"switchButton";//Effect那边定死的
    NSInteger value = model.toggled ? 0 : 1;
    [self.cameraService.beauty updateComposerNode:model.node.node key:key value:value];
    model.toggled = !model.toggled;
    [self notifyDuetLayoutWithIndex:index];
}

- (void)applyDefaultDuetLayouts
{
    if (!self.hasAppliedDownloadedLayout) {
        VEComposerInfo *node = [self buildDefaultLeftRightNode];
        NSArray *nodes = node ? @[node] : nil;
        [self notifyDuetLayoutWithIndex:0];//内置资源包等同于网络下载的第一个
        
        [self cameraApplyComposerNodes:nodes];
    }
}

// 实际上是applyDefaultDuetLayouts的优化，如果选择的不是第一个则试试从缓存里拿，这样不会由A到B闪一下
- (BOOL)applyFirstDuetLayoutsIfEnable
{
    NSString *firstDuetLayoutName = self.firstDuetLayout;
    
    if (ACC_isEmptyString(firstDuetLayoutName) || self.hasAppliedDownloadedLayout) {
        return NO;
    }

    IESEffectPlatformResponseModel *responseModel = [EffectPlatform cachedEffectsOfPanel:kDuetPannelName];
    if (ACC_isEmptyArray(responseModel.effects)) {
        return NO;
    }
    
    NSArray <ACCDuetLayoutModel *> *cachedDuetLayots = [self p_dueLayoutModelsWithEffects:responseModel.effects];
    ACCDuetLayoutModel *targetLayoutModel = nil;
    BOOL isToggled = NO;
    
    for (ACCDuetLayoutModel *model in cachedDuetLayots) {
        NSInteger index = [model duetLayoutIndexOf:firstDuetLayoutName];
        if (index >= 0) {
            targetLayoutModel = model;
            isToggled = (index == 1);
            break;
        }
    }

    if (!targetLayoutModel || !targetLayoutModel.enable || !targetLayoutModel.node) {
        return NO;
    }

    VEComposerInfo *node = targetLayoutModel.node;
    NSArray *nodes = node ? @[node] : nil;
    [self cameraApplyComposerNodes:nodes];
    
    if (isToggled) {
        NSString *key = @"switchButton";
        [self.cameraService.beauty updateComposerNode:targetLayoutModel.node.node key:key value:1];
    }

    return YES;
}

- (NSString *)duetLayoutFromIndex:(NSInteger)index
{
    NSString *duetLayout = kDuetLayoutApplyTypeLeftRightA;
    if (index < self.duetLayoutModels.count) {
        ACCDuetLayoutModel *model = [self.duetLayoutModels objectAtIndex:index];
        duetLayout = model.duetLayout ? model.duetLayout : duetLayout;
    }
    return duetLayout;
}

- (NSInteger)indexFromDuetLayout:(NSString *)duetLayout
{
    for (NSInteger i = 0; i < self.duetLayoutModels.count; i++) {
        ACCDuetLayoutModel *model = [self.duetLayoutModels objectAtIndex:i];
        if ([model duetLayoutIndexOf:duetLayout] >= 0) {
            return i;
        }
    }
    return 0;
}

- (void)notifyDuetLayoutWithIndex:(NSInteger)index
{
    NSString *duetLayout = [self duetLayoutFromIndex:index];
    if ([self.delegate respondsToSelector:@selector(duetLayoutManager:didApplyDuetLayout:)]) {
        [self.delegate duetLayoutManager:self didApplyDuetLayout:duetLayout];
    }
}

- (void)cameraApplyComposerNodes:(NSArray *)nodes
{
    if (self.oldNodes) {
        [self.cameraService.beauty replaceComposerNodesWithNewTag:nodes old:self.oldNodes];
    } else {
        [self.cameraService.beauty appendComposerNodesWithTags:nodes];
    }
    self.oldNodes = nodes;
}

- (VEComposerInfo *)buildDefaultLeftRightNode
{
    VEComposerInfo *node = [VEComposerInfo new];
    NSString *path = [NSString acc_filePathWithName:kDuetLayoutDefaultResourceFileName];
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:path], @"合拍布局应当内置左右布局的资源");
    node.tag = kDuetLayoutTagLeftRight;
    node.node = path;
    return node;
}

#pragma mark - setters

@end

//
//  ACCNLEEditStickerWrapper.m
//  CameraClient
//
//  Created by larry.lai on 2021/1/24.
//

#import "ACCNLEEditStickerWrapper.h"
#import <NLEPlatform/NLESegmentInfoSticker+iOS.h>
#import <NLEPlatform/NLESegmentSubtitleSticker+iOS.h>
#import <NLEPlatform/NLEStyleText+iOS.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectSDK_iOS/RequirementDefine.h>
#import <EffectPlatformSDK/IESAlgorithmRecord.h>
#import <CreativeKit/ACCMacros.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

#import <CreationKitInfra/ACCRACWrapper.h>
#import "VEEditorSession+ACCSticker.h"
#import "ACCNLEHeaders.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/NSDictionary+ACCAdditions.h>

#import "NLEResourceAV_OC+Extension.h"
#import "NLEEditor_OC+Extension.h"
#import "IESInfoSticker+ACCAdditions.h"
#import "NLETrackSlot_OC+Extension.h"
#import "ACCEditVideoDataDowngrading.h"

static CMTime ConvertToNLETime(float time) {
    return CMTimeMake(time * USEC_PER_SEC, USEC_PER_SEC);
}

@interface ACCNLEEditStickerWrapper () <ACCEditBuildListener, NLEVECallBackProtocol>

@property (nonatomic, weak) NLEInterface_OC *nle;
@property (nonatomic, weak) NLEModel_OC *nleModel; ///< help to judge if idToSlotCache is out of sync
@property (nonatomic, strong) NSMapTable *idToSlotCache; // stickerId - slot
@property (nonatomic, copy) void (^pinCallback)(BOOL result, NSError *error);
@property (nonatomic, copy) VEStickerImageBlock autoCaptionImageBlock;
@property (nonatomic, strong) RACSubject<RACTwoTuple<NSNumber *, NSNumber *> *> *stickerRegenerateSignal;

@end

@implementation ACCNLEEditStickerWrapper
@synthesize fixedTopInfoSticker = _fixedTopInfoSticker;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fixedTopInfoSticker = -1;
    }
    return self;
}

- (void)dealloc
{
    [_stickerRegenerateSignal sendCompleted];
}

- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

#pragma mark - ACCEditBuildListener

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editorSession {}

- (void)onNLEEditorInit:(NLEInterface_OC *)editor {
    self.nle = editor;
    // only used for PIN callback now
    [self.nle setVEOperateCallback:self];
    
    @weakify(self);
    self.nle.stickerChangeEvent = ^(NSInteger newStickerId, NSInteger originStickerId) {
        @strongify(self);
        if (newStickerId == originStickerId) return;
        [self onRecoverStickerWith:newStickerId originStickerId:originStickerId];
    };
}

#pragma mark - ACCEditStickerProtocol

#pragma mark - lyric sticker

- (NSInteger)addSubtitleSticker
{
    // 自动字幕是一条时间线上顺序排列的一或多个贴纸，用一个专属轨道来承载
    NLETrackSlot_OC *slot = [NLETrackSlot_OC captionStickerTrackSlot];
    slot.layer = [[self.nle.editor getModel] getLayerMax] + 1;
    NLETrack_OC *track = [[self.nle.editor getModel] captionStickerTrack];
    [track addSlot:slot];
    [self.nle.editor acc_commitAndRender:nil];
    
    NSInteger stickerId = [self.nle stickerIdForSlot:[slot getName]];
    return stickerId;
}

- (UIColor *)filterMusicLyricColor
{
    NLETrackSlot_OC *slot = [self lyricStickerSlot];
    return [slot getSrtColor];
}

- (NSString *)filterMusicLyricEffectId
{
    return ACCDynamicCast([[[self.nle getInfoStickers] acc_match:^BOOL(IESInfoSticker * _Nonnull item) {
        return item.isSrtInfoSticker;
    }] userinfo][@"stickerID"], NSString);
}

- (NSNumber *)filterMusicLyricStickerId
{
    NLETrackSlot_OC *slot = [self lyricStickerSlot];
    if (slot) {
        return @([self.nle stickerIdForSlot:[slot getName]]);
    }
    // 如果返回nil，外部不判断，直接获取integervalue为0，
    // VE的贴纸ID就是从0开始，0是有效贴纸，可能会导致删除错误的贴纸
    return @(NSIntegerMin);
}

- (void)setSrtAudioInfo:(NSInteger)stickerId seqIn:(NSTimeInterval)seqIn trimIn:(NSTimeInterval)trimIn duration:(NSTimeInterval)duration audioCycle:(BOOL)audioCycle
{
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerId];
    if (!slot) {
        return;
    }
    NLESegmentSubtitleSticker_OC *sticker = slot.lyricSticker;
    sticker.timeClipStart = ConvertToNLETime(trimIn);
    sticker.timeClipEnd = ConvertToNLETime(trimIn + duration);
    
    // 动画信息
    NLEStyStickerAnimation_OC *stickerAnim = sticker.stickerAnimation;
    stickerAnim.loop = audioCycle;
    
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setSrtColor:(NSInteger)stickerId red:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a
{
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerId];
    if (!slot) {
        return;
    }
    [slot setSrtColorWithR:r g:g b:b a:a];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setSrtFont:(NSInteger)stickerId fontPath:(nonnull NSString *)fontPath
{
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerId];
    if (!slot) {
        return;
    }
    [slot.lyricSticker.style.font acc_setPrivateResouceWithURL:[NSURL URLWithString:fontPath]
                                                   draftFolder:self.nle.draftFolder];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setSrtInfo:(NSInteger)stickerId srt:(nonnull NSString *)srt
{
    if (srt.length == 0) {
        return;
    }
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerId];
    if (!slot) {
        return;
    }
    [slot setSrtString:srt draftFolder:self.nle.draftFolder];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)updateSticker:(NSInteger)stickerId
{
    [self.nle updateSticker:stickerId];
}

#pragma mark - Pin

- (void)preparePin
{
    AWELogToolInfo2(@"ACCNLEEditStickerWrapper", AWELogToolTagEdit, @"prepare PIN");
    [self.nle preparePin];
}

- (void)startPin:(NSInteger)stickerIndex
    pinStartTime:(float)pinStartTime
     pinDuration:(float)duration
      completion:(nonnull void (^)(BOOL result, NSError *error))completion
{
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerIndex];
    if (!slot) {
        ACCBLOCK_INVOKE(completion, NO, nil);
        return;
    }
    NSDictionary<NSString *, IESAlgorithmRecord *> *info = [EffectPlatform checkoutModelInfosWithRequirements:@[@REQUIREMENT_OBJECT_TRACKING_TAG] modelNames:@{}];
    IESAlgorithmRecord *algo = info.allValues.firstObject;
    if (algo) {
        AWELogToolInfo(AWELogToolTagEdit, @"find PIN algorithm file\nname: %@\nversion:%@\n", algo.name, algo.version);
    } else {
        AWELogToolError(AWELogToolTagEdit, @"no PIN algorithm file");
        ACCBLOCK_INVOKE(completion, NO, nil);
        return;
    }
    
    NLEResourceNode_OC *node = [[NLEResourceNode_OC alloc] init];
    node.resourceType = NLEResourceTypePIN;
    
    slot.pinAlgorithmFile = node;
    slot.startTime = ConvertToNLETime(pinStartTime);
    slot.duration = ConvertToNLETime(duration);
    
    @weakify(self);
    self.pinCallback = [^(BOOL result, NSError *error) {
        @strongify(self);
        if (!error && result) {
            IESInfoSticker *sticker = [[self.nle getInfoStickers] acc_match:^BOOL(IESInfoSticker * _Nonnull item) {
                return item.stickerId == stickerIndex;
            }];
            NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerIndex];
            [slot.pinAlgorithmFile acc_setPrivateResouceWithURL:[NSURL URLWithString:sticker.pinResultPath]
                                                    draftFolder:self.nle.draftFolder];
        } else {
            AWELogToolError(AWELogToolTagEdit, @"PIN failed, error: %@", error);
            slot.pinAlgorithmFile = nil;
        }
        [self.nle.editor acc_commitAndRender:nil];
        ACCBLOCK_INVOKE(completion, result, error);
    } copy];

    [self.nle.editor acc_commitAndRender:nil];
}

- (void)cancelPin:(NSInteger)stickerIndex
{
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerIndex];
    if (!slot) {
        return;
    }
    slot.pinAlgorithmFile = nil;
    [self.nle.editor acc_commitAndRender:nil];
}

- (VEStickerPinStatus)getStickerPinStatus:(NSInteger)stickerIndex
{
    return [self.nle getStickerPinStatus:stickerIndex];
}

- (void)setInfoStickerRestoreMode:(VEInfoStickerRestoreMode)mode
{
    [self.nle setInfoStickerRestoreMode:mode];
}

#pragma mark - Sticker

- (void)addStickerbyUIImage:(UIImage *)image letterInfo:(nullable NSString*)letterInfo duration:(CGFloat)duration
{
    [self.nle addStickerByUIImage:image letterInfo:letterInfo duration:duration];
}

- (NSInteger)addTextStickerWithUserInfo:(NSDictionary *)userInfo
{
    NLETrackSlot_OC *slot = [NLETrackSlot_OC textStickerTrackSlot];
    slot.layer = [[self.nle.editor getModel] getLayerMax] + 1;
    NLETrack_OC *track = [[NLETrack_OC alloc] init];
    [track addSlot:slot];
    
    [[self.nle.editor getModel] addTrack:track];
    [self.nle setUserInfo:userInfo forStickerSlot:[slot getName]];
    [self.nle.editor acc_commitAndRender:nil];
    
    NSInteger stickerId = [self.nle stickerIdForSlot:[slot getName]];
    return stickerId;
}

- (BOOL)isAnimationSticker:(NSInteger)stickerID
{
    return [self.nle isAnimationSticker:stickerID];
}

- (NSInteger)addInfoSticker:(NSString *)path withEffectInfo:(nullable NSArray *)effectInfo userInfo:(NSDictionary *)userInfo
{
    NLETrackSlot_OC *stickerTrackSlot;
    // lyric Sticker
    if (userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeLyrics ||
        (userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeKaraoke &&
         userInfo.acc_karaokeType == ACCKaraokeStickerTypeLyric)) {
        stickerTrackSlot = [NLETrackSlot_OC lyricsStickerWithResoucePath:path
                                                              effectInfo:effectInfo
                                                                userInfo:userInfo
                                                             draftFolder:self.nle.draftFolder];
    }
    else if (userInfo.acc_isImageSticker) {
        stickerTrackSlot = [NLETrackSlot_OC imageStickerWithResoucePath:path
                                                             effectInfo:effectInfo
                                                               userInfo:userInfo
                                                            draftFolder:self.nle.draftFolder];
    }
    else {
        stickerTrackSlot = [NLETrackSlot_OC infoStickerWithResoucePath:path
                                                            effectInfo:effectInfo
                                                              userInfo:userInfo
                                                           draftFolder:self.nle.draftFolder];
    }
    stickerTrackSlot.layer = [[self.nle.editor getModel] getLayerMax] + 1;
    [self.nle setUserInfo:userInfo forStickerSlot:[stickerTrackSlot getName]];
    
    NLETrack_OC *track = [[NLETrack_OC alloc] init];
    [track addSlot:stickerTrackSlot];
    [[self.nle.editor getModel] addTrack:track];
    [self.nle.editor acc_commitAndRender:nil];
    
    // 歌词贴纸可能有初始值
    if (userInfo.acc_stickerType == ACCEditEmbeddedStickerTypeLyrics) {
        [self p_updateInitPosForStickerSlot:stickerTrackSlot];
    }
    
    NSInteger stickerId = [self.nle stickerIdForSlot:[stickerTrackSlot getName]];
    return stickerId;
}

- (NSInteger)setStickerAnimationWithStckerID:(NSInteger)stickerID animationType:(NSInteger)animationType filePath:(NSString *)filePath duration:(CGFloat)duration
{
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerID];
    if (!slot) {
        return NSIntegerMax;
    }
    return [slot setStickerAnimationType:animationType
                                filePath:filePath
                             draftFolder:self.nle.draftFolder
                                duration:duration];
}

- (void)setSticker:(NSInteger)stickerId offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY angle:(CGFloat)angle scale:(CGFloat)scale
{
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerId];
    if (!slot) {
        return;
    }
    
    [slot setStickerOffset:CGPointMake(offsetX, offsetY) normalizeConverter:self.nle.normalizeConverter];
    slot.rotation = -angle; // NLE逆时针旋转角度为正
    slot.scale *= scale; // we need absolute scale here
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setSticker:(NSInteger)stickerId offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY
{
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerId];
    if (!slot) {
        return;
    }
    
    [slot setStickerOffset:CGPointMake(offsetX, offsetY) normalizeConverter:self.nle.normalizeConverter];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setTextStickerTextParams:(NSInteger)stickerId textParams:(NSString *)textParams
{
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerId];
    if (!slot) {
        return;
    }
    
    [slot setTextStickerTextParams:textParams];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setSticker:(NSInteger)stickerId alpha:(CGFloat)alpha
{
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerId];
    if (!slot) {
        return;
    }
    slot.sticker.alpha = alpha;
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setStickerAngle:(NSInteger)stickerId angle:(CGFloat)angle
{
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerId];
    if (!slot) {
        return;
    }
    slot.rotation = -angle;
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setStickerScale:(NSInteger)stickerId scale:(CGFloat)scale
{
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerId];
    if (!slot) {
        return;
    }
    slot.scale = scale;
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setStickerLayer:(NSInteger)stickerId layer:(NSInteger)layer
{
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerId];
    if (!slot) {
        return;
    }
    [slot setLayer:layer];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setSticker:(NSInteger)stickerId startTime:(CGFloat)startTime duration:(CGFloat)duration
{
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerId];
    if (!slot) {
        return;
    }
    
    CGFloat maxDuration = [[self.nle.editor getModel] getMaxTargetEnd] / (1000 * 1000);
    if (startTime + duration > maxDuration) {
        duration = -1;
    }
    
    slot.startTime = ConvertToNLETime(startTime);
    slot.duration = ConvertToNLETime(duration);
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setStickerAbove:(NSInteger)stickerId
{
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerId];
    if (!slot) {
        return;
    }
    
    IESInfoSticker *sticker = [[self.nle getInfoStickers] acc_match:^BOOL(IESInfoSticker * _Nonnull item) {
        return item.stickerId == stickerId;
    }];
    if (sticker.layer < 0) {
        return;
    }
    
    [slot setStickerAboveWithNLEModel:self.nle.editor.model];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setStickerAboveForInfoSticker:(NSInteger)stickerId
{
    [self setStickerAbove:stickerId];
    if (self.fixedTopInfoSticker != -1) {
        [self setStickerAbove:self.fixedTopInfoSticker];
    }
}

- (void)startChangeStickerDuration:(NSInteger)stickerId
{
    [self.nle startChangeStickerDuration:stickerId];
}

- (void)stopChangeStickerDuration:(NSInteger)stickerId
{
    [self.nle stopChangeStickerDuration:stickerId];
}

- (CGRect)getstickerEditBoundBox:(NSInteger)stickerId
{
    return [self.nle getstickerEditBoundBox:stickerId];
}

- (CGSize)getInfoStickerSize:(NSInteger)stickerId
{
    return [self.nle getInfoStickerSize:stickerId];
}

- (CGSize)getstickerEditBoxSize:(NSInteger)stickerId
{
    return [self.nle getstickerEditBoxSize:stickerId];
}

- (void)getStickerId:(NSInteger)stickerId props:(IESInfoStickerProps *)props
{
    [self.nle getStickerId:stickerId props:props];
}

- (CGFloat)getStickerRotation:(NSInteger)stickerIndex
{
    return [self.nle getStickerRotation:stickerIndex];
}

- (CGPoint)getStickerPosition:(NSInteger)stickerIndex
{
    return [self.nle getStickerPosition:stickerIndex];
}

- (BOOL)getStickerVisible:(NSInteger)stickerIndex
{
    return [self.nle getStickerVisible:stickerIndex];
}

- (void)removeInfoSticker:(NSInteger)stickerId
{
    NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:stickerId];
    if (!slot) {
        return;
    }
    [[self.nle.editor getModel] removeSlots:@[slot] trackType:NLETrackSTICKER];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)removeAllInfoStickers
{
    for (NLETrack_OC *track in [[self.nle.editor getModel] tracksWithType:NLETrackSTICKER]) {
        for (NLETrackSlot_OC *slot in track.slots) {
            if (slot.sticker) {
                [track removeSlot:slot];
            }
        }
    }
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)removeAll2DStickers
{
    for (NLETrack_OC *track in [[self.nle.editor getModel] tracksWithType:NLETrackSTICKER]) {
        [[self.nle.editor getModel] removeTrack:track];
    }
    [self.nle.editor acc_commitAndRender:nil];
}

- (NSArray<IESInfoSticker *> *)infoStickers
{
    return [self.nle getInfoStickers];
}

- (void)setCaptionStickerImageBlock:(VEStickerImageBlock)captionStickerImageBlock
{
    self.autoCaptionImageBlock = [captionStickerImageBlock copy];
    [self.nle setCaptionStickerImageBlock:captionStickerImageBlock];
}

- (VEStickerImageBlock)captionStickerImageBlock
{
    return [self.autoCaptionImageBlock copy];
}

- (void)syncInfoStickerUpdatedWithVideoData:(ACCEditVideoData *)videoData
{
    ACCNLEEditVideoData *nleVideoData = acc_videodata_take_nle(videoData);
    if (nleVideoData == nil) {
        return;
    }
    
    [nleVideoData.stickerChangeMap acc_forEach:^(NSNumber * _Nonnull key, NSString * _Nonnull value) {
        NSInteger newStickerId = [self.nle stickerIdForSlot:value];
        if (key.integerValue != newStickerId) {
            [self onRecoverStickerWith:newStickerId originStickerId:key.integerValue];
        }
    }];
    nleVideoData.stickerChangeMap = nil;
}

#pragma mark - <NLEVECallBackProtocol>
- (void)veCallBackChanged:(BOOL) result error:(NSError *_Nonnull) error
{
    ACCBLOCK_INVOKE(self.pinCallback, result, error);
    self.pinCallback = nil;
}

#pragma mark - Helper Methods

- (NLETrackSlot_OC * _Nullable)p_stickerSlotWithStickerID:(NSInteger)id {
    if (id == NSIntegerMin || id == NSIntegerMax) {
        return nil;
    }
    
    NSString *cacheKey = [NSString stringWithFormat:@"%zd", id];
    NLETrackSlot_OC *slot;
    if (self.nleModel == [self.nle.editor getModel]) {
        slot = (NLETrackSlot_OC *)[self.idToSlotCache objectForKey:cacheKey];
        if (slot) return slot;
    } else {
        self.nleModel = [self.nle.editor getModel];
        [self.idToSlotCache removeAllObjects];
    }
    
    NSString* slotId = [self.nle slotIdForSticker:id];
    if (ACC_isEmptyString(slotId)) {
        return nil;
    }
    slot = [[self.nle.editor getModel] slotOfName:slotId withTrackType:NLETrackSTICKER];
    [self.idToSlotCache setObject:slot forKey:cacheKey];
    NSAssert(slot != nil, @"slotId cannot be nil");
    return slot;
}

- (NLETrackSlot_OC *)lyricStickerSlot {
    return [[[self.nle.editor getModel] slotsWithType:NLETrackSTICKER] acc_match:^BOOL(NLETrackSlot_OC * _Nonnull item) {
        return [item lyricSticker] != nil;
    }];
}

- (void)onRecoverStickerWith:(NSInteger)stickerId originStickerId:(NSInteger)originStickerId {
    [self.idToSlotCache removeObjectForKey:@(originStickerId).stringValue];
    [self.stickerRegenerateSignal sendNext:RACTuplePack(@(originStickerId),@(stickerId))];
}

- (void)syncEditPageWithBlock:(NS_NOESCAPE dispatch_block_t _Nullable)block {
    NSMutableDictionary *stickerMap = @{}.mutableCopy;
    [[[self.nle.editor getModel] slotsWithType:NLETrackSTICKER] btd_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
        stickerMap[obj.getName] = @([self.nle stickerIdForSlot:obj.getName]);
    }];
    ACCBLOCK_INVOKE(block);
    if (stickerMap.count) {
        [[self.nle.veEditor getInfoStickers] btd_forEach:^(IESInfoSticker * _Nonnull sticker) {
            NSString *slotName = [self.nle slotIdForSticker:sticker.stickerId];
            if (ACC_isEmptyString(slotName)) return;
            NSNumber *stickerId = [stickerMap btd_numberValueForKey:slotName];
            if (!stickerId) return;
            if (stickerId.integerValue == sticker.stickerId) return;
            [self onRecoverStickerWith:sticker.stickerId originStickerId:stickerId.integerValue];
        }];
    }
}

#pragma mark - batch

- (void)setStickersAbove:(nonnull NSArray<NSNumber *> *)stickerIds offsetX:(CGFloat)offsetX offsetY:(CGFloat)offsetY angle:(CGFloat)angle scale:(CGFloat)scale {
    [stickerIds acc_forEach:^(NSNumber * _Nonnull obj) {
        NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:obj.integerValue];
        if (!slot) {
            return;
        }
        // x,y 坐标
        [slot setStickerOffset:CGPointMake(offsetX, offsetY) normalizeConverter:self.nle.normalizeConverter];
        // z 坐标
        [slot setStickerAboveWithNLEModel:self.nle.editor.model];
    }];
    [self.nle.editor acc_commitAndRender:nil];
}


- (void)setStickersScale:(nonnull NSArray<NSNumber *> *)stickerIds scale:(CGFloat)scale {
    [stickerIds acc_forEach:^(NSNumber * _Nonnull obj) {
        NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:obj.integerValue];
        if (!slot) {
            return;
        }
        slot.scale = scale;
    }];
    [self.nle.editor acc_commitAndRender:nil];
}

- (void)setStickerAlphas:(NSArray<NSNumber *> *)stickerIds alpha:(CGFloat)alpha above:(BOOL)above
{
    [stickerIds acc_forEach:^(NSNumber * _Nonnull obj) {
        NLETrackSlot_OC *slot = [self p_stickerSlotWithStickerID:obj.integerValue];
        if (!slot) {
            return;
        }
        slot.sticker.alpha = alpha;
        if (above) {
            [slot setStickerAboveWithNLEModel:self.nle.editor.model];
        }
    }];
    [self.nle.editor acc_commitAndRender:nil];
}

#pragma mark - Private

- (void)p_updateInitPosForStickerSlot:(NLETrackSlot_OC *)stickerTrackSlot
{
    NSInteger stickerId = [self.nle stickerIdForSlot:[stickerTrackSlot getName]];
    CGPoint initPos = [self.nle getStickerPosition:stickerId];
    stickerTrackSlot.transformX = initPos.x;
    stickerTrackSlot.transformY = initPos.y;
    [self.nle.editor acc_commitAndRender:nil];
}

#pragma mark - getter

- (NSMapTable *)idToSlotCache {
    if (!_idToSlotCache) {
        _idToSlotCache = [NSMapTable strongToWeakObjectsMapTable];
    }
    return _idToSlotCache;;
}

- (RACSubject<RACTwoTuple<NSNumber *,NSNumber *> *> *)stickerRegenerateSignal {
    if (!_stickerRegenerateSignal) {
        _stickerRegenerateSignal = [RACSubject subject];
    }
    return _stickerRegenerateSignal;
}

#pragma mark - Sticker Animation

- (void)disableStickerAnimation:(nullable NLETrackSlot_OC *)slot disable:(BOOL)disable
{
    if (!slot) {
        return;
    }
    if (disable) {
        [self.nle disableStickerAnimation:slot];
    } else {
        [self.nle updateStickerAnimation:slot];
    }
}

- (nullable NLEStickerBox *)stickerBoxWithSlot:(NLETrackSlot_OC *)slot
{
    return [self.nle stickerBoxWithSlot:slot];
}

- (void)setSrtManipulate:(NSInteger)stickerId state:(BOOL)state {}

@end

//
//  ACCEffectWrapper.m
//  Pods
//
//  Created by liyingpeng on 2020/5/28.
//

#import "ACCEffectWrapper.h"
#import <CreationKitRTProtocol/ACCCameraDefine.h>
#import "ACCCameraFactory.h"
#import <TTVideoEditor/VERecorder.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <objc/message.h>
#import <CreativeKit/ACCMemoryTrackProtocol.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <TTVideoEditor/IESMMEffectMessage.h>
#import <CreativeKit/ACCAPMProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitRTProtocol/AWEComposerEffectProtocol.h>
#import "ACCFlowerAuditDataService.h"

static NSString * const AWEEffectRenderCacheKeyMemojiMatchScanResult = @"MemojiMatchScanResult";
static NSString * const AWEStikerEffectKey = @"AWEStikerEffectKey";
static NSString * const AWEComposerEffectKey = @"AWEComposerEffectKey";
static NSString * const kACCNeedExternalOpacityKey = @"needExternalOpacity";
static NSString * const kACCExternalMaleOpacityKey = @"externalMaleOpacity";
static NSString * const kACCExternalFemaleOpacityKey = @"externalFemaleOpacity";

@interface ACCEffectWrapper () <ACCCameraBuildListener>

@property (nonatomic, weak) id<VERecorderPublicProtocol> camera;
@property (nonatomic, strong) NSMutableDictionary *acc_contextInfo;
@property (nonatomic, assign) NSInteger forbiddenMusicPropPlayCount;

@end

@implementation ACCEffectWrapper
@synthesize currentSticker = _currentSticker;
@synthesize currentComposerSticker = _currentComposerSticker;
@synthesize camera = _camera;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _forbiddenMusicPropPlayCount = 0;
    }

    return self;
}

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
}

- (NSMutableDictionary *)acc_contextInfo
{
    if (!_acc_contextInfo) {
        _acc_contextInfo = @{}.mutableCopy;
    }
    return _acc_contextInfo;
}

#pragma mark -

- (void)acc_applyStickerEffect:(IESEffectModel * _Nullable)effect
{
    if (self.currentSticker) {
        [ACCMemoryTrack() finishScene:kAWEStudioSceneEffect withKey:kAWEStudioSceneEffect info:@{@"effect_id":self.currentSticker.effectIdentifier?:@""}];
    }
    [ACCMemoryTrack() resetMemoryWarningCountWithScene:kAWEStudioSceneEffect key:kAWEStudioSceneEffect];
    [ACCAPM() attachFilter:effect.effectIdentifier forKey:@"camera_effect"];
    [self p_configExternalFaceMakeupOpacityIfNeeded:effect];

    // composer和普通贴纸互斥逻辑端上做
    [self acc_operateVEComposerEffect:self.currentComposerSticker operation:IESMMComposerNodesOperationRemove extra:effect.extra];
    [self acc_applyVEStickerEffect:effect];
    [self acc_configVEForProp:effect];//Adjust VE config for props.
}

- (void)acc_applyVEStickerEffect:(IESEffectModel *)effect {
    if (![self p_verifyCameraContext]) {
        return;
    }
    NSString *path = effect.resourcePath;
    if (path == nil) {
        path = @"";
    }
    NSString *currentStickerPath = [self.acc_contextInfo acc_stringValueForKey:AWEStikerEffectKey];
    NSString *auditPackagePath = [IESAutoInline(ACCBaseServiceProvider(), ACCFlowerAuditDataService) auditPackagePath];
    if ([effect isFlowerPropAduit]) {
        currentStickerPath = auditPackagePath;
    }
    
    if ([path isEqual:currentStickerPath]) {
        return;
    }
    self.currentSticker = effect;
    self.acc_contextInfo[AWEStikerEffectKey] = path;
    if ([effect isFlowerPropAduit]) {
        self.acc_contextInfo[AWEStikerEffectKey] = auditPackagePath;
    }
    
    IESMMEffectStickerInfo *stickerInfo = [effect effectStickerInfo];
    stickerInfo.needReload = [effect needReloadWhenApply];
    if ([effect isFlowerPropAduit]) {
        stickerInfo.path = auditPackagePath;
    }
    
    if (ACC_isEmptyString(stickerInfo.path)) {
        stickerInfo.path = effect.resourcePath;
    }
    ACCLog(@"xfyxfy apply effect %@ reload %d", effect.effectIdentifier, stickerInfo.needReload);
    if ([effect isTypeInstrument]) {
        [self.camera applyRealPlayWithInfo:stickerInfo];
    } else {
        [self.camera applyEffectWithInfo:stickerInfo type:IESEffectGroup];
    }
}

- (void)acc_clearEffectRecordFinish
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    
    if ([self.currentSticker isTypeMusicBeat]) {
        [self acc_propPlayMusic:nil];
    }
    self.currentSticker = nil;
    self.acc_contextInfo[AWEStikerEffectKey] = @"";
    [self.camera clearEffectForRecordFinish];
}

- (void)acc_configVEForProp:(IESEffectModel *)effect
{
    [self acc_propPlayMusic:effect];
    [self acc_propSpeedControl:effect];
}

- (void)acc_applyComposerEffect:(id<AWEComposerEffectProtocol>)effect extra:(NSString *)extra {
    [self acc_operateVEComposerEffect:self.currentComposerSticker operation:IESMMComposerNodesOperationRemove extra:extra];
    [self acc_operateComposerEffect:effect operation:IESMMComposerNodesOperationAppend extra:extra];
}

- (void)acc_applyVEComposerEffect:(id<AWEComposerEffectProtocol>)effect extra:(NSString *)extra {
    [self acc_operateVEComposerEffect:self.currentComposerSticker operation:IESMMComposerNodesOperationRemove extra:extra];
    [self acc_operateVEComposerEffect:effect operation:IESMMComposerNodesOperationAppend extra:extra];
}

- (void)acc_operateComposerEffect:(id<AWEComposerEffectProtocol>)effect operation:(IESMMComposerNodesOperation)operation extra:(NSString *)extra
{
    // !! 应effect要求，调用顺序不能调换，否则效果会闪
    [self acc_operateVEComposerEffect:effect operation:operation extra:extra];
    [self acc_applyVEStickerEffect:nil];
}

- (void)acc_operateVEComposerEffect:(id<AWEComposerEffectProtocol>)effect operation:(IESMMComposerNodesOperation)operation extra:(NSString *)extra
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    NSArray *nodes = effect.filePaths;
    if (!nodes) {
        nodes = @[];
    }
    NSArray<NSString *> *currentComposerNodes = [self.acc_contextInfo acc_arrayValueForKey:AWEComposerEffectKey];
    if (operation == IESMMComposerNodesOperationSet) {
        if ([nodes isEqual:currentComposerNodes]) {
            return;
        }
    }

    NSMutableArray *nodeTags = [NSMutableArray new];
    for (NSString *node in nodes) {
        VEComposerInfo *info = [VEComposerInfo new];
        info.node = node;
        info.tag = extra;
        if (info) {
            [nodeTags addObject:info];
        }
    }

    if (operation != IESMMComposerNodesOperationRemove) {
        if (effect) {
            NSAssert(effect.response.resourcesAllDownloaded, @"set moji that missing some resources");
        }
        self.acc_contextInfo[AWEComposerEffectKey] = nodes;
        self.currentComposerSticker = effect;
        [self p_safelySetRenderCacheStringByKey:AWEEffectRenderCacheKeyMemojiMatchScanResult value:effect.idMap?:@""];

    } else {
        nodes = currentComposerNodes.count ? currentComposerNodes : nodes;
        if (nodes.count) {
            [self p_safelySetRenderCacheStringByKey:AWEEffectRenderCacheKeyMemojiMatchScanResult value:@""];
        }
        self.acc_contextInfo[AWEComposerEffectKey] = nil;
        self.currentComposerSticker = nil;
    }
    [self.camera operateComposerNodesWithTags:nodeTags operation:operation];
}

- (void)p_safelySetRenderCacheStringByKey:(NSString *)key value:(NSString *)value
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.camera setRenderCacheStringByKey:key value:value];
    });
}

#pragma mark - configVE with prop

- (void)acc_propPlayMusic:(IESEffectModel * _Nullable)effect
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    self.forbiddenMusicPropPlayCount = 0;
    // audio 在 musicPlay 这个接口里会驱动音频图，所以 audio graph 道具也需要开始 play
    if ([effect isTypeMusicBeat] || [effect isTypeAudioGraph]) {
        [self muteEffectPropBGM:YES];
        self.camera.effectNodeInAudioChainIsOn = YES;
        [self.camera setMusicNeedRepeat:YES];
        [self.camera musicPlay];
    } else {
        self.camera.effectNodeInAudioChainIsOn = NO;
        [self.camera setMusicNeedRepeat:NO];
        [self.camera musicSeekToTime:0.0];
        [self.camera musicPause];
    }
}

- (void)acc_musicPropStopMusic
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera musicStop];
}

- (void)acc_changeMusicPropPlayStatus:(BOOL)needPlay
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.currentSticker isTypeMusicBeat] || [self.currentSticker isTypeAudioGraph]) {
        if (needPlay) {
            [self.camera musicPlay];
        } else {
            [self.camera musicPause];
        }
    }
}

- (void)acc_retainForbiddenMusicPropPlayCount
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    self.forbiddenMusicPropPlayCount++;
    if (self.forbiddenMusicPropPlayCount > 0) {
        [self acc_changeMusicPropPlayStatus:NO];
    }
}

- (void)acc_releaseForbiddenMusicPropPlayCount
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    self.forbiddenMusicPropPlayCount--;
    if (self.forbiddenMusicPropPlayCount == 0) {
        [self acc_changeMusicPropPlayStatus:YES];
    }
}

- (void)acc_playMusicIfNotBeingFobbidden
{
    if (self.forbiddenMusicPropPlayCount <= 0) {
        [self acc_changeMusicPropPlayStatus:YES];
    }
}

- (void)acc_propSpeedControl:(IESEffectModel * _Nullable)effect
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([effect acc_useEffectRecordRate]) {
        [self.camera setUseEffectRecordRate:YES];
    } else {
        [self.camera setUseEffectRecordRate:NO];
    }
}

#pragma mark - effect prop bgm control

- (void)enableEffectPropBGM:(BOOL)enable
{
    if (!_camera) {
        return;
    }
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(enableBGM:)]) {
        [self.camera enableBGM:enable];
    }
}

- (void)startEffectPropBGM:(IESEffectBGMType)type
{
    if (!_camera) {
        return;
    }
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.currentSticker isTypeMusicBeat] && ![self.currentSticker isTypeAudioGraph]) {
        return;
    }
    NSString *currentStickerPath = [self.acc_contextInfo[AWEStikerEffectKey] isKindOfClass:[NSString class]] ? self.acc_contextInfo[AWEStikerEffectKey] : nil;
    if (currentStickerPath.length > 0) {
        [self.camera startBGM:type];
    }
}

- (void)pauseEffectPropBGM:(IESEffectBGMType)type
{
    if (!_camera) {
        return;
    }
    if (![self p_verifyCameraContext]) {
        return;
    }
    NSString *currentStickerPath = [self.acc_contextInfo[AWEStikerEffectKey] isKindOfClass:[NSString class]] ? self.acc_contextInfo[AWEStikerEffectKey] : nil;
    if (currentStickerPath.length > 0) {
        [self.camera pauseBGM:type];
    }
}

- (void)muteEffectPropBGM:(BOOL)enable
{
    if (!_camera) {
        return;
    }
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera muteBGM:enable];
}

#pragma mark -

- (NSInteger)effectTextLimit
{
    if ([self.camera respondsToSelector:@selector(effectTextLimit)]) {
        return [self.camera effectTextLimit];
    }
    return 0;
}

- (void)setEffectText:(NSString *)text messageModel:(IESMMEffectMessage*)messageModel
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(setEffectText:arg1:arg2:arg3:)]) {
        [self.camera setEffectText:text arg1:(int)messageModel.arg1 arg2:(int)messageModel.arg2 arg3:[messageModel.arg3 UTF8String]];
    }
}

- (void)setInputKeyboardHide:(BOOL)boolValue
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    if ([self.camera respondsToSelector:@selector(setInputKeyboardHide:)]) {
        [self.camera setInputKeyboardHide:boolValue];
    }
}

- (void)renderPicImage:(UIImage *)photo withKey:(nonnull NSString *)key
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera renderPicImage:photo withKey:key];
}

- (void)renderPicImages:(NSArray<UIImage *> *)photos withKeys:(NSArray<NSString *> *)keys
{
    [self.camera renderPicImage:photos withKeys:keys];
}

- (void)setEffectLoadStatusBlock:(void (^)(IESStickerStatus status, NSInteger stickerId, NSString *resName))IESStickerStatusBlock
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera setEffectLoadStatusBlock:IESStickerStatusBlock];
}

- (NSArray<NSString *> *)getEffectTextArray
{
    return [self.camera getEffectTextArray];
}

- (VEEffectImage *_Nullable)getEffectCapturedImageWithKey:(NSString *)key
{
    if ([self.camera respondsToSelector:@selector(getEffectCapturedImageWithKey:)]) {
        return [self.camera getEffectCapturedImageWithKey:key];
    }
    return nil;
}

- (NSArray<NSString *> *)getAuxiliaryTextureKeys
{
    return [self.camera getAuxiliaryTextureKeys];
}

- (void)setAuxiliaryImage:(UIImage *)image withKey:(NSString *)key
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera setAuxiliaryImage:image withKey:key];
}

- (void)removeAllAuxiliaryImages
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera removeAllAuxiliaryImages];
}

- (IESComposerJudgeResult *)judgeComposerPriority:(NSString *)newNodePath tag:(NSString *)tag
{
    if (![self p_verifyCameraContext]) {
        return nil;
    }
    return [self.camera judgeComposerPriority:newNodePath tag:tag];
}

- (void *)getEffectHandle
{
    return [self.camera getEffectHandle];
}

- (void)getEffectResMultiviewTag:(const char *)featureList tag:(char *)tag
{
    if (![self p_verifyCameraContext]) {
        return;
    }
    [self.camera getEffectResMultiviewTag:featureList tag:tag];
}

- (BOOL)toggleGestureRecognition:(BOOL)enabled type:(VETouchGestureRecognitionType)type {
    if (![self p_verifyCameraContext]) {
        return NO;
    }
    return [self.camera toggleGestureRecognition:enabled type:type];
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

- (void)p_configExternalFaceMakeupOpacityIfNeeded:(IESEffectModel * _Nullable)effect
{
    if (!effect) {
        return;
    }
    
    NSDictionary *extraDict = [effect acc_analyzeSDKExtra];
    NSArray *extraDictKeys = [extraDict allKeys];
    if (![extraDictKeys containsObject:kACCNeedExternalOpacityKey] ||
        ![extraDictKeys containsObject:kACCExternalMaleOpacityKey] ||
        ![extraDictKeys containsObject:kACCExternalFemaleOpacityKey]) {
        return;
    }

    BOOL needExternalOpacity = [extraDict acc_boolValueForKey:@"needExternalOpacity"];

    CGFloat externalMaleOpacity = [extraDict acc_floatValueForKey:@"externalMaleOpacity" defaultValue:1];
    if (externalMaleOpacity < 0 || externalMaleOpacity > 1) {
        externalMaleOpacity = 1;
    }

    CGFloat externalFemaleOpacity = [extraDict acc_floatValueForKey:@"externalFemaleOpacity" defaultValue:1];
    if (externalFemaleOpacity < 0 || externalFemaleOpacity > 1) {
        externalFemaleOpacity = 1;
    }

    if (needExternalOpacity) {
        [self.camera setExternalFaceMakeupOpacity:effect.resourcePath ?: @"" maleOpacity:externalMaleOpacity femaleOpacity:externalFemaleOpacity];
    }
}

@end


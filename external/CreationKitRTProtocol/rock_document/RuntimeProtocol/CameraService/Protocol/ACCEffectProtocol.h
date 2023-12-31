//
//  ACCEffectProtocol.h
//  Pods
//
//  Created by liyingpeng on 2020/6/4.
//

#ifndef ACCEffectProtocol_h
#define ACCEffectProtocol_h

#import "ACCCameraWrapper.h"
#import <TTVideoEditor/VERecorder.h>
#import <TTVideoEditor/IESMMEffectGroup.h>

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;

@protocol AWEComposerEffectProtocol;

@protocol ACCEffectProtocol <ACCCameraWrapper>

@property (nonatomic, strong, nullable) IESEffectModel *currentSticker;
@property (nonatomic, strong, nullable) id<AWEComposerEffectProtocol> currentComposerSticker;

/*
  The following set sticker methods, with VE in the method name are common/composer coexistence, without is mutually exclusive
 */
// Set up stickers
- (void)acc_applyStickerEffect:(IESEffectModel * _Nullable)effect;
- (void)acc_applyVEStickerEffect:(IESEffectModel * _Nullable)effect;
- (void)acc_clearEffectRecordFinish;// After recording, edit, empty props and release memory
// Setting composer will clear the previous composer nodes
- (void)acc_applyComposerEffect:(id<AWEComposerEffectProtocol> _Nullable)effect extra:(NSString * _Nullable)extra;
- (void)acc_applyVEComposerEffect:(id<AWEComposerEffectProtocol> _Nullable)effect extra:(NSString * _Nullable)extra;
// Operate composer to perform only the specified operation
- (void)acc_operateComposerEffect:(id<AWEComposerEffectProtocol> _Nullable)effect operation:(IESMMComposerNodesOperation)operation extra:(NSString * _Nullable)extra;
- (void)acc_operateVEComposerEffect:(id<AWEComposerEffectProtocol> _Nullable)effect operation:(IESMMComposerNodesOperation)operation extra:(NSString * _Nullable)extra;

- (void)acc_propPlayMusic:(IESEffectModel * _Nullable)effect;

- (void)acc_musicPropStopMusic;

- (void)acc_changeMusicPropPlayStatus:(BOOL)needPlay;

- (void)acc_retainForbiddenMusicPropPlayCount;

- (void)acc_releaseForbiddenMusicPropPlayCount;

- (void)acc_playMusicIfNotBeingFobbidden;

#pragma mark - effect prop bgm control

- (void)enableEffectPropBGM:(BOOL)enable;

- (void)startEffectPropBGM:(IESEffectBGMType)type;

- (void)pauseEffectPropBGM:(IESEffectBGMType)type;

- (void)muteEffectPropBGM:(BOOL)enable;

#pragma mark -

-(NSInteger)effectTextLimit;

- (void)setEffectText:(NSString *)text messageModel:(IESMMEffectMessage *)messageModel;

- (void)setInputKeyboardHide:(BOOL)boolValue;

- (void)renderPicImage:(UIImage * _Nullable)photo withKey:(nonnull NSString *)key;

- (void)renderPicImages:(NSArray<UIImage *> * _Nullable)photos withKeys:(NSArray<NSString *> *)keys;

- (void)setEffectLoadStatusBlock:(void (^)(IESStickerStatus status, NSInteger stickerId, NSString *resName))IESStickerStatusBlock;

- (NSArray<NSString *> *)getEffectTextArray;

- (VEEffectImage *_Nullable)getEffectCapturedImageWithKey:(NSString *)key;

- (void)p_safelySetRenderCacheStringByKey:(NSString *)key value:(NSString *)value;

- (NSArray<NSString *> *)getAuxiliaryTextureKeys;

- (void)setAuxiliaryImage:(UIImage *)image withKey:(NSString *)key;

- (void)removeAllAuxiliaryImages;

- (IESComposerJudgeResult *)judgeComposerPriority:(NSString *)newNodePath tag:(NSString *)tag;

/**
get effect handle
*/
- (void *_Nullable)getEffectHandle;

- (void)getEffectResMultiviewTag:(const char *_Nonnull)featureList tag:(char *_Nonnull)tag;

#pragma mark - effect gesture

- (BOOL)toggleGestureRecognition:(BOOL)enabled type:(VETouchGestureRecognitionType)type;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCEffectProtocol_h */

//
//  ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/2/19.
//

#import <Foundation/Foundation.h>

#import <EffectPlatformSDK/IESEffectModel.h>

#import <CreationKitInfra/AWEModernStickerDefine.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelType) {
    ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelTypeNone = 0,
    ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelTypeSoundEffect,
    ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelTypeDefault // local sound effects, in case there is no online one
};

@interface ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel : NSObject

@property (nonatomic, copy) NSString *titleString;
@property (nonatomic, copy) NSArray<NSString *> *iconDownloadURLs;
@property (nonatomic, assign) ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelType modelType;
@property (nonatomic, assign, getter=isSelected) BOOL selected;
@property (nonatomic, assign) AWEEffectDownloadStatus downloadStatus;
@property (nonatomic, copy, nullable, readonly) NSString *audioPath;
@property (nonatomic, copy, nullable, readonly) NSString *soundEffect;
@property (nonatomic, assign, getter=isPlaying) BOOL playing;

- (void)configWithEffectModel:(IESEffectModel *)effectModel
                    audioText:(NSString *)audioText;
- (void)useDefaultSoundEffectWithAudioText:(NSString *)audioText;

- (void)fetchTTSAudioWithText:(NSString *)text
                   completion:(void (^)(NSError * _Nullable, NSString * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END

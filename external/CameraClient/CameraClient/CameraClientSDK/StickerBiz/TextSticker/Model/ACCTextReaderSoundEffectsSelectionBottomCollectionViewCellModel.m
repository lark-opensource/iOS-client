//
//  ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/2/19.
//

#import "ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel.h"

#import <CreativeKit/ACCMacros.h>

#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "ACCTextReadingRequestHelper.h"
#import <CreationKitInfra/ACCPathUtils.h>
#import <CreationKitInfra/ACCLogProtocol.h>

static NSString * const kDefaultSpeakerName = @"清新女声";

@interface ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel ()

@property (nonatomic, copy, nullable) IESEffectModel *effectModel;
@property (nonatomic, copy, nullable, readwrite) NSString *audioPath;
@property (nonatomic, copy) NSString *audioText;

@end

@implementation ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.modelType = ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelTypeNone;
        self.downloadStatus = AWEEffectDownloadStatusUndownloaded;
    }
    return self;
}

#pragma mark - Getters and Setters

- (nullable NSString *)audioPath
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:_audioPath]) {
        return _audioPath;
    } else {
        return nil;
    }
}

- (nullable NSString *)soundEffect
{
    if (self.modelType == ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelTypeNone) {
        return nil;
    } else if (self.modelType == ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelTypeDefault) {
        return @"xiaomei";
    } else {
        NSData *jsonData = [self.effectModel.extra dataUsingEncoding:NSUTF8StringEncoding];
        if (jsonData) {
            NSError *error = nil;
            id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
            if (error) {
                AWELogToolError2(@"text_sticker", AWELogToolTagEdit, @"text_sticker_loki_get_speakerID_failed: %@", error);
                return nil;
            }
            if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                return [jsonObject acc_stringValueForKey:@"speakerID"];
            }
        }
        return nil;
    }
}

- (NSString *)titleString
{
    if (self.modelType == ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelTypeNone) {
        return @"无";
    } else if (self.modelType == ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelTypeDefault) {
        return kDefaultSpeakerName;
    } else {
        return self.effectModel.effectName;
    }
}

#pragma mark - Private Methods

- (BOOL)isFileExist:(NSString *)text speakerID:(NSString *)speakerID
{
    NSString *filePath = [self p_generateAudioPath:text speakerID:speakerID];
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

- (NSString *)p_generateAudioPath:(NSString *)text
                        speakerID:(NSString *)speakerID
{
    NSString *tempDirPathStr = ACCTemporaryDirectory();
    tempDirPathStr = [tempDirPathStr stringByAppendingPathComponent:@"textReader/"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:tempDirPathStr]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:tempDirPathStr
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            AWELogToolError2(@"text_sticker", AWELogToolTagEdit, @"create directory failed: %@", error);
        }
    }
    NSString *fileName = [NSString stringWithFormat:
                          @"%@_%@_%@.mp3",
                          @"textReader",
                          [[text dataUsingEncoding:NSUTF8StringEncoding] acc_md5String],
                          speakerID];
    NSString *fullFilePath = [tempDirPathStr stringByAppendingPathComponent:fileName];
    return fullFilePath;
}

#pragma mark - Public Methods

- (void)configWithEffectModel:(IESEffectModel *)effectModel
                    audioText:(NSString *)audioText
{
    self.audioText = audioText;
    self.effectModel = effectModel;
    self.modelType = ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelTypeSoundEffect;
    self.iconDownloadURLs = [effectModel.iconDownloadURLs copy];
    if ([self isFileExist:self.audioText speakerID:self.soundEffect]) {
        self.audioPath = [self p_generateAudioPath:self.audioText speakerID:self.soundEffect];
        self.downloadStatus = AWEEffectDownloadStatusDownloaded;
    }
}

- (void)useDefaultSoundEffectWithAudioText:(NSString *)audioText
{
    self.effectModel = nil;
    self.modelType = ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModelTypeDefault;
    if ([self isFileExist:self.audioText speakerID:self.soundEffect]) {
        self.audioPath = [self p_generateAudioPath:self.audioText speakerID:self.soundEffect];
        self.downloadStatus = AWEEffectDownloadStatusDownloaded;
    }
}

- (void)fetchTTSAudioWithText:(NSString *)text
                   completion:(void (^)(NSError * _Nullable, NSString * _Nullable))completion
{
    if (text == nil) {
        ACCBLOCK_INVOKE(completion, nil, nil);
    }
    if (self.downloadStatus == AWEEffectDownloadStatusDownloading) {
        ACCBLOCK_INVOKE(completion, nil, nil);
    }
    
    NSString *fullFilePath = [self p_generateAudioPath:text speakerID:self.soundEffect];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullFilePath]) {
        self.audioPath = fullFilePath;
        self.downloadStatus = AWEEffectDownloadStatusDownloaded;
        ACCBLOCK_INVOKE(completion, nil, fullFilePath);
        return;
    }
    self.downloadStatus = AWEEffectDownloadStatusDownloading;
    @weakify(self);
    [[ACCTextReadingRequestHelper sharedHelper] requestTextReaderForUploadText:text
                                                                   textSpeaker:self.soundEffect
                                                                      filePath:fullFilePath
                                                               completionBlock:^(BOOL success,
                                                                                 NSString * filePath,
                                                                                 NSError * error) {
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            self.audioPath = nil;
            if (error != nil) {
                self.downloadStatus = AWEEffectDownloadStatusDownloadFail;
                AWELogToolError2(@"download_tts_audio", AWELogToolTagEdit, @"download tts audio failed: %@", error);
            } else {
                self.audioPath = filePath;
                self.downloadStatus = AWEEffectDownloadStatusDownloaded;
            }
            ACCBLOCK_INVOKE(completion, error, filePath);
        });
    }];
}

@end

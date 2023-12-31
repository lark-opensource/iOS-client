//
//  ACCStickerLogger.h
//  Pods
//
//  Created by liyingpeng on 2020/8/5.
//

#ifndef ACCStickerLogger_h
#define ACCStickerLogger_h

#import <CreationKitArch/AWEStoryTextImageModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCTextStickerLoggerClickTextReaderType) {
    ACCTextStickerLoggerClickTextReaderTypePopup = 0,
    ACCTextStickerLoggerClickTextReaderTypeEditIcon = 1
};

@protocol ACCStickerLogger <NSObject>

// text sticker

- (void)logTextStickerEditFinished:(BOOL)textAdded anchor:(BOOL)anchorAdded;

- (void)logTextStickerSocialInfoWhenAddFinishedWithTrackInfo:(NSDictionary *)trackInfo;

- (void)logTextStickerDidSelectedToolbarColorItem:(NSDictionary *)trackInfo;

- (void)logTextStickerDidSelectColor:(NSString *)colorString;

- (void)logTextStickerDidChangeTextStyle:(AWEStoryTextStyle)style;

- (void)logTextStickerDidSelectFont:(NSString *)font;

- (void)logTextStickerDidChangeAlignment:(AWEStoryTextAlignmentStyle)style;

- (void)logTextStickerViewDidTapOnce;

- (void)logTextStickerViewDidTapSecond;

- (void)logTextStickerViewWillDeleteWithEnterMethod:(NSString *)enterMethod;

- (void)logStickerViewWillDeleteWithEnterMethod:(NSString *)enterMethod;

- (void)logTextReadingBubbleShow:(BOOL)isAddedInEditView;

- (void)logTextStickerViewDidTriggeredSocialEntraceWithEntraceName:(NSString *)entraceName isMention:(BOOL)isMention;

- (void)logClickTextReading:(BOOL)isAddedInEditView type:(ACCTextStickerLoggerClickTextReaderType)type;
- (void)logCancelTextReading:(BOOL)isAddedInEditView;
- (void)logToneClick:(BOOL)isAddedInEditView
           speakerID:(NSString *)speakerID
         speakerName:(NSString *)speakerName
   isDefaultSelected:(BOOL)isDefaultSelected;
- (void)logToneCancel:(BOOL)isAddedInEditView;
- (void)logTextReadingComplete:(BOOL)isAddedInEditView
                     speakerID:(NSString *)speakerID
                   speakerName:(NSString *)speakerName;

// tags
- (void)logTagWillDeleteWithAddtionalInfo:(NSDictionary *)trackInfo;
- (void)logTagDragWithAddtionalInfo:(NSDictionary *)trackInfo;
- (void)logTagReEditWithAddtionalInfo:(NSDictionary *)trackInfo;
- (void)logTagAdjustWithAddtionalInfo:(NSDictionary *)trackInfo;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCStickerLogger_h */

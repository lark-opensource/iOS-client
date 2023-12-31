//
//  ACCStickerLoggerImpl.m
//  Pods
//
//  Created by liyingpeng on 2020/8/5.
//

#import "ACCStickerLoggerImpl.h"
#import "AWEVideoPublishViewModel+FilterEdit.h"
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoStickerModel.h>

@implementation ACCStickerLoggerImpl

- (void)logTextStickerEditFinished:(BOOL)textAdded anchor:(BOOL)anchorAdded {
    NSMutableDictionary *mParams = self.publishModel.repoTrack.referExtra.mutableCopy;
    [mParams addEntriesFromDictionary:@{
        @"text_added": textAdded ? @(1) : @(0),
        @"anchor_added" : anchorAdded ? @(1) : @(0),
        @"anchor_type" : @"wiki"
    }];
    [ACCTracker() trackEvent:@"text_complete" params:mParams needStagingFlag:NO];
}

- (void)logTextStickerDidSelectColor:(NSString *)colorString {
    NSMutableDictionary *params = [@{@"color" : colorString ?: @""} mutableCopy];
    [params addEntriesFromDictionary:self.publishModel.repoTrack.referExtra];
    [ACCTracker() trackEvent:@"select_text_color" params:params needStagingFlag:NO];
}

- (void)logTextStickerDidChangeTextStyle:(AWEStoryTextStyle)style {
    NSMutableDictionary *params = [@{
                                     @"text_style" : @(style)
                                     }
                                   mutableCopy];
    [params addEntriesFromDictionary:self.publishModel.repoTrack.referExtra];
    [ACCTracker() trackEvent:@"select_text_style" params:params needStagingFlag:NO];
}

- (void)logTextStickerDidSelectFont:(NSString *)font {
    NSMutableDictionary *params = [@{
                                     @"font" : font ?: @"",
                                     }
                                   mutableCopy];
    [params addEntriesFromDictionary:self.publishModel.repoTrack.referExtra];
    [ACCTracker() trackEvent:@"select_text_font" params:params needStagingFlag:NO];
}

- (void)logTextStickerDidChangeAlignment:(AWEStoryTextAlignmentStyle)style {
    NSString *styleStr = @"center";
    if (style == AWEStoryTextAlignmentLeft) {
        styleStr = @"left";
    } else if (style == AWEStoryTextAlignmentRight) {
        styleStr = @"right";
    }
    NSMutableDictionary *params = [@{
                                     @"paragraph_style" : styleStr,
                                     }
                                   mutableCopy];
    [params addEntriesFromDictionary:self.publishModel.repoTrack.referExtra];
    [ACCTracker() trackEvent:@"select_text_paragraph" params:params needStagingFlag:NO];
}

- (void)logTextStickerViewDidTapOnce {
    [ACCTracker() trackEvent:@"text_more_click" params:self.publishModel.repoTrack.referExtra needStagingFlag:NO];
}

- (void)logTextStickerViewDidTapSecond {
    NSMutableDictionary *params = [@{} mutableCopy];
    [params addEntriesFromDictionary:self.publishModel.repoTrack.referExtra];
    [params setValue:@"click_text" forKey:@"enter_method"];
    [ACCTracker() trackEvent:@"click_text_entrance" params:params needStagingFlag:NO];
}

- (void)logTextStickerViewWillDeleteWithEnterMethod:(NSString *)enterMethod {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:@{@"enter_from" : self.publishModel.repoTrack.enterFrom? : @"",
                                                                                      @"is_subtitle": @(0)}];
    [self.publishModel trackPostEvent:@"text_delete"
                          enterMethod:enterMethod
                            extraInfo:attributes];
}

- (void)logStickerViewWillDeleteWithEnterMethod:(NSString *)enterMethod {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:@{@"enter_from" : self.publishModel.repoTrack.enterFrom? : @""}];
    [self.publishModel trackPostEvent:@"prop_delete"
                          enterMethod:enterMethod
                            extraInfo:attributes];
}

- (void)logTextReadingBubbleShow:(BOOL)isAddedInEditView {
    [ACCTracker() trackEvent:@"text_reading_bubble_show" params:@{
        @"enter_from":@"video_edit_page",
        @"shoot_way":self.publishModel.repoTrack.referString?:@"",
        @"creation_id":self.publishModel.repoContext.createId ?:@"",
        @"content_source":self.publishModel.repoTrack.referExtra[@"content_source"]?:@"",
        @"content_type":self.publishModel.repoTrack.referExtra[@"content_type"]?:@"",
        @"is_text_reading":@(self.publishModel.repoSticker.textReadingAssets.count),
        @"text_type":isAddedInEditView ? @"general_mode" : @"text_mode"
    }];
}

- (void)logClickTextReading:(BOOL)isAddedInEditView type:(ACCTextStickerLoggerClickTextReaderType)type {
    NSMutableDictionary *params = [@{
        @"enter_from":@"video_edit_page",
        @"shoot_way":self.publishModel.repoTrack.referString?:@"",
        @"creation_id":self.publishModel.repoContext.createId ?:@"",
        @"content_source":self.publishModel.repoTrack.referExtra[@"content_source"]?:@"",
        @"content_type":self.publishModel.repoTrack.referExtra[@"content_type"]?:@"",
        @"is_text_reading":@(self.publishModel.repoSticker.textReadingAssets.count),
        @"text_type":isAddedInEditView ? @"general_mode" : @"text_mode"
    } mutableCopy];
    if (type == ACCTextStickerLoggerClickTextReaderTypePopup) {
        [params setValue:@"text_popup" forKey:@"enter_method"];
    } else if (type == ACCTextStickerLoggerClickTextReaderTypeEditIcon) {
        [params setValue:@"text_edit_icon" forKey:@"enter_method"];
    }
    [ACCTracker() trackEvent:@"click_text_reading" params:[params copy]];
}

- (void)logCancelTextReading:(BOOL)isAddedInEditView
{
    [ACCTracker() trackEvent:@"cancel_text_reading" params:@{
        @"enter_from":@"video_edit_page",
        @"shoot_way":self.publishModel.repoTrack.referString?:@"",
        @"creation_id":self.publishModel.repoContext.createId ?:@"",
        @"content_source":self.publishModel.repoTrack.referExtra[@"content_source"]?:@"",
        @"content_type":self.publishModel.repoTrack.referExtra[@"content_type"]?:@"",
        @"is_text_reading":@(self.publishModel.repoSticker.textReadingAssets.count),
        @"text_type":isAddedInEditView ? @"general_mode" : @"text_mode"
    }];
}

- (void)logToneClick:(BOOL)isAddedInEditView
           speakerID:(NSString *)speakerID
         speakerName:(NSString *)speakerName
   isDefaultSelected:(BOOL)isDefaultSelected
{
    NSMutableDictionary *params = [@{
        @"enter_from":@"video_edit_page",
        @"shoot_way":self.publishModel.repoTrack.referString?:@"",
        @"creation_id":self.publishModel.repoContext.createId ?:@"",
        @"content_source":self.publishModel.repoTrack.referExtra[@"content_source"]?:@"",
        @"content_type":self.publishModel.repoTrack.referExtra[@"content_type"]?:@"",
        @"is_text_reading":@(self.publishModel.repoSticker.textReadingAssets.count),
        @"text_type":isAddedInEditView ? @"general_mode" : @"text_mode",
        @"is_selected":isDefaultSelected ? @(1) : @(0)
    } mutableCopy];
    if (speakerID != nil) {
        [params setValue:speakerID forKey:@"tone_id"];
        if (speakerName != nil) {
            [params setValue:speakerName forKey:@"tone_name"];
        }
    }
    [ACCTracker() trackEvent:@"tone_click" params:[params copy]];
}

- (void)logToneCancel:(BOOL)isAddedInEditView
{
    [ACCTracker() trackEvent:@"tone_cancel" params:@{
        @"enter_from":@"video_edit_page",
        @"shoot_way":self.publishModel.repoTrack.referString?:@"",
        @"creation_id":self.publishModel.repoContext.createId ?:@"",
        @"content_source":self.publishModel.repoTrack.referExtra[@"content_source"]?:@"",
        @"content_type":self.publishModel.repoTrack.referExtra[@"content_type"]?:@"",
        @"is_text_reading":@(self.publishModel.repoSticker.textReadingAssets.count),
        @"text_type":isAddedInEditView ? @"general_mode" : @"text_mode"
    }];
}

- (void)logTextReadingComplete:(BOOL)isAddedInEditView
                     speakerID:(NSString *)speakerID
                   speakerName:(NSString *)speakerName
{
    NSMutableDictionary *params = [@{
        @"enter_from":@"video_edit_page",
        @"shoot_way":self.publishModel.repoTrack.referString?:@"",
        @"creation_id":self.publishModel.repoContext.createId ?:@"",
        @"content_source":self.publishModel.repoTrack.referExtra[@"content_source"]?:@"",
        @"content_type":self.publishModel.repoTrack.referExtra[@"content_type"]?:@"",
        @"is_text_reading":@(self.publishModel.repoSticker.textReadingAssets.count),
        @"text_type":isAddedInEditView ? @"general_mode" : @"text_mode"
    } mutableCopy];
    if (speakerID != nil) {
        [params setValue:speakerID forKey:@"tone_id"];
        if (speakerName != nil) {
            [params setValue:speakerName forKey:@"tone_name"];
        }
    }
    [ACCTracker() trackEvent:@"text_reading_complete" params:[params copy]];
}

- (void)logTextStickerViewDidTriggeredSocialEntraceWithEntraceName:(NSString *)entraceName isMention:(BOOL)isMention
{
    [ACCTracker() trackEvent:isMention? @"click_at_entrance" : @"click_tag_entrance" params:[self p_commonTrackInfoWithExtraTrackInfo:@{@"enter_method" : entraceName?:@""}]];
}

- (void)logTextStickerSocialInfoWhenAddFinishedWithTrackInfo:(NSDictionary *)trackInfo
{
    [ACCTracker() trackEvent:@"add_hashtag_at_sticker" params:[self p_commonTrackInfoWithExtraTrackInfo:trackInfo]];
}

- (void)logTextStickerDidSelectedToolbarColorItem:(NSDictionary *)trackInfo
{
    [ACCTracker() trackEvent:@"change_text_mode" params:[self p_commonTrackInfoWithExtraTrackInfo:trackInfo]];
}

- (nonnull NSDictionary *)mediaCountInfo
{
    return [self.publishModel.repoTrack mediaCountInfo]? : @{};
}

- (void)logTagWillDeleteWithAddtionalInfo:(NSDictionary *)trackInfo
{
    NSMutableDictionary *dictionary = [[self p_commonTrackInfoWithExtraTrackInfo:trackInfo] mutableCopy];
    [dictionary addEntriesFromDictionary:[self mediaCountInfo]];
    [ACCTracker() trackEvent:@"tag_delete" params:dictionary];
}

- (void)logTagDragWithAddtionalInfo:(NSDictionary *)trackInfo
{
    NSMutableDictionary *dictionary = [[self p_commonTrackInfoWithExtraTrackInfo:trackInfo] mutableCopy];
    [dictionary addEntriesFromDictionary:[self mediaCountInfo]];
    [ACCTracker() trackEvent:@"tag_drag" params:dictionary];
}

- (void)logTagReEditWithAddtionalInfo:(NSDictionary *)trackInfo
{
    NSMutableDictionary *dictionary = [[self p_commonTrackInfoWithExtraTrackInfo:trackInfo] mutableCopy];
    [dictionary addEntriesFromDictionary:[self mediaCountInfo]];
    [ACCTracker() trackEvent:@"tag_reedit" params:dictionary];
}

- (void)logTagAdjustWithAddtionalInfo:(NSDictionary *)trackInfo
{
    NSMutableDictionary *dictionary = [[self p_commonTrackInfoWithExtraTrackInfo:trackInfo] mutableCopy];
    [dictionary addEntriesFromDictionary:[self mediaCountInfo]];
    [ACCTracker() trackEvent:@"tag_adjust" params:dictionary];
}

- (NSDictionary *)p_commonTrackInfoWithExtraTrackInfo:(NSDictionary *)trackInfo
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_from"] = self.publishModel.repoTrack.enterFrom?:@"video_edit_page";
    [params addEntriesFromDictionary:self.publishModel.repoTrack.referExtra?:@{}];
    [params addEntriesFromDictionary:trackInfo?:@{}];
    return [params copy];
}

@end

//
//  ACCToolBarSortDataSource.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/7.
//

#import "ACCToolBarSortDataSource.h"
#import "ACCToolBarContainerPageEnum.h"
#import "ACCToolBarAdapterUtils.h"

#import <CreationKitArch/ACCRecorderToolBarDefines.h>
#import <CameraClient/ACCRecorderToolBarDefinesD.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import "ACCVideoEditToolBarDefinition.h"

#import <CameraClient/ACCConfigKeyDefines.h>

@interface ACCToolBarSortDataSource ()
@property (nonatomic, copy) NSArray *settingsRecordList;
@property (nonatomic, copy) NSArray *settingsEditList;
@property (nonatomic, copy) NSArray *settingsRecordRedDotList;
@property (nonatomic, copy) NSArray *settingsEditRedDotList;
@property (nonatomic, copy) NSDictionary *mapEdit;
@property (nonatomic, copy) NSDictionary *mapRecord;
@end

@implementation ACCToolBarSortDataSource

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self getSettingsArray];
    }
    return self;
}

- (void)getSettingsArray
{
    NSDictionary *dict = ACCConfigDict(kConfigDict_studio_optim_sidebar_list);
    self.settingsRecordList = [self settingsToList:[dict btd_arrayValueForKey:@"record_sidebar_list"] isEdit:NO];
    self.settingsRecordRedDotList = [self settingsToList:[dict btd_arrayValueForKey:@"record_sidebar_reddot"] isEdit: NO];
    self.settingsEditList = [self settingsToList:[dict btd_arrayValueForKey:@"edit_sidebar_list"] isEdit:YES];
    self.settingsEditRedDotList = [self settingsToList:[dict btd_arrayValueForKey:@"edit_sidebar_reddot"] isEdit:YES];
}

- (NSArray *)settingsToList:(NSArray *)settings isEdit:(BOOL)isEdit
{
    if (BTD_isEmptyArray(settings)) {
        return nil;
    }
    NSMutableArray *settingsOrder = [NSMutableArray array];
    NSDictionary *map = isEdit ? self.mapEdit : self.mapRecord;

    // settings order
    [settings enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            if ([map valueForKey:obj]) {
                [settingsOrder addObject:[map valueForKey:obj]];
            }
        }
    }];

    // conbine with default order
    NSArray *defaultOrder = isEdit ? self.defaultSortArrayEdit : self.defaultSortArrayRecord;
    NSMutableArray *targetOrder = [NSMutableArray arrayWithArray:defaultOrder];
    [targetOrder sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSComparisonResult result = NSOrderedSame;
        NSUInteger index1 = [settingsOrder indexOfObject:obj1];
        NSUInteger index2 = [settingsOrder indexOfObject:obj2];
        if (index1 != NSNotFound && index2!= NSNotFound) {
            result = [@(index1) compare:@(index2)];
        }
        return result;
    }];
    return  [targetOrder count] > 0 ? targetOrder : nil;
}

- (nonnull NSArray *)barItemSortArray
{
    return @[];
}

- (nonnull NSArray *)barItemSortArrayWithPage:(ACCToolBarContainerPageEnum)page
{
    if (page == ACCToolBarContainerPageEnumRecorder || page == ACCToolBarContainerPageEnumIMRecorder) {
        if ([ACCToolBarAdapterUtils modifyOrder] && self.settingsRecordList != nil) {
            return self.settingsRecordList;
        }
        return [self defaultSortArrayRecord];
    } else if (page == ACCToolBarContainerPageEnumEdit || page == ACCToolBarContainerPageEnumIMEdit) {
        if ([ACCToolBarAdapterUtils modifyOrder] && self.settingsEditList != nil) {
            return self.settingsEditList;
        }
        return [self defaultSortArrayEdit];
    } else {
        return self.barItemSortArray;
    }
}

- (nullable NSArray *)barItemRedPointArrayWithPage:(ACCToolBarContainerPageEnum)page
{
    if (page == ACCToolBarContainerPageEnumRecorder || page == ACCToolBarContainerPageEnumIMRecorder) {
        return self.settingsRecordRedDotList ?: nil;
    } else if (page == ACCToolBarContainerPageEnumEdit || page == ACCToolBarContainerPageEnumIMEdit) {
        return self.settingsEditRedDotList ?: nil;
    }
    return nil;
}

- (nonnull NSArray *)defaultSortArrayEdit
{
    if (ACCConfigInt(kConfigInt_editor_toolbar_optimize) != ACCStoryEditorOptimizeTypeNone) {
        return @[
            [NSValue valueWithPointer:ACCEditToolBarRedpacketContext],
            [NSValue valueWithPointer:ACCEditToolBarPublishSettingsContext],
            [NSValue valueWithPointer:ACCEditToolBarQuickSaveDraftContext],
            [NSValue valueWithPointer:ACCEditToolBarQuickSavePrivateContext],
            [NSValue valueWithPointer:ACCEditToolBarQuickSaveAlbumContext],
            [NSValue valueWithPointer:ACCEditToolBarClipContext],
            [NSValue valueWithPointer:ACCEditToolBarSelectTemplateContext],
            [NSValue valueWithPointer:ACCEditToolBarMusicContext],
            [NSValue valueWithPointer:ACCEditToolBarImage2VideoContext],
            [NSValue valueWithPointer:ACCEditToolBarVideo2ImageContext],
            [NSValue valueWithPointer:ACCEditToolBarTagsContext],
            [NSValue valueWithPointer:ACCEditToolBarCropImageContext],
            [NSValue valueWithPointer:ACCEditToolBarSmartMovieContext],
            [NSValue valueWithPointer:ACCEditToolBarTextContext],
            [NSValue valueWithPointer:ACCEditToolBarInfoStickerContext],
            [NSValue valueWithPointer:ACCEditToolBarEffectContext],
            [NSValue valueWithPointer:ACCEditToolBarFilterContext],
            [NSValue valueWithPointer:ACCEditToolBarBeautyContext],
            [NSValue valueWithPointer:ACCEditToolBarSoundContext],
            [NSValue valueWithPointer:ACCEditToolBarMeteorModeContext],
            //folded
            [NSValue valueWithPointer:ACCEditToolBarAutoCaptionContext],
            [NSValue valueWithPointer:ACCEditToolBarVideoEnhanceContext],
            [NSValue valueWithPointer:ACCEditToolBarVoiceChangeContext],
            [NSValue valueWithPointer:ACCEditToolBarMusicCutContext],
            [NSValue valueWithPointer:ACCEditToolBarVideoDubContext],
        ];
    }
    return @[
        [NSValue valueWithPointer:ACCEditToolBarRedpacketContext],
        [NSValue valueWithPointer:ACCEditToolBarPublishSettingsContext],
        [NSValue valueWithPointer:ACCEditToolBarQuickSaveDraftContext],
        [NSValue valueWithPointer:ACCEditToolBarQuickSavePrivateContext],
        [NSValue valueWithPointer:ACCEditToolBarQuickSaveAlbumContext],
        [NSValue valueWithPointer:ACCEditToolBarClipContext],
        [NSValue valueWithPointer:ACCEditToolBarSelectTemplateContext],
        [NSValue valueWithPointer:ACCEditToolBarStatusBgImageContext],
        [NSValue valueWithPointer:ACCEditToolBarMusicContext],
        [NSValue valueWithPointer:ACCEditToolBarImage2VideoContext],
        [NSValue valueWithPointer:ACCEditToolBarVideo2ImageContext],
        [NSValue valueWithPointer:ACCEditToolBarTagsContext],
        [NSValue valueWithPointer:ACCEditToolBarCropImageContext],
        [NSValue valueWithPointer:ACCEditToolBarSmartMovieContext],
        [NSValue valueWithPointer:ACCEditToolBarEffectContext],
        [NSValue valueWithPointer:ACCEditToolBarTextContext],
        [NSValue valueWithPointer:ACCEditToolBarInfoStickerContext],

        [NSValue valueWithPointer:ACCEditToolBarFilterContext],
        [NSValue valueWithPointer:ACCEditToolBarBeautyContext],
        [NSValue valueWithPointer:ACCEditToolBarVideoEnhanceContext],
        [NSValue valueWithPointer:ACCEditToolBarVoiceChangeContext],
        [NSValue valueWithPointer:ACCEditToolBarVideoDubContext],
        [NSValue valueWithPointer:ACCEditToolBarAutoCaptionContext],
        [NSValue valueWithPointer:ACCEditToolBarMusicCutContext],
        [NSValue valueWithPointer:ACCEditToolBarSoundContext],
        [NSValue valueWithPointer:ACCEditToolBarMeteorModeContext],
    ];
}

- (nonnull NSArray *)defaultSortArrayRecord
{
    return @[[NSValue valueWithPointer:ACCRecorderToolBarAdvancedSettingContext],
      [NSValue valueWithPointer:ACCRecorderToolBarSwapContext],
      [NSValue valueWithPointer:ACCRecorderToolBarSpeedControlContext],
      [NSValue valueWithPointer:ACCRecorderToolBarFilterContext],
      [NSValue valueWithPointer:ACCRecorderToolBarMeteorModeContext],
      [NSValue valueWithPointer:ACCRecorderToolBarModernBeautyContext],
      [NSValue valueWithPointer:ACCRecorderToolBarDelayRecordContext],
      [NSValue valueWithPointer:ACCRecorderToolBarDuetLayoutContext],
      [NSValue valueWithPointer:ACCRecorderToolBarMicrophoneContext],
      [NSValue valueWithPointer:ACCRecorderToolBarFlashContext],
      [NSValue valueWithPointer:ACCRecorderToolBarInspirationContext],
      [NSValue valueWithPointer:ACCRecorderToolBarRecognitionContext],
      [NSValue valueWithPointer:ACCRecorderToolBarEarBackContext],
    ];

}

- (NSDictionary *)mapEdit
{
    if (!_mapEdit) {
        _mapEdit = @{
            @"red_packet" : [NSValue valueWithPointer:ACCEditToolBarRedpacketContext],
            @"wish_module" : [NSValue valueWithPointer:ACCEditToolBarNewYearModuleContext],
            @"wish_text" : [NSValue valueWithPointer:ACCEditToolBarNewYearTextContext],
            @"ktv_tuning" : [NSValue valueWithPointer:ACCEditToolBarKaraokeConfigContext], // k歌调音
            @"ktv_change_template" : [NSValue valueWithPointer:ACCEditToolBarKaraokeBGConfigContext], //k歌背景
            @"text" : [NSValue valueWithPointer:ACCEditToolBarTextContext],
            @"effect" : [NSValue valueWithPointer:ACCEditToolBarEffectContext],
            @"auto_caption" : [NSValue valueWithPointer:ACCEditToolBarAutoCaptionContext],
            @"sticker" : [NSValue valueWithPointer:ACCEditToolBarInfoStickerContext],
            @"filter" : [NSValue valueWithPointer:ACCEditToolBarFilterContext],
            @"beauty" : [NSValue valueWithPointer:ACCEditToolBarBeautyContext],
            @"publish_settings" : [NSValue valueWithPointer:ACCEditToolBarPublishSettingsContext],
            @"quick_save_draft" : [NSValue valueWithPointer:ACCEditToolBarQuickSaveDraftContext],
            @"quick_publish_private" : [NSValue valueWithPointer:ACCEditToolBarQuickSavePrivateContext],
            @"quick_save_album" : [NSValue valueWithPointer:ACCEditToolBarQuickSaveAlbumContext],
            @"volume" : [NSValue valueWithPointer:ACCEditToolBarSoundContext],
            @"video_enhance" : [NSValue valueWithPointer:ACCEditToolBarVideoEnhanceContext],
            @"clip" : [NSValue valueWithPointer:ACCEditToolBarClipContext],
            @"image_to_video" : [NSValue valueWithPointer:ACCEditToolBarImage2VideoContext],
            @"video_to_image" : [NSValue valueWithPointer:ACCEditToolBarVideo2ImageContext],
            @"tags" : [NSValue valueWithPointer:ACCEditToolBarTagsContext],
            @"crop_image" : [NSValue valueWithPointer:ACCEditToolBarCropImageContext],
            @"audio_record" : [NSValue valueWithPointer:ACCEditToolBarVideoDubContext], // 配音
            @"select_template" : [NSValue valueWithPointer:ACCEditToolBarSelectTemplateContext],
            @"smart_movie" : [NSValue valueWithPointer:ACCEditToolBarSmartMovieContext],
            @"cut_music" : [NSValue valueWithPointer:ACCEditToolBarMusicCutContext],
            @"music" : [NSValue valueWithPointer:ACCEditToolBarMusicContext],
            @"voice_change" : [NSValue valueWithPointer:ACCEditToolBarVoiceChangeContext],
            @"meteor" : [NSValue valueWithPointer:ACCEditToolBarMeteorModeContext] //一闪而过
        };
    }
    return _mapEdit;
}

- (NSDictionary *)mapRecord
{
    if (!_mapRecord) {
        _mapRecord = @{
            // record
            @"switching" : [NSValue valueWithPointer:ACCRecorderToolBarSwapContext],
            @"countdown" : [NSValue valueWithPointer:ACCRecorderToolBarDelayRecordContext],
            @"beauty" : [NSValue valueWithPointer:ACCRecorderToolBarModernBeautyContext],
            @"filter" : [NSValue valueWithPointer:ACCRecorderToolBarFilterContext],
            @"speed" : [NSValue valueWithPointer:ACCRecorderToolBarSpeedControlContext],
            @"duet" : [NSValue valueWithPointer:ACCRecorderToolBarDuetLayoutContext],
            @"meteor" : [NSValue valueWithPointer:ACCRecorderToolBarMeteorModeContext], //一闪而过
            @"microphone" : [NSValue valueWithPointer:ACCRecorderToolBarMicrophoneContext],
            //"aspect_ratio" : [NSValue valueWithPointer:],//多画幅, 代码已下线
            //"aiargument" : [NSValue valueWithPointer:], //安卓设备的能力
            //"wide_angle" : [NSValue valueWithPointer:], //安卓 广角
            @"flash" : [NSValue valueWithPointer:ACCRecorderToolBarFlashContext],
            //"anti_shake" : [NSValue valueWithPointer:], //防抖
            //"inspire" : [NSValue valueWithPointer:] //inspire 下线
        };
    }
    return _mapRecord;
}

- (NSArray *)typeBItemsArray
{
    return @[
             [NSValue valueWithPointer:ACCEditToolBarRedpacketContext],
             [NSValue valueWithPointer:ACCRecorderToolBarSwapContext],
             [NSValue valueWithPointer:ACCRecorderToolBarSpeedControlContext],
             [NSValue valueWithPointer:ACCRecorderToolBarMicrophoneContext],
             [NSValue valueWithPointer:ACCRecorderToolBarFlashContext],
             [NSValue valueWithPointer:ACCEditToolBarPublishSettingsContext],
             [NSValue valueWithPointer:ACCEditToolBarQuickSaveDraftContext],
             [NSValue valueWithPointer:ACCEditToolBarQuickSavePrivateContext],
             [NSValue valueWithPointer:ACCEditToolBarQuickSaveAlbumContext],
             [NSValue valueWithPointer:ACCEditToolBarSoundContext],
             [NSValue valueWithPointer:ACCEditToolBarVideoEnhanceContext],
             [NSValue valueWithPointer:ACCEditToolBarImage2VideoContext],
             [NSValue valueWithPointer:ACCEditToolBarVideo2ImageContext],
             [NSValue valueWithPointer:ACCEditToolBarTagsContext],
             [NSValue valueWithPointer:ACCEditToolBarCropImageContext],
             [NSValue valueWithPointer:ACCEditToolBarMusicCutContext],
             [NSValue valueWithPointer:ACCEditToolBarMusicContext],
             [NSValue valueWithPointer:ACCEditToolBarVoiceChangeContext],
             [NSValue valueWithPointer:ACCRecorderToolBarEarBackContext]
    ];
}

- (NSArray *)typeAItemsArray
{
    return @[
        [NSValue valueWithPointer:ACCEditToolBarRedpacketContext],
        [NSValue valueWithPointer:ACCRecorderToolBarDelayRecordContext],
        [NSValue valueWithPointer:ACCRecorderToolBarModernBeautyContext],
        [NSValue valueWithPointer:ACCRecorderToolBarFilterContext],
        [NSValue valueWithPointer:ACCRecorderToolBarDuetLayoutContext],
        [NSValue valueWithPointer:ACCEditToolBarKaraokeConfigContext],
        [NSValue valueWithPointer:ACCEditToolBarKaraokeBGConfigContext],
        [NSValue valueWithPointer:ACCEditToolBarTextContext],
        [NSValue valueWithPointer:ACCEditToolBarEffectContext],
        [NSValue valueWithPointer:ACCEditToolBarAutoCaptionContext],
        [NSValue valueWithPointer:ACCEditToolBarInfoStickerContext],
        [NSValue valueWithPointer:ACCEditToolBarFilterContext],
        [NSValue valueWithPointer:ACCEditToolBarBeautyContext],
        [NSValue valueWithPointer:ACCEditToolBarClipContext],
        [NSValue valueWithPointer:ACCEditToolBarSelectTemplateContext],
        [NSValue valueWithPointer:ACCRecorderToolBarEarBackContext]
    ];
}

@end

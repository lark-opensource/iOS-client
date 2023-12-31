//
//  ACCPersonalRecommendWords.m
//  Indexer
//
//  Created by raomengyun on 2021/11/29.
//

#import "ACCPersonalRecommendWords.h"
#import "ACCMainServiceProtocol.h"

#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/ACCLanguageProtocol.h>

@implementation ACCPersonalRecommendWords

+ (NSString *)wordsWithKey:(NSString *)key
{
    NSDictionary *textList = [IESAutoInline(ACCBaseServiceProvider(), ACCMainServiceProtocol) isPersonalRecommendSwitchOn] ?
        [self _onTextList] : [self _offTextList];
    NSString *words = [textList acc_stringValueForKey:key];
    
    NSAssert(words.length > 0, @"words of key: %@ is not config!", key);
    return words;
}

+ (NSDictionary *)_onTextList
{
    return @{
        @"karaoke_search_music_header": @"为你推荐",
        @"karaoke_music_panel_volume": @"使用推荐音量",
        @"cutsame_select_template": @"推荐模板",
        @"sticker_picker_hastag_view": @"猜你想搜",
        @"music_search_music_list": ACCLocalizedCurrentString(@"dmt_av_impl_recommend"),
        @"social_sticker_hashtag_header": @"推荐话题",
        @"edit_music_panel_header": ACCLocalizedString(@"dmt_av_impl_recommend", @"dmt_av_impl_recommend"),
        @"publish_cover_choose_title": @"添加推荐标题，能获得更多播放"
    };
}

+ (NSDictionary *)_offTextList
{
    return @{
        @"karaoke_search_music_header": @"大家都在搜",
        @"karaoke_music_panel_volume": @"使用建议音量",
        @"cutsame_select_template": @"模板列表",
        @"sticker_picker_hastag_view": @"大家都在搜",
        @"music_search_music_list": @"热门",
        @"social_sticker_hashtag_header": @"话题",
        @"edit_music_panel_header": @"热门",
        @"publish_cover_choose_title": @"添加标题，能获得更多播放"
    };
}

@end

//
//  ACCStickerHandler+SocialData.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/3/24.
//

#import "ACCStickerHandler+SocialData.h"
#import "ACCStickerBizDefines.h"
#import "ACCSocialStickerView.h"
#import "ACCTextStickerView.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitArch/ACCTextStickerExtraModel.h>

@implementation ACCStickerHandler (SocialData)

- (NSInteger)allMentionCountInSticker
{
    return [self p_getSocialCountWithIsGetMention:YES];
}

- (NSInteger)allHashtahCountInSticker
{
    return [self p_getSocialCountWithIsGetMention:NO];
}

- (NSInteger)p_getSocialCountWithIsGetMention:(BOOL)isGetMention
{
    NSInteger count = 0;
    
    NSArray <ACCStickerViewType > *socialStickers = [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdSocial] acc_filter:^BOOL(ACCStickerViewType  _Nonnull item) {
        return [item.contentView isKindOfClass:[ACCSocialStickerView class]];
    }];
    
    for (UIView<ACCStickerProtocol> *sticker in socialStickers) {
  
        ACCSocialStickerView *socialView = (ACCSocialStickerView *)(sticker.contentView);
        if (![socialView isKindOfClass:[ACCSocialStickerView class]]) {
            continue;
        }
        if (isGetMention) {
            if (socialView.stickerType == ACCSocialStickerTypeMention) {
                count ++;
            }
        } else {
            if (socialView.stickerType == ACCSocialStickerTypeHashTag) {
                count ++;
            }
        }
    }
    
    NSArray <ACCStickerViewType > *textStickers = [[self.stickerContainerView stickerViewsWithTypeId:ACCStickerTypeIdText] acc_filter:^BOOL(ACCStickerViewType  _Nonnull item) {
        return [item.contentView isKindOfClass:[ACCTextStickerView class]];
    }];
    
    for (UIView<ACCStickerProtocol> *sticker in textStickers) {
  
        ACCTextStickerView *textView = (ACCTextStickerView *)(sticker.contentView);
        if (![textView isKindOfClass:[ACCTextStickerView class]]) {
            continue;
        }
        count += [ACCTextStickerExtraModel numberOfValidExtrasInList:textView.textModel.extraInfos forType:isGetMention ? ACCTextStickerExtraTypeMention:ACCTextStickerExtraTypeHashtag];
    }
    
    return count;
}

@end

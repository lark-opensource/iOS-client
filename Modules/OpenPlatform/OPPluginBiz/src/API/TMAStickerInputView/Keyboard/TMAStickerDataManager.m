//
//  TMAStickerDataManager.m
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/17.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import "TMAStickerDataManager.h"
#import <OPFoundation/OPBundle.h>
#import "NSAttributedString+TMASticker.h"
#import "TMASticker.h"
#import "TMATextBackedString.h"
#import <OPFoundation/UIImage+EMA.h>
#import <OPPluginBiz/OPPluginBiz-Swift.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/BDPUtils.h>

@interface TMAStickerMatchingResult : NSObject
@property (nonatomic, assign) NSRange range;                    // 匹配到的表情包文本的range
@property (nonatomic, strong) UIImage *emojiImage;              // 如果能在本地找到emoji的图片，则此值不为空
@property (nonatomic, strong) NSString *showingDescription;     // 表情的实际文本(形如：[哈哈])，不为空
@end

@implementation TMAStickerMatchingResult
@end

@interface TMAStickerDataManager ()
@property (nonatomic, strong, readwrite) NSArray<TMASticker *> *allStickers;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *opEmojiMap;
@end

@implementation TMAStickerDataManager

static NSString * const kCoverImageName = @"tma_emoji";

+ (instancetype)sharedInstance {
    static TMAStickerDataManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TMAStickerDataManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self initStickers];
    }
    return self;
}

- (void)initStickers {
    // OP EMOJI的描述对应的主端资源的key
    self.opEmojiMap = @{
        @"微笑": @"SMILE",
        @"爱慕": @"DROOL",
        @"惊呆": @"SCOWL",
        @"酷拽": @"HAUGHTY",
        @"抠鼻": @"NOSEPICK",
        @"流泪": @"SOB",
        @"发怒": @"ANGRY",
        @"呲牙": @"BLUSH",
        @"鼾睡": @"SLEEP",
        @"害羞": @"SHY",
        @"可爱": @"WINK",
        @"晕": @"DIZZY",
        @"衰": @"TOASTED",
        @"闭嘴": @"SILENT",
        @"机智": @"SMART",
        @"来看我": @"ATTENTION",
        @"灵光一闪": @"WITTY",
        @"耶": @"YEAH",
        @"捂脸": @"FACEPALM",
        @"打脸": @"SLAP",
        @"大笑": @"LAUGH",
        @"哈欠": @"YAWN",
        @"震惊": @"SHOCKED",
        @"送心": @"LOVE",
        @"困": @"DROWSY",
        @"what": @"WHAT",
        @"泣不成声": @"CRY",
        @"小鼓掌": @"CLAP",
        @"酷": @"SHOWOFF",
        @"偷笑": @"CHUCKLE",
        @"石化": @"PETRIFIED",
        @"思考": @"THINKING",
        @"吐血": @"SPITBLOOD",
        @"可怜": @"WHIMPER",
        @"嘘": @"SHHH",
        @"撇嘴": @"SMUG",
        @"黑线": @"ERROR",
        @"笑哭": @"LOL",
        @"雾霾": @"SICK",
        @"奸笑": @"SMIRK",
        @"得意": @"PROUD",
        @"憨笑": @"TRICK",
        @"抓狂": @"CRAZY",
        @"泪奔": @"TEARS",
        @"钱": @"MONEY",
        @"吻": @"KISS",
        @"恐惧": @"TERROR",
        @"笑": @"JOYFUL",
        @"快哭了": @"BLUBBER",
        @"翻白眼": @"HUSKY",
        @"互粉": @"FOLLOWME",
        @"赞": @"THUMBSUP",
        @"鼓掌": @"APPLAUSE",
        @"谢谢": @"THANKS",
        @"去污粉": @"DETERGENT",
        @"666": @"AWESOME",
        @"玫瑰": @"ROSE",
        @"胡瓜": @"CUCUMBER",
        @"啤酒": @"BEER",
        @"我想静静": @"ENOUGH",
        @"委屈": @"WRONGED",
        @"舔屏": @"OBSESSED",
        @"鄙视": @"LOOKDOWN",
        @"飞吻": @"SMOOCH",
        @"再见": @"WAVE",
        @"紫薇别走": @"DONNOTGO",
        @"听歌": @"HEADSET",
        @"求抱抱": @"HUG",
        @"周冬雨的凝视": @"DULLSTARE",
        @"马思纯的微笑": @"INNOCENTSMILE",
        @"吐舌": @"TONGUE",
        @"呆无辜": @"DULL",
        @"看": @"GLANCE",
        @"白眼": @"SLIGHT",
        @"熊吉": @"BEAR",
        @"骷髅": @"SKULL",
        @"黑脸": @"BLACKFACE"
    };
    NSArray *emojiKeys = [TMAEmotionResource allResource];
    NSMutableArray<TMASticker *> *stickers = [[NSMutableArray alloc] init];
    TMASticker *sticker = [[TMASticker alloc] init];
    sticker.coverImageName = kCoverImageName;
    NSMutableArray<TMAEmoji *> *emojis = [[NSMutableArray alloc] init];
    for (NSString *emojiKey in emojiKeys) {
        TMAEmoji *emoji = [[TMAEmoji alloc] init];
        emoji.imageName = emojiKey;
        emoji.emojiDescription = [TMAEmotionResource i18NBy:emojiKey];
        [emojis addObject:emoji];
    }
    sticker.emojis = emojis;
    [stickers addObject:sticker];
    self.allStickers = stickers;
}

#pragma mark - public method

- (void)replaceEmojiForAttributedString:(NSMutableAttributedString *)attributedString font:(UIFont *)font {
    if (!attributedString || !attributedString.length || !font) {
        return;
    }

    NSArray<TMAStickerMatchingResult *> *matchingResults = [self matchingEmojiForString:attributedString.string];

    if (matchingResults && matchingResults.count) {
        NSUInteger offset = 0;
        for (TMAStickerMatchingResult *result in matchingResults) {
            if (result.emojiImage) {
                CGFloat emojiHeight = font.lineHeight;
                NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                attachment.image = result.emojiImage;
                attachment.bounds = CGRectMake(0, font.descender, emojiHeight, emojiHeight);
                NSMutableAttributedString *emojiAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
                [emojiAttributedString tma_setTextBackedString:[TMATextBackedString stringWithString:result.showingDescription] range:NSMakeRange(0, emojiAttributedString.length)];
                if (!emojiAttributedString) {
                    continue;
                }
                NSRange actualRange = NSMakeRange(result.range.location - offset, result.showingDescription.length);
                [attributedString replaceCharactersInRange:actualRange withAttributedString:emojiAttributedString];
                offset += result.showingDescription.length - emojiAttributedString.length;
            }
        }
    }
}

#pragma mark - private method

- (NSArray<TMAStickerMatchingResult *> *)matchingEmojiForString:(NSString *)string {
    if (!string.length) {
        return nil;
    }
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[.+?\\]" options:0 error:NULL];
    NSArray<NSTextCheckingResult *> *results = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    if (results && results.count) {
        NSMutableArray *emojiMatchingResults = [[NSMutableArray alloc] init];
        for (NSTextCheckingResult *result in results) {
            NSString *showingDescription = [string substringWithRange:result.range];
            NSString *emojiSubString = [showingDescription substringFromIndex:1];       // 去掉[
            emojiSubString = [emojiSubString substringWithRange:NSMakeRange(0, emojiSubString.length - 1)];    // 去掉]
            TMAEmoji *emoji = [self emojiWithEmojiDescription:emojiSubString];
            if (emoji) {
                TMAStickerMatchingResult *emojiMatchingResult = [[TMAStickerMatchingResult alloc] init];
                emojiMatchingResult.range = result.range;
                emojiMatchingResult.showingDescription = showingDescription;
                emojiMatchingResult.emojiImage = [TMAEmotionResource imageBy:emoji.imageName];//[UIImage ema_imageNamed:[@"Sticker.bundle" stringByAppendingPathComponent:emoji.imageName]];
                [emojiMatchingResults addObject:emojiMatchingResult];
            }
        }
        return emojiMatchingResults;
    }
    return nil;
}

- (TMAEmoji *)emojiWithEmojiDescription:(NSString *)emojiDescription {
    if (BDPIsEmptyString(emojiDescription)) {
        return nil;
    }
    for (TMASticker *sticker in self.allStickers) {
        for (TMAEmoji *emoji in sticker.emojis) {
            if ([emoji.emojiDescription isEqualToString:emojiDescription]) {
                return emoji;
            }
            NSString *emojiName = [self.opEmojiMap bdp_stringValueForKey:emojiDescription];
            if ([emojiName isEqualToString:emoji.imageName]) {
                return emoji;
            }
        }
    }
    // 面板上不会出现，但是能通过键盘输入
    TMAEmoji *extralEmoji = [[TMAEmoji alloc] init];
    extralEmoji.imageName = emojiDescription;
    extralEmoji.emojiDescription = emojiDescription;
    return extralEmoji;
}

@end

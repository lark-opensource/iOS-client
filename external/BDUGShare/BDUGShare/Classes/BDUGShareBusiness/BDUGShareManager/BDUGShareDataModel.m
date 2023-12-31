//
//  BDUGShareDataModel.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/4/8.
//

#import "BDUGShareDataModel.h"
#import <ByteDanceKit/ByteDanceKit.h>


//已跟服务端对齐：https://wiki.bytedance.net/pages/viewpage.action?pageId=323728585
NSString* const kBDUGShareMethodServerStringDefault = @"sdk";
NSString* const kBDUGShareMethodServerStringSystem = @"sys";
NSString* const kBDUGShareMethodServerStringToken = @"token";
NSString* const kBDUGShareMethodServerStringImage = @"image";
NSString* const kBDUGShareMethodServerStringVideo = @"video";

NSString* const kBDUGSharePlatformServerStringQQ = @"qq";
NSString* const kBDUGSharePlatformServerStringQQZone = @"qzone";
NSString* const kBDUGSharePlatformServerStringWechat = @"wechat";
NSString* const kBDUGSharePlatformServerStringTimeline = @"moments";
NSString* const kBDUGSharePlatformServerStringSystem = @"sys_share";
NSString* const kBDUGSharePlatformServerStringSMS = @"sms";
NSString* const kBDUGSharePlatformServerStringCopyLink = @"copy_link";
NSString* const kBDUGSharePlatformServerStringDingtalk = @"dingding";
NSString* const kBDUGSharePlatformServerStringAweme = @"douyin";
NSString* const kBDUGSharePlatformServerStringWeibo = @"weibo";
NSString* const kBDUGSharePlatformServerStringFacebook = @"facebook";
NSString* const kBDUGSharePlatformServerStringWhatsApp = @"whatsapp";
NSString* const kBDUGSharePlatformServerStringMessenger = @"messenger";
NSString* const kBDUGSharePlatformServerStringInstagram = @"instagram";
NSString* const kBDUGSharePlatformServerStringTiktok = @"tiktok";
NSString* const kBDUGSharePlatformServerStringTwitter = @"twitter";
NSString* const kBDUGSharePlatformServerStringLine = @"line";
NSString* const kBDUGSharePlatformServerStringSnapChat = @"snapchat";
NSString* const kBDUGSharePlatformServerStringKakaoTalk = @"kakao";
NSString* const kBDUGSharePlatformServerStringRocket = @"feiliao";
NSString* const kBDUGSharePlatformServerStringMaya = @"duoshan";
NSString* const kBDUGSharePlatformServerStringToutiao = @"toutiao";
NSString* const kBDUGSharePlatformServerStringImageShare = @"image_share";
NSString* const kBDUGSharePlatformServerStringFeishu = @"feishu";
NSString* const kBDUGSharePlatformServerStringLongImage = @"long_image";

@implementation BDUGShareDataItemTokenInfoModel

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        _title = dict[@"title"];
        _tip = dict[@"tips"];
        _token = dict[@"description"];
    }
    return self;
}

- (BOOL)tokenInfoValide {
    return _title.length > 0 && _tip.length > 0 && _token.length > 0;
}

@end

@implementation BDUGShareDataItemModel

- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _channel = [dict btd_stringValueForKey:@"channel"];
        _method = [dict btd_stringValueForKey:@"method"];
        NSDictionary *shareData = [dict btd_dictionaryValueForKey:@"share_data"];
        _title = [shareData btd_stringValueForKey:@"title"];
        _desc = [shareData btd_stringValueForKey:@"description"];
        _imageUrl = [shareData btd_stringValueForKey:@"hidden_url"];
        _thumbImageUrl = [shareData btd_stringValueForKey:@"thumb_image_url"];
        _shareUrl = [shareData btd_stringValueForKey:@"share_url"];
        _appId = [shareData btd_stringValueForKey:@"app_id"];
        _videoURL = [shareData btd_stringValueForKey:@"video_url"];
        _tokenInfo = [[BDUGShareDataItemTokenInfoModel alloc] initWithDict:[shareData btd_dictionaryValueForKey:@"token_info"]];
        
        _sharePlatformActivityType = [[self.class inServerControllItemTypeDict] btd_stringValueForKey:_channel];
        _shareMethod = [[self.class methodDict] btd_integerValueForKey:_method];
    }
    return self;
}

+ (NSDictionary *)inServerControllItemTypeDict {
    return @{
             kBDUGSharePlatformServerStringQQ : @"BDUGQQFriendContentItem",
             kBDUGSharePlatformServerStringQQZone : @"BDUGQQZoneContentItem",
             kBDUGSharePlatformServerStringWechat : @"BDUGWechatContentItem",
             kBDUGSharePlatformServerStringTimeline : @"BDUGWechatTimelineContentItem",
             kBDUGSharePlatformServerStringDingtalk : @"BDUGDingTalkContentItem",
             kBDUGSharePlatformServerStringSystem : @"BDUGSystemContentItem",
             kBDUGSharePlatformServerStringCopyLink : @"BDUGCopyContentItem",
             kBDUGSharePlatformServerStringAweme : @"BDUGAwemeContentItem",
             kBDUGSharePlatformServerStringWeibo : @"BDUGSinaWeiboContentItem",
             kBDUGSharePlatformServerStringFacebook : @"BDUGFacebookContentItem",
             kBDUGSharePlatformServerStringWhatsApp : @"BDUGWhatsAppContentItem",
             kBDUGSharePlatformServerStringMessenger : @"BDUGMessengerContentItem",
             kBDUGSharePlatformServerStringInstagram : @"BDUGInstagramContentItem",
             kBDUGSharePlatformServerStringTiktok : @"BDUGTiktokContentItem",
             kBDUGSharePlatformServerStringTwitter : @"BDUGTwitterContentItem",
             kBDUGSharePlatformServerStringLine : @"BDUGLineContentItem",
             kBDUGSharePlatformServerStringSnapChat : @"BDUGSnapChatContentItem",
             kBDUGSharePlatformServerStringKakaoTalk : @"BDUGKakaoTalkContentItem",
             kBDUGSharePlatformServerStringRocket : @"BDUGRocketContentItem",
             kBDUGSharePlatformServerStringMaya : @"BDUGMayaContentItem",
             kBDUGSharePlatformServerStringSMS : @"BDUGSMSContentItem",
             kBDUGSharePlatformServerStringToutiao : @"BDUGToutiaoContentItem",
             kBDUGSharePlatformServerStringImageShare : @"BDUGImageShareContentItem",
             kBDUGSharePlatformServerStringFeishu : @"BDUGLarkContentItem",
             kBDUGSharePlatformServerStringLongImage : @"BDUGAdditionalPanelContentItem",
             };
}

+ (NSDictionary *)channelTypeDict
{
    // reverse inServerControllItemTypeDict
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    [[self inServerControllItemTypeDict] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [result setObject:key forKey:obj];
    }];
    return result.copy;
}

+ (NSDictionary *)methodDict {
    return @{
             kBDUGShareMethodServerStringDefault : @(BDUGShareMethodDefault),
             kBDUGShareMethodServerStringSystem : @(BDUGShareMethodSystem),
             kBDUGShareMethodServerStringToken : @(BDUGShareMethodToken),
             kBDUGShareMethodServerStringImage : @(BDUGShareMethodImage),
             kBDUGShareMethodServerStringVideo : @(BDUGShareMethodVideo),
             };
}

@end

@implementation BDUGShareDataModel

- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        NSArray *infoList = [dict btd_arrayValueForKey:@"share_info_list"];
        if (infoList.count > 0) {
            NSMutableArray *tempArray = [[NSMutableArray alloc] init];
            [infoList enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                BDUGShareDataItemModel *itemModel = [[BDUGShareDataItemModel alloc] initWithDict:obj];
                [tempArray addObject:itemModel];
            }];
            self.infoList = tempArray.copy;
        }
    }
    return self;
}

@end

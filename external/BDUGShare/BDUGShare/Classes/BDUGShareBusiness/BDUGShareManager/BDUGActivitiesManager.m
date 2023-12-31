//
//  TTActivitiesManager.m
//  BDUGActivityViewControllerDemo
//
//  Created by 延晋 张 on 16/6/1.
//
//

#import "BDUGActivitiesManager.h"
#import "BDUGActivityProtocol.h"
#import "BDUGActivityContentItemProtocol.h"
#import "BDUGShareBaseContentItem.h"

@interface BDUGActivitiesManager ()

//只存储分享类型Activity 不存储分享内容activityContentItem
@property (nonatomic, strong) NSMutableArray *validActivitiesArray;

@end

@implementation BDUGActivitiesManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static BDUGActivitiesManager * sharedInstance;
    dispatch_once(&once, ^ { sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

- (id)init
{
    if (self = [super init]) {
        _validActivitiesArray = [NSMutableArray arrayWithArray:[self sharePodSupportActivities]];
    }
    return self;
}

- (void)addValidActivitiesFromArray:(NSArray *)activities
{
    for (id <BDUGActivityProtocol> activity in activities) {
        [self addValidActivity:activity];
    }
}

- (void)addValidActivity:(id <BDUGActivityProtocol>)activity
{
    BOOL hasThisClass = NO;
    //todo： 命名风格问题。
    for (id <BDUGActivityProtocol> activity_inArray in _validActivitiesArray) {
        if ([NSStringFromClass([activity class]) isEqualToString:NSStringFromClass([activity_inArray class])]) {
            hasThisClass = YES;
            break;
        }
    }
    //保证每种分享类型，只加一次
    if (!hasThisClass) {
        [_validActivitiesArray addObject:activity];
    }
}

- (NSMutableArray *)sharePodSupportActivities
{
    NSMutableArray *sharePodSupportActivities = [NSMutableArray array];
    for (NSString *activityNameString in [self allPodSupportActivitiesString]) {
        id activityObj = [[NSClassFromString(activityNameString) alloc] init];
        if (activityObj) {
            [sharePodSupportActivities addObject:activityObj];
        }
    }
    return sharePodSupportActivities;
}

- (NSArray *)allPodSupportActivitiesString
{
    //todo： 看下这里的必要性
    return @[@"BDUGSinaWeiboActivity",
             @"BDUGWechatActivity",
             @"BDUGAwemeActivity",
             @"BDUGWechatTimelineActivity",
             @"BDUGZhiFuBaoActivity",
             @"BDUGSMSActivity",
             @"BDUGQQFriendActivity",
             @"BDUGQQZoneActivity",
             @"BDUGEmailActivity",
             @"BDUGSystemActivity",
             @"BDUGCopyActivity",
             @"BDUGDingTalkActivity",
             @"BDUGFacebookActivity",
             @"BDUGWhatsAppActivity",
             @"BDUGMessengerActivity",
             @"BDUGInstagramActivity",
             @"BDUGTiktokActivity",
             @"BDUGTwitterActivity",
             @"BDUGLineActivity",
             @"BDUGSnapChatActivity",
             @"BDUGKakaoTalkActivity",
             @"BDUGRocketActivity",
             @"BDUGMayaActivity",
             @"BDUGToutiaoActivity",
             @"BDUGImageShareActivity",
             @"BDUGLarkActivity",
             @"BDUGAdditionalPanelActivity",
             ];
}

- (NSArray *)validActivitiesForContent:(NSArray *)contentArray hiddenContentArray:(NSArray *)hiddenContentArray panelId:(NSString *)panelId
{
    NSMutableArray *activities = [NSMutableArray array];
    for (id object in contentArray) {
        if ([object isKindOfClass:[NSArray class]]) {
            [activities addObject:[self validActivitiesForContent:object hiddenContentArray:hiddenContentArray panelId:panelId]];
        } else if ([object conformsToProtocol:@protocol(BDUGActivityContentItemProtocol)]) {
            id <BDUGActivityContentItemProtocol> item = object;
            id <BDUGActivityProtocol> activity = [self getActivityByItem:item panelId:panelId];
            //没安装且在服务器的【不安装不展示】数组中，即标记为不展示。
            BOOL activityShouldNotShow = [hiddenContentArray containsObject:NSStringFromClass(item.class)] && [activity respondsToSelector:@selector(appInstalled)] && ![activity appInstalled];
            if (activity && !activityShouldNotShow) {
                [activities addObject:activity];
            }
        } else {
            NSAssert(0, @"该ContentItem没有实现BDUGActivityContentItemProtocol协议");
        }
    }
    return [activities copy];
}

- (id <BDUGActivityProtocol>)getActivityByItem:(id <BDUGActivityContentItemProtocol>)item panelId:(NSString *)panelId
{
    NSDictionary *channelDict = [BDUGShareDataItemModel channelTypeDict];
    for (id <BDUGActivityProtocol> activity in _validActivitiesArray) {
        if ([[activity contentItemType] isEqualToString:item.contentItemType]) {
            id <BDUGActivityProtocol> newActivity = [[activity.class alloc] init];
            if ([item isKindOfClass:[BDUGShareBaseContentItem class]]) {
                ((BDUGShareBaseContentItem *)item).channelString = [channelDict objectForKey:NSStringFromClass(item.class)];
            }
            newActivity.contentItem = item;
            if ([newActivity respondsToSelector:@selector(setPanelId:)]) {
                [newActivity setPanelId:panelId];
            }
            return newActivity;
        }
    }
    return nil;
}

@end

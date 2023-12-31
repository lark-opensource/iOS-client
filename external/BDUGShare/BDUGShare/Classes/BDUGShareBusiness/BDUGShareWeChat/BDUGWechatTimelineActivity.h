//
//  BDUGWechatTimelineActivity.h
//  BDUGActivityViewControllerDemo
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import "BDUGActivityProtocol.h"
#import "BDUGWechatTimelineContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToWechatTimeline;

@interface BDUGWechatTimelineActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGWechatTimelineContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END

//
//  BDUGWechatActivity.h
//  BDUGActivityViewControllerDemo
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import "BDUGActivityProtocol.h"
#import "BDUGWechatContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToWechat;

@interface BDUGWechatActivity : NSObject<BDUGActivityProtocol>

@property (nonatomic, strong) BDUGWechatContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END

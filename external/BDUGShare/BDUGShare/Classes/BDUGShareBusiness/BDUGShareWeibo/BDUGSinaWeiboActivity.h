//
//  BDUGSinaWeiboActivity.h
//  BDUGActivityViewControllerDemo
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import "BDUGActivityProtocol.h"
#import "BDUGSinaWeiboContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToWeibo;

@interface BDUGSinaWeiboActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGSinaWeiboContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END

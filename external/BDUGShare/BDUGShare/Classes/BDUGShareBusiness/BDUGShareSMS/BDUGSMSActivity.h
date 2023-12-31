//
//  BDUGSMSActivity.h
//  NeteaseLottery
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import "BDUGActivityProtocol.h"
#import "BDUGSMSContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToSMS;

@interface BDUGSMSActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGSMSContentItem *contentItem;
@property (nonatomic, weak, nullable) UIViewController *presentingViewController;

@end

NS_ASSUME_NONNULL_END

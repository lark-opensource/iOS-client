//
//  BDUGEmailActivity.h
//  NeteaseLottery
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import "BDUGActivityProtocol.h"
#import "BDUGEmailContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToEmail;

@interface BDUGEmailActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic,strong) BDUGEmailContentItem *contentItem;
@property (nonatomic, weak, nullable) UIViewController *presentingViewController;

@end

NS_ASSUME_NONNULL_END

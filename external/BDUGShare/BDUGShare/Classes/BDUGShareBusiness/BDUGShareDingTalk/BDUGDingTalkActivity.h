//
//  BDUGDingTalkActivity.h
//  Pods
//
//  Created by 张 延晋 on 17/01/09.
//
//

#import "BDUGActivityProtocol.h"
#import "BDUGDingTalkContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToDingTalk;

@interface BDUGDingTalkActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGDingTalkContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END

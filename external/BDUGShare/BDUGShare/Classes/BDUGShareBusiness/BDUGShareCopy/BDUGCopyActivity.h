//
//  BDUGCopyActivity.h
//  NeteaseLottery
//
//  Created by 延晋 张 on 16/6/7.
//
//

#import "BDUGActivityProtocol.h"
#import "BDUGCopyContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToCopy;

@interface BDUGCopyActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic,strong) BDUGCopyContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END

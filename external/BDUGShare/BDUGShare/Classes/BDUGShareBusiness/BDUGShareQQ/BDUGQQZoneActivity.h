//
//  BDUGQQZoneActivity.h
//  Pods
//
//  Created by 张 延晋 on 16/06/03.
//
//

#import "BDUGActivityProtocol.h"
#import "BDUGQQZoneContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToQQZone;

@interface BDUGQQZoneActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGQQZoneContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END

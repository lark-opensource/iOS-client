//
//  TTShareMYActivity.h
//  TTShareService
//
//  Created by chenjianneng on 2019/3/15.
//

#import "BDUGActivityProtocol.h"
#import "BDUGToutiaoContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypeShareToutiao;

@interface BDUGToutiaoActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGToutiaoContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END

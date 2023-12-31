//
//  BDUGWhatsAppActivity.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/29.
//

#import "BDUGActivityProtocol.h"
#import "BDUGWhatsAppContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToWhatsApp;

@interface BDUGWhatsAppActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGWhatsAppContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END

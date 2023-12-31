//
//  BDUGAwemeActivity.h
//  Pods
//
//  Created by 王霖 on 6/12/16.
//
//

#import <Foundation/Foundation.h>
#import "BDUGActivityProtocol.h"
#import "BDUGAwemeContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToAweme;

@interface BDUGAwemeActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGAwemeContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END

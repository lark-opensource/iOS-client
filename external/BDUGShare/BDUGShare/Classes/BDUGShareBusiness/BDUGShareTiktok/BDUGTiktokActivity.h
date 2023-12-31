//
//  BDUGTiktokActivity.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/11.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDUGActivityProtocol.h"
#import "BDUGTiktokContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToTiktok;

@interface BDUGTiktokActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGTiktokContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END

//
//  BDUGRocketActivity.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/21.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import "BDUGActivityProtocol.h"
#import "BDUGRocketContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToRocket;

@interface BDUGRocketActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGRocketContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END

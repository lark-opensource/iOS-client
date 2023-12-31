//
//  BDUGInstagramActivity.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/5/30.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import "BDUGActivityProtocol.h"
#import "BDUGInstagramContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToInstagram;

@interface BDUGInstagramActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGInstagramContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END

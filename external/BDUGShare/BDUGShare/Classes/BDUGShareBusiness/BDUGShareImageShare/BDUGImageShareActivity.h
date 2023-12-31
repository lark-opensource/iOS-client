//
//  BDUGImageShareActivity.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2020/3/9.
//  Copyright © 2020 xunianqiang. All rights reserved.
//

#import "BDUGActivityProtocol.h"
#import "BDUGImageShareContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypeHiddenMarkImage;

@interface BDUGImageShareActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGImageShareContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END

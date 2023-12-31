//
//  BDUGInstagramContentItem.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/5/30.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDUGActivityContentItemProtocol.h"
#import "BDUGShareBaseContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityContentItemTypeInstagram;

@interface BDUGInstagramContentItem : BDUGShareBaseContentItem

@property (nonatomic, assign) BOOL shareToStories NS_AVAILABLE_IOS(10_0);

@end

NS_ASSUME_NONNULL_END

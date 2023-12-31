//
//  BDUGLineActivity.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/16.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import "BDUGActivityProtocol.h"
#import "BDUGLineContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToLine;

@interface BDUGLineActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGLineContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END

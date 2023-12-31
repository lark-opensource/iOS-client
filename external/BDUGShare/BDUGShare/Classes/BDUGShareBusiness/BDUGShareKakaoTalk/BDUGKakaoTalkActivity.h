//
//  BDUGKakaoTalkActivity.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/17.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDUGActivityProtocol.h"
#import "BDUGKakaoTalkContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToKakaoTalk;

@interface BDUGKakaoTalkActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGKakaoTalkContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END

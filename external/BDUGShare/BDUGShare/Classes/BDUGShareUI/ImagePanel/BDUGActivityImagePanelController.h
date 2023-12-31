//
//  BDUGActivityImagePanelController.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2020/5/6.
//  Copyright © 2020 xunianqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDUGActivityPanelControllerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString* const kImagePanelWillTransitionToSize;

@interface BDUGActivityImagePanelController : NSObject <BDUGActivityPanelControllerProtocol>

@property (nonatomic, weak, nullable) id <BDUGActivityPanelDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

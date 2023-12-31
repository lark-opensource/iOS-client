//
//  AWEEditAndPublishViewActionContainerModel.h
//  AWEStudio
//
//  Created by hanxu on 2018/11/16.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWEEditAndPublishViewData.h"

@interface AWEEditAndPublishViewActionContainerModel : NSObject

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UILabel *bottomLabel;
@property (nonatomic, weak) UIView *actionItemView;
// New addition on May 10, 2019
@property (nonatomic, strong) AWEEditAndPublishViewData *data; ///< view bound data
@end

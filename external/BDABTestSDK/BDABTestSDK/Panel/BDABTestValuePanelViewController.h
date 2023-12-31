//
//  BDABTestValuePanelViewController.h
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/24.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BDABTestExperimentItemModel.h"

@protocol BDABTestValuePanelDelegate <NSObject>

//搜索

//翻页

//改写
- (void)refreshExperimentWithModel:(BDABTestExperimentItemModel *)model forKey:(NSString *)key;

@end

@interface BDABTestValuePanelViewController : UIViewController

@property (nonatomic, weak) id<BDABTestValuePanelDelegate> delegate;

- (instancetype)initWithSourceData:(NSArray *)data;

@end

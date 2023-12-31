//
//  AWECameraContainerToolButtonWrapView.h
//  AWEStudio
//
//Created by Hao Yipeng on June 14, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCBarItemCustomView.h>
#import <CreativeKit/ACCBarItem.h>

@interface AWECameraContainerToolButtonWrapView : UIView <ACCBarItemCustomView>

@property (nonatomic, assign) void *itemID;
- (instancetype)initWithButton:(UIButton *)button label:(UILabel *)label itemID:(void *)itemID;

- (instancetype)initWithButton:(UIButton *)button label:(UILabel *)label;
@end

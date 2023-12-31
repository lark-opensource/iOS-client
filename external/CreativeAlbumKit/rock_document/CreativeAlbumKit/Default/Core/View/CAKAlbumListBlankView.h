//
//  CAKAlbumListBlankView.h
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/3.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CAKAlbumListBlankViewType) {
    CAKAlbumListBlankViewTypeNoPermissions,
    CAKAlbumListBlankViewTypeNoVideo,
    CAKAlbumListBlankViewTypeNoPhoto,
    CAKAlbumListBlankViewTypeNoVideoAndPhoto,
};

@interface CAKAlbumListBlankView : UIView

@property (nonatomic, assign) CAKAlbumListBlankViewType type;
@property (nonatomic, strong, readonly ,nullable) UIButton *toSetupButton;
@property (nonatomic, strong, nullable) UIView *containerView;

@end

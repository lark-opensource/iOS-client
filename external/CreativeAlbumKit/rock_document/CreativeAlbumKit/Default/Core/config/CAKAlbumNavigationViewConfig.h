//
//  CAKAlbumNavigationViewConfig.h
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/1.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CAKAlbumNavigationViewConfig : NSObject

//是否开启选择相册功能
@property (nonatomic, assign) BOOL enableChooseAlbum;
@property (nonatomic, assign) BOOL hiddenCancelButton;
@property (nonatomic, assign) BOOL enableBlackStyle;

@property (nonatomic, copy, nullable) NSString *titleText;

@end

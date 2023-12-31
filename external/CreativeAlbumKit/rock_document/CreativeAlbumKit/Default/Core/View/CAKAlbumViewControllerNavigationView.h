//
//  CAKAlbumViewControllerNavigationView.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/6.
//

#import <UIKit/UIKit.h>
#import "CAKAlbumSelectAlbumButton.h"
#import "CAKAlbumNavigationViewProtocol.h"

@interface CAKAlbumViewControllerNavigationView : UIView <CAKAlbumNavigationViewProtocol>

@property (nonatomic, strong, nullable) UILabel *titleLabel;
@property (nonatomic, strong, nullable) CAKAlbumSelectAlbumButton *selectAlbumButton; //选择相册，点击显示下拉菜单展示所有相册

@end

//
//  CAKAlbumGoSettingStrip.h
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2020/9/12.
//

#import <UIKit/UIKit.h>

@interface CAKAlbumGoSettingStrip : UIView

+ (BOOL)closedByUser;
+ (void)setClosedByUser;

@property (nonatomic, strong, nullable) UILabel *label;
@property (nonatomic, strong, nullable) UIButton *closeButton;

@end


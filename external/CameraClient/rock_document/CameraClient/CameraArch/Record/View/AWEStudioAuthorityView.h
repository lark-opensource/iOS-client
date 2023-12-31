//
//  AWEStudioAuthorityView.h
//  Aweme
//
//  Created by hanxu on 2017/5/19.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AWEStudioAuthorityView : UIView

+ (instancetype)getInstanceForRecordControllerWithFrame:(CGRect)frame withUserGrantedBlock:(void(^)(void))UserGrantedBlock;

@property (nonatomic, strong) void (^didClickedCameraAuthorityBtn)(AWEStudioAuthorityView *authorityView);
@property (nonatomic, strong) void (^didClickedMikeAuthorityBtn)(AWEStudioAuthorityView *authorityView);

@property (nonatomic, strong) UILabel *upLabel;
@property (nonatomic, strong) UILabel *downLabel;
@property (nonatomic, strong) UIButton *cameraAuthorityBtn;
@property (nonatomic, strong) UIButton *mikeAuthorityBtn;

- (void)setCameraAuthoritySelected:(BOOL)selected;
- (void)setMikeAuthoritySelected:(BOOL)selected;

/**
 当用户相机权限被系统限制时更新按钮的宽度，因为文案变长了，会导致小尺寸屏幕换行
 */
- (void)updateCameraWidthConstraintsWhenRestricted;
/**
 当用户麦克风权限被系统限制时更新按钮的宽度，因为文案变长了，会导致小尺寸屏幕换行
 */
- (void)updateMikeWidthConstraintsWhenRestricted;
@end

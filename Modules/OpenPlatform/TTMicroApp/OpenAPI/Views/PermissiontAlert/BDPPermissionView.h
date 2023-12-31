//
//  BDPPermissionView.h
//  Timor
//
//  Created by liuxiangxin on 2019/6/13.
//

#import <UIKit/UIKit.h>
#import <OPFoundation/BDPUniqueID.h>

@class BDPPermissionView;

NS_ASSUME_NONNULL_BEGIN

@protocol BDPPermissionViewDelegate <NSObject>

- (void)permissionViewDidConfirm:(BDPPermissionView *)permissionView;
- (void)permissionViewDidCancel:(BDPPermissionView *)permissionView;

@end

@interface BDPPermissionView : UIView

@property (nonatomic, copy, readonly) NSString *appActionDescription;
@property (nonatomic, copy, readonly) NSString *permisstionTitle;
@property (nonatomic, copy, readonly) NSString *appName;
@property (nonatomic, strong, readonly) BDPUniqueID *uniqueID;
@property (nonatomic, strong, readonly) UIView *contentView;
@property (nonatomic, strong, readonly) UIButton *cancelButton;
@property (nonatomic, strong, readonly) UIButton *confirmButton;
@property (nonatomic, strong, readonly) UILabel *privacyPolicyLabel;
@property (nonatomic, weak, nullable) id<BDPPermissionViewDelegate> delegate;
@property (nonatomic, assign) BOOL enableNewStyle;

- (instancetype)initWithActionDescption:(NSString *)actionDescription
                        permissionTitle:(NSString *)permissionTitle
                                   logo:(NSString *)logo
                            contentView:(UIView *)contentView
                                appName:(NSString *)appName
                               newStyle:(BOOL)enableNewStyle
                               uniqueID:(nullable BDPUniqueID *)uniqueID;
@end

NS_ASSUME_NONNULL_END

//
//  ACCToolBarCommonProtocol.h
//  CameraClient
//
//  Created by bytedance on 2021/6/1.
//

#ifndef ACCToolBarCommonProtocol_h
#define ACCToolBarCommonProtocol_h

#import <CreativeKit/ACCBarItemContainerView.h>

@protocol ACCToolBarCommonProtocol <ACCBarItemContainerView>
// Block
@property (nonatomic, copy) void (^clickItemBlock)(UIView *clickItemView);
@property (nonatomic, copy) void (^clickMoreBlock)(BOOL folded);
// get view
- (id<ACCBarItemCustomView>)viewWithBarItemID:(nonnull void *)itemId;
- (nullable UIView *)getMoreItemView;
// add view
- (void)addMaskViewAboveToolBar:(UIView *)maskView;
// action
- (void)resetUpBarContentView;
- (void)resetFoldState;

@end

#endif /* ACCToolBarCommonProtocol_h */

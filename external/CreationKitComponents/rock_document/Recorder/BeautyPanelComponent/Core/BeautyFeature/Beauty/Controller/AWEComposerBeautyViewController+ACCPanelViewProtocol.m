//
//  AWEComposerBeautyViewController+ACCPanelViewProtocol.m
//  CameraClient
//
//  Created by haoyipeng on 2020/7/20.
//

#import "AWEComposerBeautyViewController+ACCPanelViewProtocol.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>

@implementation AWEComposerBeautyViewController (ACCPanelViewProtocol)

- (void *)identifier
{
    return ACCRecordBeautyPanelContext;
}

- (CGFloat)panelViewHeight
{
    return self.view.acc_height;
}

- (void)panelWillShow
{
    [self reloadPanel];
}

@end

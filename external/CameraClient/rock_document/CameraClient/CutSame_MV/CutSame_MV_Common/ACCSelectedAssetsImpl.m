//
//  ACCSelectedAssetsImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/9.
//

#import "ACCSelectedAssetsImpl.h"
#import "ACCImportMaterialSelectView.h"
#import "ACCImportMaterialSelectBottomView.h"

@implementation ACCSelectedAssetsImpl

- (UIView<ACCSelectedAssetsViewProtocol> *)selectedAssetsViewWithChangeCellColor:(BOOL) shouldCellChangeColor;
{
    return [[ACCImportMaterialSelectView alloc] initWithFrame:CGRectZero withChangeCellColor:shouldCellChangeColor];
}

- (UIView<ACCSelectedAssetsBottomViewProtocol> *)selectedAssetsBottomView
{
    return [[ACCImportMaterialSelectBottomView alloc] init];
}

@end

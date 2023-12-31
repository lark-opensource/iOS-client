//
//  DVEBaseBar.h
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "DVEBaseView.h"
#import "DVEStepSlider.h"
#import <DVEFoundationKit/DVECommonDefine.h>
#import <DVEFoundationKit/DVEMacros.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEBaseBar : DVEBaseView

@property (nonatomic, strong) DVEStepSlider *slider;
@property (nonatomic, assign) NSInteger panelType;

- (void)refreshBar;

@end

NS_ASSUME_NONNULL_END

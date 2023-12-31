//
//  AWEStickerPickerOverlayView.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/26.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEStickerPickerOverlayView.h"
#import <Masonry/View+MASAdditions.h>

@implementation AWEStickerPickerOverlayView

- (void)showOnView:(UIView *)view {
    [view addSubview:self];
    ACCMasMaker(self, {
        make.edges.equalTo(@(0));
    });
}

- (void)dismiss {
    [self removeFromSuperview];
}

@end

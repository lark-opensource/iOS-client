//
//  ACCFlowerPropPanelView+Tray.h
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/11/14.
//

#import "ACCFlowerPropPanelView.h"
#import <CameraClient/AWEStickerViewLayoutManagerProtocol.h>
#import "AWECollectionStickerPickerController.h"


@interface ACCFlowerPropPanelView (Tray) <AWEStickerViewLayoutManagerProtocol, AWECollectionStickerPickerControllerDelegate>

- (void)showFlowerShootCollectionPanel;
- (void)hideFlowerShootCollectionPanel;

@end


//
//  ACCFlowerScrollPropPanelView.h
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/11/12.
//

#import <UIKit/UIKit.h>
#import "ACCFlowerScrollPropPanelView.h"
#import "ACCExposePanGestureRecognizer.h"
#import "ACCFlowerPropPanelViewModel.h"

@protocol ACCRecognitionService;

@interface ACCFlowerScrollPropPanelView : UIView

@property (nonatomic, strong, nullable) ACCFlowerPropPanelViewModel *panelViewMdoel;
@property (nonatomic, weak, nullable) id<ACCRecognitionService> recognitionService;
@property (nonatomic, strong, nullable) ACCExposePanGestureRecognizer *exposePanGestureRecognizer;
@property (nonatomic, readonly) NSInteger selectedIndex;

@property (nonatomic, copy, nullable) void (^didTakePictureBlock)(void);

- (void)updateSelectedIndex:(NSInteger)index animated:(BOOL)animated;
- (void)reloadScrollPanel;

@end


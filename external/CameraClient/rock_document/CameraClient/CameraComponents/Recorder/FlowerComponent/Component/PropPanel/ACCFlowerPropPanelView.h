//
//  ACCFlowerPropPanelView.h
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/11/12.
//

#import <UIKit/UIKit.h>
#import "ACCFlowerScrollPropPanelView.h"
#import "ACCExposePanGestureRecognizer.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import "ACCFlowerPropPanelViewModel.h"


@interface ACCFlowerPropPanelView : UIView

@property (nonatomic, strong, readonly, nullable) ACCExposePanGestureRecognizer *exposePanGestureRecognizer;
@property (nonatomic, strong, readonly, nullable) ACCFlowerScrollPropPanelView *panelView;
@property (nonatomic, strong, readonly, nullable) UIView *backgroundView;
@property (nonatomic, strong, readonly, nullable) ACCAnimatedButton *closeButton;
@property (nonatomic, strong, nullable) ACCFlowerPropPanelViewModel *panelViewModel;

@property (nonatomic, strong, nullable) ACCFlowerPropPanelViewModel *panelViewMdoel;

@property (nonatomic, assign) CGFloat trayViewOffset;

@property (nonatomic, assign) CGFloat recordButtonTop;
@property (nonatomic, assign) CGFloat taskEntryViewBottom;

@property (nonatomic, assign) BOOL isPhotoPropDowning;
@property (nonatomic, assign) BOOL isDefaultPropLoading;
@property (nonatomic, assign) CFTimeInterval photoPropStartTime;

- (void)updateEntryText:(NSString *)entryText;
- (void)reloadScrollPanel;

@property (nonatomic, copy, nullable) void (^closeButtonClickCallback)(void);
@property (nonatomic, copy, nullable) void (^entryButtonClickCallback)(void);

@property (nonatomic, copy, nullable) void (^didSelectStickerBlock)(IESEffectModel * _Nullable sticker);
@property (nonatomic, copy, nullable) void (^didTakePictureBlock)(void);
@property (nonatomic, copy, nullable) void (^onTrayViewChanged)(UIView * _Nullable trayView);

@end


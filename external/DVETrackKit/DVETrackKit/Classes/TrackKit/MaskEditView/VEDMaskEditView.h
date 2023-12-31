//
//  VEDMaskEditView.h
//  NLEEditor
//
//  Created by bytedance on 2021/4/11.
//

#import <UIKit/UIKit.h>
#import "VEDMaskEditViewProtocol.h"
#import "VEDMaskEditViewConfig.h"
#import "VEDMaskDrawView.h"
#import "VEDMaskPanGestureHandler.h"
#import "VEDMaskPinchGestureHandler.h"
#import "VEDMaskRotateGesture.h"


NS_ASSUME_NONNULL_BEGIN

@interface VEDMaskEditView : UIView <VEDMaskDrawViewDelegate,UIGestureRecognizerDelegate>

@property (nonatomic, strong) VEDMaskEditViewConfig *config;

@property (nonatomic, weak) id<VEDMaskEditViewProtocol> delegate;

@property (nonatomic, strong) VEDMaskDrawView *drawView;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGesture;

@property (nonatomic, strong) UIRotationGestureRecognizer *rotateGesture;


@property (nonatomic, strong) VEDMaskPanGestureHandler *panHandler;

@property (nonatomic, strong) VEDMaskPinchGestureHandler *pinchHandler;

@property (nonatomic, strong) VEDMaskRotateGesture *rotateHandler;


- (void)configDrawViewWithConfig:(VEDMaskEditViewConfig *)config;

- (void)setBorderView:(UIView *)borderView;

- (void)updateLabel;

@end

NS_ASSUME_NONNULL_END

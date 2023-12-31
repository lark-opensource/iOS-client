//
//  VEDMaskDrawView.h
//  NLEEditor
//
//  Created by bytedance on 2021/4/11.
//

#import <UIKit/UIKit.h>
#import "VEDMaskAbleProtocol.h"
#import "VEDMaskEditViewConfig.h"
#import "VEDMaskTransform.h"


NS_ASSUME_NONNULL_BEGIN
@class VEDMaskDrawView;
@protocol VEDMaskDrawViewDelegate <NSObject>

- (CGPoint)fixBorderPanMoveInMaskDrawView:(VEDMaskDrawView *)maskDrawView toPoint:(CGPoint)point;

- (void)didBeganMaskDrawEditInMaskDrawView:(VEDMaskDrawView *) maskDrawView;

- (void)didMaskDrawEditingInMaskDrawView:(VEDMaskDrawView *) maskDrawView;

- (void)didEndedMaskDrawEditInMaskDrawView:(VEDMaskDrawView *) maskDrawView;

- (void)maskDrawViewWillBeginRotateWithMaskDrawView:(VEDMaskDrawView *) maskDrawView;

- (void)maskDrawViewDidChangeRotateWithMaskDrawView:(VEDMaskDrawView *) maskDrawView;

- (void)maskDrawViewDidEndRotateRotateWithMaskDrawView:(VEDMaskDrawView *) maskDrawView;


@end


typedef NS_ENUM(NSInteger, VEDPanActionType) {
    VEDPanActionTypeNone = 0,
    VEDPanActionTypeMove,
    VEDPanActionTypeHorizontal,
    VEDPanActionTypeVertical,
    VEDPanActionTypeFeather,
    VEDPanActionTypeRoundCorner
   
};

@interface VEDMaskDrawView : UIView <VEDMaskActionableProtocol,VEDMaskGestureableProtocol>



@property (nonatomic, weak) id<VEDMaskDrawViewDelegate> delegate;
    
@property (nonatomic, strong) VEDMaskEditViewConfig *config;

@property (nonatomic, strong) VEDMaskTransform *maskTranform;

@property (nonatomic, strong) CAShapeLayer *borderLayer;

@property (nonatomic, strong) CAShapeLayer *centerLayer;
    
@property (nonatomic, strong) UIImageView *horizontalPanIcon;

@property (nonatomic, strong) UIImageView *verticalPanIcon;

@property (nonatomic, strong) UIImageView *featherPanIcon;

@property (nonatomic, strong) UIImageView *roundCornerPanIcon;
    
@property (nonatomic, assign) VEDPanActionType panAction;

- (instancetype)initWithFrame:(CGRect)frame config:(VEDMaskEditViewConfig *)config;
    
- (void)setupBorder;

- (void)drawBorder;

// MARK:- Pan Gesture
- (void)didPanWithGesture:(UIPanGestureRecognizer *)pan;

// MARK:- Pinch Gesture
- (void)didPinchWithWidth:(CGFloat)width height:(CGFloat)height pinch:(UIPinchGestureRecognizer *)pinch;

// MARK:- Rotate Gesture
- (void)didRotateWithRotate:(CGFloat)rotation rotate:(UIRotationGestureRecognizer *)rotate;

// MARK: - Transform
- (void)applyTransform;

- (BOOL)canBorderPanRespondInPoint:(CGPoint)touchPoint;

- (BOOL)canRoundCornerPanRespondInPoint:(CGPoint)touchPoint;

- (BOOL)canHorizontalPanRespondInPoint:(CGPoint)touchPoint;

- (BOOL)canVerticalPanRespondInPoint:(CGPoint)touchPoint;

- (BOOL)canFeatherPanRespondInPoint:(CGPoint)touchPoint;

- (void)updateIconsPositons;
   

@end

NS_ASSUME_NONNULL_END

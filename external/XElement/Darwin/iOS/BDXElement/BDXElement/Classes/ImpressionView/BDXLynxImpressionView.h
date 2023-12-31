//
//  BDXLynxImpressionView.h
//  BDXElement
//
//  Created by li keliang on 2020/3/9.
//

#import <Lynx/LynxUI.h>

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSNotificationName const BDXLynxImpressionWillManualExposureNotification;
UIKIT_EXTERN NSNotificationName const BDXLynxImpressionLynxViewIDNotificationKey;
UIKIT_EXTERN NSNotificationName const BDXLynxImpressionStatusNotificationKey;
UIKIT_EXTERN NSNotificationName const BDXLynxImpressionForceImpressionBoolKey;

@protocol BDXLynxImpressionParentView <NSObject>

@optional
- (BOOL)bdx_shouldManualExposure;

@end

@interface BDXLynxInnerImpressionView : UIView

@property (nonatomic, assign, readonly) BOOL onScreen;

@property (nonatomic, assign) float impressionPercent;

- (void)impression;
- (void)exit;

@end

@interface BDXLynxImpressionView : LynxUI<BDXLynxInnerImpressionView*>

@end

NS_ASSUME_NONNULL_END

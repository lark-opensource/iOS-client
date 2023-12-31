//
//  VEDMaskAbleProtocol.h
//  NLEEditor
//
//  Created by bytedance on 2021/4/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VEDMaskActionableProtocol <NSObject>

@property (nonatomic, assign) BOOL horizontalPanable;
@property (nonatomic, assign) BOOL verticalPanable;
@property (nonatomic, assign) BOOL roundCornerPanable;

@end

@protocol VEDMaskGestureableProtocol <NSObject>

@property (nonatomic, assign) BOOL panGestureable;
@property (nonatomic, assign) BOOL pinchGestureable;
@property (nonatomic, assign) BOOL rotateGestureable;

@end

NS_ASSUME_NONNULL_END

//
//  TTPlayerViewProtocol.h
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "TTAVPlayerProtocol.h"

#ifndef TTM_DUAL_CORE_TTPLAYER_VIEW_PROTOCOL
#define TTM_DUAL_CORE_TTPLAYER_VIEW_PROTOCOL

typedef NS_ENUM(NSInteger, TTPlayerViewScaleType) {
    TTPlayerViewScaleTypeAspectFit = 0,
    TTPlayerViewScaleTypeAspectFill = 1,
    TTPlayerViewScaleTypeToFill = 2,
};

typedef NS_ENUM(NSInteger, TTPlayerViewRenderType) {
    TTPlayerViewRenderTypeInvalid = -1,
    TTPlayerViewRenderTypeOpenGLES = 0,
    TTPlayerViewRenderTypeMetal = 1,
    TTPlayerViewRenderTypeSampleBufferDisplayLayer = 2,
    TTPlayerViewRenderTypeOutput = 100,
};

typedef NS_ENUM(NSInteger, TTPlayerViewRotateType) {
    TTPlayerViewRotateTypeNone = 0,
    TTPlayerViewRotateType90   = 1,/// 顺时针90度
    TTPlayerViewRotateType180  = 2,
    TTPlayerViewRotateType270  = 3,
};

typedef NS_ENUM(NSInteger, TTPlayerViewMirrorType) {
    TTPlayerViewMirrorTypeNone = 0,
    TTPlayerViewMirrorTypeH    = 1,
    TTPlayerViewMirrorTypeV    = 2,
    TTPlayerViewMirrorTypeHV   = 3,
};

typedef NS_ENUM(NSInteger, TTPlayerViewAlignMode) {
    TTPlayerViewAlignModeCenter = 0,
    TTPlayerViewAlignModeLeftTop = 1,
    TTPlayerViewAlignModeLeftCenter = 2,
    TTPlayerViewAlignModeLeftBottom = 3,
    TTPlayerViewAlignModeTopCenter = 4,
    TTPlayerViewAlignModeBottomCenter = 5,
    TTPlayerViewAlignModeRightTop = 6,
    TTPlayerViewAlignModeRightCenter = 7,
    TTPlayerViewAlignModeRightBottom = 8,
    TTPlayerViewAlignModeSelfDefineRatio = 9,
};

typedef NS_ENUM(NSInteger, TTPlayerViewKeyForValues) {
    TTPlayerViewPreferSpdlForHDR = 0,
    TTPlayerViewHandleBackgroundAvView = 1,
    TTPlayerViewDynTexSize = 2,
};

@protocol TTPlayerViewProtocol <NSObject>

@property (nonatomic, strong) id<TTAVPlayerProtocol> player;
@property (nonatomic, assign) TTPlayerViewAlignMode alignMode;
@property (nonatomic, assign) CGFloat alignRatio;
@property (nonatomic, assign) TTPlayerViewScaleType scaleType;
@property (nonatomic, assign) TTPlayerViewRenderType renderType;
@property (nonatomic, assign) TTPlayerViewRenderType lastRenderType;
@property (nonatomic, assign) TTPlayerViewRotateType rotateType;
@property (nonatomic, assign) BOOL memoryOptimizeEnabled;
@property (nonatomic, assign) CGRect cropAreaFrame;
@property (nonatomic, assign) CGRect normalizeCropArea;
@property (nonatomic, assign) BOOL useNormalizeCropArea;
@property (nonatomic, assign, readonly) CGRect videoAreaFrame;
@property (nonatomic, assign, getter=isSupportPictureInPictureMode) BOOL supportPictureInPictureMode;

- (BOOL)needRemoveView:(id<TTAVPlayerProtocol>) player;

- (void)setOptionForKey:(NSInteger)key value:(id)value;

- (void)updateVideoFrame;

- (void)releaseContents;

- (CVPixelBufferRef)copyPixelBuffer;

@end

#endif // TTM_DUAL_CORE_TTPLAYER_VIEW_PROTOCOL

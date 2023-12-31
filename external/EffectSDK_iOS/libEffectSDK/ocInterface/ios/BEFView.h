//
//  BEFGeneralPanelView.h
//  EffectSDK_iOS
//
//  Created by bytedance on 2020/8/11.
//

#import <UIKit/UIKit.h>
#import "bef_view_public_define.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BEFViewDelegate <NSObject>

/// process message ,return TRUE if processed, else return FALSE
/// @brief message callback
/// @param msgid message id
/// @param arg1 additional arg 1
/// @param arg2 additional arg 2
/// @param arg3 additional arg 3
/// @return return YES when success，return NO when fail
- (BOOL)msgProc :(unsigned int)msgid
           arg1 :(long)arg1
           arg2 :(long)arg2
           arg3 :(const char *)arg3;
@end

typedef NS_ENUM(NSUInteger, BEFViewFitMode) {
    FIT_WIDTH = 0,
    FIT_HEIGHT,
    FILL_SCREEN,
    FIT_WIDTH_BOTTOM,
    NO_CLIP
};

/// TouchData
typedef NS_ENUM(NSUInteger, BEFViewTouchStatus) {
    BEFViewTouchStatusBegin = 0,
    BEFViewTouchStatusMove,
    BEFViewTouchStatusEnd,
    BEFViewTouchStatusCancel,
};

typedef char* (*ResourceFinder)(void* effectHandle, const char* dir, const char* name);
typedef void  (*ResourceFinderReleaser)(void*);

@interface BEFViewInitParam : NSObject
@property(nonatomic, assign, nullable) void* effectHandle;//can be nil
@property(nonatomic, assign) CGSize renderSize;//{720,1280} by default
@property(nonatomic, assign) CGRect frame;//UIView frame
@property(nonatomic, assign) BEFViewFitMode fitMode;//FIT_WIDTH by default
@property(nonatomic, copy) NSString *bizId;//"livegame","shootpage","hostgift" etc
@property(nonatomic, assign) NSInteger fps;//fps, 60 by default
@property(nonatomic, assign, nullable) ResourceFinder resourceFinder;//resource finder
@property(nonatomic, assign, nullable) ResourceFinderReleaser resourceFinderReleaser;//resource finder releaser
@property(nonatomic, assign) BEFViewSceneKey sceneKey;//SHOOT by default
@property(nonatomic, assign) bool neglectTouchEvent;//need to neglect touch events
@end

@interface BEFView : UIView

@property (nonatomic, assign, readonly) NSInteger framesPerSecond;

- (id)initWithFrame:(CGRect)frame effectHandle:(void *)effectHandle;

- (id)initWithFrame:(CGRect)frame effectHandle:(void *)effectHandle resourceFinder:(nullable ResourceFinder)finder resourceReleaser:(nullable ResourceFinderReleaser) releaser;

- (id)initWithParam:(BEFViewInitParam *)param;

/// set fps, 60 by default
- (void)setFPS:(NSInteger)fps;

/// load sticker, input the path of sticker in bundle (for builtin resource)
- (BOOL)loadStickerPath:(NSString*)gamePath bundleName:(NSString*)bundleName;

/// load sticker, input absolute path of sticker in device (for downloaded resource)
- (BOOL)loadStickerFullPath:(NSString*)fullPath;


/// add/remove message delegate to outside from BEFGeneralPanelView
- (void)addMessageDelegate:(id<BEFViewDelegate>)delegate;
- (void)removeMessageDelegate:(id<BEFViewDelegate>)delegate;


/// messages that BEFGeneralPanelView will process  arrived 
- (int)messageArrived:(unsigned int)msgid arg1:(long)arg1 arg2:(long)arg2 arg3:(const char*)arg3;
// BEFGeneralPanelView post message to other effect instance or other client via delegate
- (int)postMessage:(unsigned int)msgid arg1:(long)arg1 arg2:(long)arg2 arg3:(const char*)arg3;

/// pause/resume
- (void)onPause;
- (void)onResume;

/// pass in touch events (have to forbid befview's own interation)
/// @brief external touch events
/// @param status BEFViewTouchStatusBegin/BEFViewTouchStatusMove/BEFViewTouchStatusEnd/BEFViewTouchStatusCancel
/// @param ids  touch.hash of all touches
/// @param xs x in locationInView of all touches
/// @param ys y in locationInView of all touches
/// @param num number of touches
/// @param pointerCount touch.pointerCount of all touches
- (void)setExternalTouchEvent:(BEFViewTouchStatus)status ids:(NSArray<NSNumber *> *)ids xs:(NSArray<NSNumber *> *)xs ys:(NSArray<NSNumber *> *)ys num:(NSInteger)num pointerCount:(NSInteger)pointerCount;

- (BOOL)setRenderCacheData:(NSString *)dataKey dataContent:(NSString *)dataContent;
- (BOOL)setRenderCacheTexture:(NSString *)textureKey texturePath:(NSString *)texturePath;
- (BOOL)setRenderCacheTextureWithBuffer:(NSString *)textureKey textureData:(const unsigned char*)data width:(long)width height:(long)height;
- (BOOL)setRenderCacheTextureWithPixelBuffer:(NSString *)key pixelBuffer:(nullable CVPixelBufferRef)pixelBuffer;
@end

NS_ASSUME_NONNULL_END

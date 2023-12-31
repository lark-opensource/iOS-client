#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

typedef bool (^ByteViewMTLRenderCallback)(id<MTLCommandBuffer> buffer);
typedef bool (^ByteViewAnimationRenderCallback)(void);

@interface ByteViewRenderTicker : NSObject

- (instancetype)initWithFPSList:(const NSInteger *)fpsList fpsCount:(NSInteger)fpsCount maxFPS:(NSInteger)maxFPS;

- (BOOL)registerMTLRenderCallbackWithID:(uint64_t)callbackID
                                fpsHint:(NSInteger)fps
                               callback:(ByteViewMTLRenderCallback)callback;

- (BOOL)unregisterCallbackWithID:(uint64_t)callbackID;
- (void)renderer:(uint64_t)renderID updatePreferredFPS:(NSInteger)fps;

- (void)updateFPSList:(const NSInteger *)fpsList fpsCount:(NSInteger)fpsCount maxFPS:(NSInteger)maxFPS;

@property(strong, nonatomic, readonly) id<MTLDevice> device;

@property(assign, atomic) BOOL dirty;

@end

NS_ASSUME_NONNULL_END

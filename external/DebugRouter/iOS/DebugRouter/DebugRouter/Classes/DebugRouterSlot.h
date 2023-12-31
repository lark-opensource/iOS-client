NS_ASSUME_NONNULL_BEGIN

@protocol DebugRouterSlotDelegate <NSObject>

@required
- (NSString *)getTemplateUrl;
- (void)onMessage:(NSString *)message WithType:(NSString *)type;

@end

@interface DebugRouterSlot : NSObject

@property(nonatomic, readwrite) int session_id;
@property(nonatomic, readwrite, weak) id<DebugRouterSlotDelegate> delegate;
@property(nonatomic, readwrite) NSString *type;

- (int)plug;
- (void)pull;
- (void)send:(NSString *)message;
- (void)sendData:(NSString *)data WithType:(NSString *)type;
- (void)sendData:(NSString *)data WithType:(NSString *)type WithMark:(int)mark;
;
- (void)sendAsync:(NSString *)message;
- (void)sendDataAsync:(NSString *)data WithType:(NSString *)type;
- (void)sendDataAsync:(NSString *)data
             WithType:(NSString *)type
             WithMark:(int)mark;
;

// delegate methods
- (NSString *)getTemplateUrl;
- (void)onMessage:(NSString *)message WithType:(NSString *)type;
#if defined(OS_IOS)
- (UIView *)getTemplateView;
#elif defined(OS_OSX)
- (NSView *)getTemplateView;
#endif

// dispatch specific messages
- (void)dispatchDocumentUpdated;
- (void)dispatchFrameNavigated:(NSString *)url;
- (void)dispatchScreencastVisibilityChanged:(BOOL)status;
- (void)clearScreenCastCache;
- (void)sendScreenCast:(NSString *)data andMetadata:(NSDictionary *)metadata;

@end

NS_ASSUME_NONNULL_END

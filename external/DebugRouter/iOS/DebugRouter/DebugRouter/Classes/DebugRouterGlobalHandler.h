NS_ASSUME_NONNULL_BEGIN

@protocol DebugRouterGlobalHandler <NSObject>

@required
- (void)openCard:(NSString *)url;
- (void)onMessage:(NSString *)message withType:(NSString *)type;

@end

NS_ASSUME_NONNULL_END

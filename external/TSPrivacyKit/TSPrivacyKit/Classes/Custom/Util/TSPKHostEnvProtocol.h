#import <mach/mach_types.h>


@protocol TSPKHostEnvProtocol <NSObject>

@required
#pragma mark - Other auxiliary protocol
- (nullable NSString *)urlIfTopIsWebViewController;
- (nullable NSString *)userRegion;

@optional

- (nullable NSString *)eventPrefix;
- (nullable NSArray *)crossPlatformCallingInfos;
- (nullable NSDictionary <NSString *, NSDictionary *> *)extraBizInfoWithGuardScene:(NSString *_Nullable)monitorScene permissionType:(NSString *_Nullable)permissionType;
- (nullable NSDictionary <NSString *,NSString *> *)extraCommonBizInfoWithGuardScene:(NSString *_Nullable)monitorScene permissionType:(NSString *_Nullable)permissionType;

- (BOOL)isEventBlocked:(NSString *_Nonnull)eventName;

- (nullable NSArray *)externalAspectAllowKlassList;

- (nullable NSDictionary *)appLifeCycleNotificationDictionary;

- (NSTimeInterval)currentServerTime;

@end



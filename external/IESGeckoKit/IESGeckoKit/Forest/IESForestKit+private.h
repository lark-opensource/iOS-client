#import "IESForestKit.h"

@interface IESForestKit ()

+ (NSString *)generateBucketWithDeviceID:(NSString *)deviceID;

/// open session to lock channel not update or change
- (BOOL)addChannelToChannelListWithSessionID:(NSString *)sessionId andAccessKey:(NSString *)accesskey andChannel:(NSString *)accesskey;
- (BOOL)containsChannelInChannelListWithSessionID:(NSString *)sessionId andAccessKey:(NSString *)accesskey andChannel:(NSString *)channel;

+ (NSMutableDictionary *)fetcherDictionary;

@end

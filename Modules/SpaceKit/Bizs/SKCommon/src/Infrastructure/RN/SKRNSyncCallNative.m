#import "SKRNSyncCallNative.h"
#import "SKCommon-Swift.h"
@implementation SKRNSyncCallNative
RCT_EXPORT_MODULE(RNSyncCallNative)
RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(featureGatingValue:(NSString *)key)
{
    return @([RNFGHelper featureGatingValueWithKey:key ?: @""]);
}
@end

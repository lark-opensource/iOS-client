
#import "TTClearCacheRule.h"
#import "TTDownloadLog.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TTClearCacheRule

- (id)init {
    self = [super init];
    if (self) {
        self.keyList = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    DLLOGD(@"dlLog:debug3:dealloc:function=%s addr=%p", __FUNCTION__, self);
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

NS_ASSUME_NONNULL_END

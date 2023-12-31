#import "TTDownloadMetaData.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTClearCacheRule : JSONModel

@property (nonatomic, copy, nonnull) NSString *clearId;
@property (nonatomic, assign) ClearRuleStatus clearRuleStatus;
@property (nonatomic, assign) ClearCacheType type;
@property (nonatomic, assign) BOOL isTncSet;
@property (nonatomic, strong, nullable) NSArray<NSString *> *keyList;

@end

NS_ASSUME_NONNULL_END

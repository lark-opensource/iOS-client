//
//  NLESegmentComposerFilter+iOS.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/2/7.
//

#ifndef NLESegmentComposerFilter_iOS_h
#define NLESegmentComposerFilter_iOS_h
#import "NLESegment+iOS.h"
#import "NLESegmentFilter+iOS.h"
#import "NLEResourceNode+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentComposerFilter_OC : NLESegmentFilter_OC

- (void)setEffectExtra:(NSString*)effectExtra;

- (NSString*)effectExtra;

- (void)setEffectTags:(NSDictionary<NSString *, NSNumber *> *)effectTags;

- (nullable NSDictionary<NSString *, NSNumber *> *)effectTags;

- (NSArray<NSString *> *)getNodePaths;

- (void)setNodePaths:(NSArray<NSString *> *)paths;

@end

NS_ASSUME_NONNULL_END

#endif /* NLESegmentComposerFilter_iOS_h */

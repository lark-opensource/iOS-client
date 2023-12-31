//
//  ACCSegmentBlender.h
//  CameraClient-Pods-Aweme
//
//  Created by Shen Chen on 2020/8/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@protocol ACCSegmentItem <NSObject, NSCopying>
@property (nonatomic, assign) double startPosition;
@property (nonatomic, assign) double endPosition;
@property (nonatomic, assign) CGFloat zorder;

- (BOOL)canMergeWith:(id<ACCSegmentItem>)item;
@end

@interface ACCSegmentBlender : NSObject

- (NSArray<NSObject<ACCSegmentItem> *>*)blendItems:(NSArray<NSObject<ACCSegmentItem> *> *)items;

@end

NS_ASSUME_NONNULL_END

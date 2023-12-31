//
//  ACCMultiAnchorOrdering.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Wu on 7/15/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMultiAnchorOrdering <NSObject>

// timestamp since 1970
@property (nonatomic, strong, nullable) NSNumber *creationTimestamp;

@end

NS_ASSUME_NONNULL_END

//
//  DVEAttacher.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/17.
//

#import <Foundation/Foundation.h>
#import "DVEAttachable.h"
#import "DVEMediaContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEAttacher : NSObject<DVEAttachable>

@property (nonatomic, strong) DVEMediaContext *context;
@property (nonatomic, assign, class, readonly) CGFloat attachThreshold;

// [CMTime]
@property (nonatomic, copy) NSArray<NSValue *> *attachablePoints;

- (instancetype)initWithContext:(DVEMediaContext *)context;

- (void)reloadPoints;

- (CGFloat)attachPoint:(CGFloat)point direction:(DVEAttachDirection)direction;

- (NSArray<NSNumber *> *)attachPoints:(NSArray<NSNumber *> *)points
                            direction:(DVEAttachDirection)direction;


@end

NS_ASSUME_NONNULL_END

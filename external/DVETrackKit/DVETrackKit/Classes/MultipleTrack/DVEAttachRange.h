//
//  DVEAttachRange.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEAttachRange : NSObject

@property (nonatomic, assign) CGFloat minX;
@property (nonatomic, assign) CGFloat maxX;

- (instancetype)initWithMinX:(CGFloat)minX maxX:(CGFloat)maxX;

@end

NS_ASSUME_NONNULL_END

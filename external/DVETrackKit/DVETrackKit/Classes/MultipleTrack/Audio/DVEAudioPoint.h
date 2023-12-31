//
//  DVEAudioPoint.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEAudioPoint : NSObject

@property (nonatomic, assign) CGFloat point;
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat speed;

- (instancetype)initWithX:(CGFloat)x point:(CGFloat)point speed:(CGFloat)speed;

@end

NS_ASSUME_NONNULL_END

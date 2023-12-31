//
//  DVERulerModel.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVERulerModel : NSObject

@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) CGFloat interval;
@property (nonatomic, assign) CGFloat reference;

- (instancetype)initWithCount:(NSInteger)count
                     interval:(CGFloat)interval
                    reference:(CGFloat)reference;

@end

NS_ASSUME_NONNULL_END

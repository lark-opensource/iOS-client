//
//  ACCStickerTimeRangeModel.h
//  CameraClient
//
//  Created by liuqing on 2020/6/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerTimeRangeModel : NSObject <NSCopying>

@property (nonatomic, strong, nullable) NSDecimalNumber *pts;
@property (nonatomic, strong, nullable) NSDecimalNumber *startTime; // ms
@property (nonatomic, strong, nullable) NSDecimalNumber *endTime; // ms

- (void)reset;

@end

NS_ASSUME_NONNULL_END

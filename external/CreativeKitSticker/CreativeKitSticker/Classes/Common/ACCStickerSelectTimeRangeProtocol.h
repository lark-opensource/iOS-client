//
//  ACCStickerSelectTimeRangeProtocol.h
//  CameraClient
//
//  Created by Haoyipeng on 2020/3/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerSelectTimeRangeProtocol <NSObject>

@property (nonatomic, assign) CGFloat realStartTime;
@property (nonatomic, assign) CGFloat realDuration;
@property (nonatomic, assign) CGFloat finalStartTime;
@property (nonatomic, assign) CGFloat finalDuration;

@end

NS_ASSUME_NONNULL_END

//
//  ACCStickerGeometryModel.h
//  CameraClient
//
//  Created by liuqing on 2020/6/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerGeometryModel : NSObject <NSCopying>

@property (nonatomic, strong, nullable) NSDecimalNumber * x;
@property (nonatomic, strong, nullable) NSDecimalNumber * y;
@property (nonatomic, strong, nullable) NSDecimalNumber * xRatio;
@property (nonatomic, strong, nullable) NSDecimalNumber * yRatio;
@property (nonatomic, strong, nullable) NSDecimalNumber * width;
@property (nonatomic, strong, nullable) NSDecimalNumber * height;
@property (nonatomic, strong, nullable) NSDecimalNumber * rotation;
@property (nonatomic, strong, nullable) NSDecimalNumber * scale;

@property (nonatomic, assign) BOOL preferredRatio;

- (void)reset;

@end

NS_ASSUME_NONNULL_END

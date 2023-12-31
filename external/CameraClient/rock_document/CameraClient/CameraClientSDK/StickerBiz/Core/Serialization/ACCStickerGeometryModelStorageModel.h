//
//  ACCStickerGeometryModelStorageModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/21.
//

#import <Mantle/MTLModel.h>
#import "ACCSerializationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerGeometryModelStorageModel : MTLModel<ACCSerializationProtocol>

@property (nonatomic, strong, nullable) NSDecimalNumber * x;
@property (nonatomic, strong, nullable) NSDecimalNumber * y;
@property (nonatomic, strong, nullable) NSDecimalNumber * xRatio;
@property (nonatomic, strong, nullable) NSDecimalNumber * yRatio;
@property (nonatomic, strong, nullable) NSDecimalNumber * width;
@property (nonatomic, strong, nullable) NSDecimalNumber * height;
@property (nonatomic, strong, nullable) NSDecimalNumber * rotation;
@property (nonatomic, strong, nullable) NSDecimalNumber * scale;

@property (nonatomic, assign) BOOL preferredRatio;

@end

NS_ASSUME_NONNULL_END

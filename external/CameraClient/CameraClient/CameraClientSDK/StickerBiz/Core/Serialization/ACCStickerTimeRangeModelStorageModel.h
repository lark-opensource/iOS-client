//
//  ACCStickerTimeRangeModelStorageModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/21.
//

#import <Mantle/MTLModel.h>
#import "ACCSerializationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerTimeRangeModelStorageModel : MTLModel<ACCSerializationProtocol>

@property (nonatomic, strong, nullable) NSDecimalNumber *pts;
@property (nonatomic, strong, nullable) NSDecimalNumber *startTime; // ms
@property (nonatomic, strong, nullable) NSDecimalNumber *endTime; // ms

@end

NS_ASSUME_NONNULL_END

//
//  ACCBeautyState.h
//  CameraClient
//
//  Created by luochaojing on 2019/12/25.
//

#import <Mantle/Mantle.h>
#import <CreationKitRTProtocol/ACCCameraDefine.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCBeautyState : MTLModel

// 美颜
@property (nonatomic, copy) NSString *beautyPath;
@property (nonatomic, assign) float smoothValue;
@property (nonatomic, assign) float sharpValue;
@property (nonatomic, assign) float whiteValue;

// 形变
@property (nonatomic, copy) NSString *reshapePath;
@property (nonatomic, assign) float bigEyeValue;
@property (nonatomic, assign) float faceLiftValue;

// 美妆
@property (nonatomic, copy) NSString *makeupPath;
@property (nonatomic, assign) float blusherValue;
@property (nonatomic, assign) float lipStickerValue;
@property (nonatomic, assign) float decreeValue;
@property (nonatomic, assign) float pouchValue;

+ (ACCBeautyState *)state;

@end

NS_ASSUME_NONNULL_END

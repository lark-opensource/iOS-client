//
//  ACCBeautyAction.h
//  CameraClient
//
//  Created by luochaojing on 2019/12/25.
//

#import <CameraClient/ACCAction.h>
#import <CreationKitRTProtocol/ACCCameraDefine.h>
#import <Mantle/Mantle.h>

typedef NS_ENUM(NSUInteger, ACCBeautyActionType) {
    ACCBeautyActionTypeApplyLVBeauty,
    ACCBeautyActionTypeApplyBeauty,
    ACCBeautyActionTypeChangeBeautyRatio
};

NS_ASSUME_NONNULL_BEGIN

@interface ACCBeautyParam : NSObject

@property (nonatomic, strong) NSNumber *sharpValue;
@property (nonatomic, strong) NSNumber *whiteValue;
@property (nonatomic, strong) NSNumber *smoothValue;

+ (instancetype)paramWithSharpValue:(NSNumber *)sharpValue
                         whiteValue:(NSNumber *)whiteValue
                        smoothValue:(NSNumber *)smoothValue;

@end

@interface ACCBeautyReshapeParam : NSObject

@property (nonatomic, strong) NSNumber *bigEyeValue;
@property (nonatomic, strong) NSNumber *faceLiftValue;

+ (instancetype)paramWithBigEyeValue:(NSNumber *)bigEyeValue
                       faceLiftValue:(NSNumber *)faceLiftValue;

@end

@interface ACCBeautyMakeupParam : NSObject

@property (nonatomic, strong) NSNumber *blusherValue;
@property (nonatomic, strong) NSNumber *lipStickerValue;
@property (nonatomic, strong) NSNumber *decreeValue;
@property (nonatomic, strong) NSNumber *pouchValue;

+ (instancetype)paramWithBlusherValue:(NSNumber *)blusherValue
                      lipStickerValue:(NSNumber *)lipStickerValue
                          decreeValue:(NSNumber *)decreeValue
                           pouchValue:(NSNumber *)pouchValue;

@end

@interface ACCBeautyAction : ACCAction

@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign) ACCCameraBeautyType beautyType;
@property (nonatomic, assign) Float64 value;

@property (nonatomic, strong) ACCBeautyParam *beautyParam;
@property (nonatomic, strong) ACCBeautyReshapeParam *reshapeParam;
@property (nonatomic, strong) ACCBeautyMakeupParam *makeupParam;

// apply beauty action
+ (instancetype)createLVBeautyWithType:(ACCCameraBeautyType)type
                                 value:(CGFloat)value
                                  path:(NSString *)path;
+ (instancetype)createApplyBeautyWithPath:(NSString *)path param:(ACCBeautyParam *)param;
+ (instancetype)createApplyBeautyWithPath:(NSString *)path
                               sharpValue:(NSNumber *)sharpValue
                               whiteValue:(NSNumber *)whiteValue
                              smoothValue:(NSNumber *)smoothValue;

+ (instancetype)createApplyReshpaWithPath:(NSString *)path param:(ACCBeautyReshapeParam *)param;
+ (instancetype)createApplyReshpaWithPath:(NSString *)path
                            faceLiftValue:(NSNumber *)faceLiftValue
                              bigEyeValue:(NSNumber *)bigValue;

+ (instancetype)createApplyMakeupWithPath:(NSString *)path param:(ACCBeautyMakeupParam *)param;
+ (instancetype)createApplyMakeupWithPath:(NSString *)path
                             blusherValue:(NSNumber *)bluserValue
                          lipStickerValue:(NSNumber *)lipStickerValue
                              decreeValue:(NSNumber *)decreeValue
                               pouchValue:(NSNumber *)pouchValue;

// change beauty ratio action
+ (instancetype)createChangeBeautyWtihParam:(ACCBeautyParam *)param;
+ (instancetype)createChangeBeautyWtihParam:(ACCBeautyParam *)param
                                 sharpValue:(NSNumber *)sharpValue
                                 whiteValue:(NSNumber *)whiteValue
                                smoothValue:(NSNumber *)smoothValue;

+ (instancetype)createChangeReshpaWithParam:(ACCBeautyReshapeParam *)param;
+ (instancetype)createChangeReshpaWithParam:(ACCBeautyReshapeParam *)param
                              faceLiftValue:(NSNumber *)faceLiftValue
                                bigEyeValue:(NSNumber *)bigValue;

+ (instancetype)createChangeMakeupWithParam:(ACCBeautyMakeupParam *)param;
+ (instancetype)createChangeMakeupWithParam:(ACCBeautyMakeupParam *)param
                               blusherValue:(NSNumber *)bluserValue
                            lipStickerValue:(NSNumber *)lipStickerValue
                                decreeValue:(NSNumber *)decreeValue
                                 pouchValue:(NSNumber *)pouchValue;

@end

NS_ASSUME_NONNULL_END

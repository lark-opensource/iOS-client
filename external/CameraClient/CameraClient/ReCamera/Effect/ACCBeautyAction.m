//
//  ACCBeautyAction.m
//  CameraClient
//
//  Created by luochaojing on 2019/12/25.
//

#import "ACCBeautyAction.h"

@implementation ACCBeautyParam

+ (instancetype)paramWithSharpValue:(NSNumber *)sharpValue
                         whiteValue:(NSNumber *)whiteValue
                        smoothValue:(NSNumber *)smoothValue
{
    ACCBeautyParam *param = [[ACCBeautyParam alloc] init];
    param.sharpValue = sharpValue;
    param.whiteValue = whiteValue;
    param.smoothValue = smoothValue;
    return param;
}

@end

@implementation ACCBeautyReshapeParam

+ (instancetype)paramWithBigEyeValue:(NSNumber *)bigEyeValue
                       faceLiftValue:(NSNumber *)faceLiftValue
{
    ACCBeautyReshapeParam *param = [[ACCBeautyReshapeParam alloc] init];
    param.bigEyeValue = bigEyeValue;
    param.faceLiftValue = faceLiftValue;
    return param;
}

@end

@implementation ACCBeautyMakeupParam

+ (instancetype)paramWithBlusherValue:(NSNumber *)blusherValue
                      lipStickerValue:(NSNumber *)lipStickerValue
                          decreeValue:(NSNumber *)decreeValue
                           pouchValue:(NSNumber *)pouchValue
{
    ACCBeautyMakeupParam *param = [[ACCBeautyMakeupParam alloc] init];
    param.blusherValue = blusherValue;
    param.lipStickerValue = lipStickerValue;
    param.decreeValue = decreeValue;
    param.pouchValue = pouchValue;
    return param;
}


@end

@implementation ACCBeautyAction

+ (instancetype)createLVBeautyWithType:(ACCCameraBeautyType)type
                                 value:(CGFloat)value
                                  path:(NSString *)path {
    ACCBeautyAction *action = [ACCBeautyAction action];
    action.beautyType = type;
    action.value = value;
    action.path = path;
    action.type = ACCBeautyActionTypeApplyLVBeauty;
    return action;
}

+ (instancetype)createBeautyApplyActionWithParam:(ACCBeautyParam *)param
{
    ACCBeautyAction *action = [ACCBeautyAction action];
    action.beautyType = ACCCameraBeautyTypeBeauty;
    action.beautyParam = param;
    return action;
}

+ (instancetype)createReshapeApplyActionWithParam:(ACCBeautyReshapeParam *)param
{
    ACCBeautyAction *action = [ACCBeautyAction action];
    action.beautyType = ACCCameraBeautyTypeReshape;
    action.reshapeParam = param;
    return action;
}

+ (instancetype)createMakeupApplyActionWithParam:(ACCBeautyMakeupParam *)param
{
    ACCBeautyAction *action = [ACCBeautyAction action];
    action.beautyType = ACCCameraBeautyTypeMakeup;
    action.makeupParam = param;
    return action;
}

// apply beauty action
+ (instancetype)createApplyBeautyWithPath:(NSString *)path param:(ACCBeautyParam *)param
{
    ACCBeautyAction *action = [ACCBeautyAction createBeautyApplyActionWithParam:param];
    action.path = path;
    return action;
}

+ (instancetype)createApplyBeautyWithPath:(NSString *)path
                               sharpValue:(NSNumber *)sharpValue
                               whiteValue:(NSNumber *)whiteValue
                              smoothValue:(NSNumber *)smoothValue
{
    return [self createApplyBeautyWithPath:path
                                     param:[ACCBeautyParam paramWithSharpValue:sharpValue
                                                                    whiteValue:whiteValue
                                                                   smoothValue:smoothValue]];
}

+ (instancetype)createApplyReshpaWithPath:(NSString *)path param:(ACCBeautyReshapeParam *)param
{
    ACCBeautyAction *action = [ACCBeautyAction createReshapeApplyActionWithParam:param];
    action.path = path;
    return action;
}

+ (instancetype)createApplyReshpaWithPath:(NSString *)path
                            faceLiftValue:(NSNumber *)faceLiftValue
                              bigEyeValue:(NSNumber *)bigValue
{
    return [self createApplyReshpaWithPath:path
                                     param:[ACCBeautyReshapeParam paramWithBigEyeValue:bigValue
                                                                         faceLiftValue:faceLiftValue]];
}

+ (instancetype)createApplyMakeupWithPath:(NSString *)path param:(ACCBeautyMakeupParam *)param
{
    ACCBeautyAction *action = [ACCBeautyAction createMakeupApplyActionWithParam:param];
    action.path = path;
    return action;
}

+ (instancetype)createApplyMakeupWithPath:(NSString *)path
                             blusherValue:(NSNumber *)bluserValue
                          lipStickerValue:(NSNumber *)lipStickerValue
                              decreeValue:(NSNumber *)decreeValue
                               pouchValue:(NSNumber *)pouchValue
{
    return [self createApplyMakeupWithPath:path
                                     param:[ACCBeautyMakeupParam paramWithBlusherValue:bluserValue
                                                                       lipStickerValue:lipStickerValue
                                                                           decreeValue:decreeValue
                                                                            pouchValue:pouchValue]];
}

// change beauty ratio action
+ (instancetype)createChangeBeautyWtihParam:(ACCBeautyParam *)param
{
    return [self createBeautyApplyActionWithParam:param];
}

+ (instancetype)createChangeBeautyWtihParam:(ACCBeautyParam *)param
                                 sharpValue:(NSNumber *)sharpValue
                                 whiteValue:(NSNumber *)whiteValue
                                smoothValue:(NSNumber *)smoothValue
{
    return [self createChangeBeautyWtihParam:[ACCBeautyParam paramWithSharpValue:sharpValue
                                                                      whiteValue:whiteValue
                                                                     smoothValue:smoothValue]];
}

+ (instancetype)createChangeReshpaWithParam:(ACCBeautyReshapeParam *)param
{
    return [self createReshapeApplyActionWithParam:param];
}

+ (instancetype)createChangeReshpaWithParam:(ACCBeautyReshapeParam *)param
                              faceLiftValue:(NSNumber *)faceLiftValue
                                bigEyeValue:(NSNumber *)bigValue
{
    return [self createChangeReshpaWithParam:[ACCBeautyReshapeParam paramWithBigEyeValue:bigValue
                                                                    faceLiftValue:faceLiftValue]];
}

+ (instancetype)createChangeMakeupWithParam:(ACCBeautyMakeupParam *)param
{
    return [self createMakeupApplyActionWithParam:param];
}

+ (instancetype)createChangeMakeupWithParam:(ACCBeautyMakeupParam *)param
                               blusherValue:(NSNumber *)bluserValue
                            lipStickerValue:(NSNumber *)lipStickerValue
                                decreeValue:(NSNumber *)decreeValue
                                 pouchValue:(NSNumber *)pouchValue
{
    return [self createChangeMakeupWithParam:[ACCBeautyMakeupParam paramWithBlusherValue:bluserValue
                                                                         lipStickerValue:lipStickerValue
                                                                             decreeValue:decreeValue
                                                                              pouchValue:pouchValue]];
}

@end

//
//  BDTuringVerifyModel+Creator.h
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringVerifyModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringVerifyModel (Creator)

/// commom captcha like text selection and 3D selection
+ (instancetype)pictureModelWithCode:(NSInteger)code;

/// model from the total parameter from the server, work in some specific scenes
+ (instancetype)parameterModelWithParameter:(NSDictionary *)parameter;

+ (instancetype)smsModelWithScene:(NSString *)scene;

+ (instancetype)preloadModel;

@end

NS_ASSUME_NONNULL_END

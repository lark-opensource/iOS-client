//
//  AWE2DStickerTextGenerator.h
//  AAWELaunchMainPlaceholder-iOS8.0
//
//  Created by 赖霄冰 on 2019/4/15.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/IESMMEffectProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWE2DStickerTextGenerator : NSObject

+ (IESEffectBitmapStruct)generate2DTextBitmapWithText:(NSString *)text textLayout:(IESEffectTextLayoutStruct)layout;

@end

NS_ASSUME_NONNULL_END

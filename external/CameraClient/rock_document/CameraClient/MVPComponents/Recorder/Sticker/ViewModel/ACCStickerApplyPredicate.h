//
//  ACCStickerApplyPredicate.h
//  AWEStudio-Pods-DouYin
//
//  Created by Howie He on 2020/8/17.
//

#import <Foundation/Foundation.h>
@class IESEffectModel;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerApplyPredicate <NSObject>

- (BOOL)shouldApplySticker:(IESEffectModel *)sticker error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

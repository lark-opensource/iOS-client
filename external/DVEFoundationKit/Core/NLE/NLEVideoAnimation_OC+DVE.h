//
//  NLEVideoAnimation_OC+DVE.h
//  NLEPlatform
//
//  Created by bytedance on 2021/4/13.
//

#import <NLEPlatform/NLEVideoAnimation+iOS.h>

typedef NS_ENUM(NSUInteger, NLEVideoAnimationType) {
    NLEVideoAnimationTypeNone,
    NLEVideoAnimationTypeIn,
    NLEVideoAnimationTypeOut,
    NLEVideoAnimationTypeCombination,
};

NS_ASSUME_NONNULL_BEGIN

@interface NLEVideoAnimation_OC (DVE)

@property (nonatomic, assign) NLEVideoAnimationType dve_animationType;

@end

NS_ASSUME_NONNULL_END

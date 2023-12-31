//
//  ACCFontProtocol.h
//  Pods
//
//  Created by Liu Deping on 2019/9/16.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCFontWeight) {
    ACCFontWeightUltraLight,
    ACCFontWeightThin,
    ACCFontWeightLight,
    ACCFontWeightRegular,
    ACCFontWeightMedium,
    ACCFontWeightSemibold,
    ACCFontWeightBold,
    ACCFontWeightHeavy,
    ACCFontWeightBlack
};

typedef NS_ENUM(NSInteger, ACCFontClass) {
    ACCFontClassH0 = -1,
    ACCFontClassH1 = 0,
    ACCFontClassH2,
    ACCFontClassH3,
    ACCFontClassH4,
    ACCFontClassP1,
    ACCFontClassP2,
    ACCFontClassP3,
    ACCFontClassSmallText1,
    ACCFontClassSmallText2
};

// Custom
@protocol ACCFontProtocol <NSObject>

- (UIFont *)systemFontOfSize:(CGFloat)fontSize;
- (UIFont *)systemFontOfSize:(CGFloat)fontSize weight:(ACCFontWeight)weight;
- (UIFont *)boldSystemFontOfSize:(CGFloat)fontSize;

/// Adaptive font size, font size will be larger if support big font mode and it is on.
/// @param fontSize font size will be larger if support big font mode and it is on.
- (UIFont *)acc_boldSystemFontOfSize:(CGFloat)fontSize;

/// Adaptive font size, font size will be larger if support big font mode and it is on.
/// @param fontClass ACCFontClass
/// @param weight ACCFontWeight
- (UIFont *)acc_fontOfClass:(ACCFontClass)fontClass weight:(ACCFontWeight)weight;

@optional

/**
 @param ttfPath ttf file full address
 @param iconFontName iconFont name
 @param iconFontSize iconFont size
 */
- (UIFont *)iconFontWithPath:(NSURL *)ttfPath name:(NSString *)iconFontName size:(CGFloat)iconFontSize;

- (UIFont *)fontOfClass:(ACCFontClass)fontClass weight:(ACCFontWeight)weight;

/* Big Font. If bigFontMode is enabled, it will use larger font size; otherwise, it will use original implementation. */

/// check if big font mode is on
- (BOOL)acc_bigFontModeOn;

/// convert fontSize to larger font size if big font mode is on
/// @param fontSize original fontSize
- (CGFloat)getAdaptiveFontSize:(CGFloat)fontSize;

/// Adaptive font size, font size will be larger if big font mode is on.
/// @param fontSize font size will be larger if big font mode is on.
- (UIFont *)acc_systemFontOfSize:(CGFloat)fontSize;

/// Adaptive font size, font size will be larger if big font mode is on.
/// @param fontSize font size will be larger if big font mode is on.
/// @param weight ACCFontWeight
- (UIFont *)acc_systemFontOfSize:(CGFloat)fontSize weight:(ACCFontWeight)weight;

@end

FOUNDATION_STATIC_INLINE id<ACCFontProtocol> ACCFont() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCFontProtocol)];
}

FOUNDATION_STATIC_INLINE UIFont *ACCStandardFont(ACCFontClass fontClass, ACCFontWeight weight) {
    if ([ACCFont() respondsToSelector:@selector(fontOfClass:weight:)]) {
        return [ACCFont() fontOfClass:fontClass weight:weight];
    }
    return nil;
}

NS_ASSUME_NONNULL_END

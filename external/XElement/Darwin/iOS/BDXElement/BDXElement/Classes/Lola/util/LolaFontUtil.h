//
//  LolaFontUtil.h
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/11/4.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LolaFontStyle) {
  LolaFontStyleNormal = 0,
  LolaFontStyleItalic,
  LolaFontStyleOblique
};

//*font-style  font-variant font-weight font-size/line-height font-family

@interface LolaTextStyle : NSObject 

@property(nonatomic, assign) CGFloat fontSize;
@property(nonatomic, assign) CGFloat lineHeight;
@property(nonatomic, assign) CGFloat fontWeight;
@property(nonatomic, assign) LolaFontStyle fontStyle;

@end

@interface LolaFontUtil : NSObject

+(UIFont *)parseFontWithStyle:(NSString *)stringStyle;

+ (UIFont *)getFontFromTextStyle:(LolaTextStyle *)style;

@end

NS_ASSUME_NONNULL_END

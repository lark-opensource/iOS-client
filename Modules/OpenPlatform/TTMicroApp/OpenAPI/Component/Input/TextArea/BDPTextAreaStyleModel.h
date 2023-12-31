//
//  BDPTextAreaStyleModel.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/4.
//

#import <JSONModel/JSONModel.h>
#import <UIKit/UIKit.h>

@interface BDPTextAreaStyleModel : JSONModel

// Frame
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat left;
@property (nonatomic, assign) CGFloat top;
// Font
@property (nonatomic, copy) NSString *color;
@property (nonatomic, copy) NSString *backgroundColor;
@property (nonatomic, copy) NSString *fontFamily;
@property (nonatomic, copy) NSString *fontWeight;
@property (nonatomic, assign) CGFloat fontSize;
// AutoHeight Range
@property (nonatomic, assign) CGFloat minHeight;
@property (nonatomic, assign) CGFloat maxHeight;
// Text
@property (nonatomic, assign) CGFloat lineSpace;
@property (nonatomic, assign) CGFloat lineHeight;
@property (nonatomic, copy) NSString *textAlign;
// Keyboard
@property (nonatomic, assign) CGFloat marginBottom;

- (CGRect)frame;
- (UIFont *)font; // 字体（通过fontFamily，fontWeight，fontSize获取）
- (NSTextAlignment)textAlignment; // 对齐方式（通过textAlign获取）
- (void)updateWithDictionary:(NSDictionary *)dict;

@end

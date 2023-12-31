//
//  BDPInputViewStyleModel.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/4.
//

#import <UIKit/UIKit.h>
#import <JSONModel/JSONModel.h>

@interface BDPInputViewStyleModel : JSONModel
// Frame
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat left;
@property (nonatomic, assign) CGFloat top;
// Font
@property (nonatomic, copy) NSString *color;
@property (nonatomic, copy) NSString *fontFamily;
@property (nonatomic, copy) NSString *fontWeight;
@property (nonatomic, assign) CGFloat fontSize;
// Background
@property (nonatomic, copy) NSString *backgroundColor;
// Text
@property (nonatomic, copy) NSString *textAlign;
// Keyboard
@property (nonatomic, assign) CGFloat marginBottom; //TODO

- (CGRect)frame;
- (UIFont *)font; // 字体（通过fontFamily，fontWeight，fontSize获取）
- (NSTextAlignment)textAlignment; // 对齐方式（通过textAlign获取）
- (void)updateWithDictionary:(NSDictionary *)dict;

@end

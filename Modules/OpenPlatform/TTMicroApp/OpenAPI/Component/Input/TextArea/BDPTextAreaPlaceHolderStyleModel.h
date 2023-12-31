//
//  BDPTextAreaPlaceHolderStyleModel.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/4.
//

#import <JSONModel/JSONModel.h>
#import <UIKit/UIKit.h>

@interface BDPTextAreaPlaceHolderStyleModel : JSONModel

@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, copy) NSString *fontWeight;
@property (nonatomic, copy) NSString *fontFamily;
@property (nonatomic, copy) NSString *color;

- (UIFont *)font;
- (void)updateWithDictionary:(NSDictionary *)dict;

@end

//
//  BDPInputViewPlaceHolderStyleModel.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/4.
//

#import <JSONModel/JSONModel.h>

@interface BDPInputViewPlaceHolderStyleModel : JSONModel

@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, copy) NSString *fontWeight;
@property (nonatomic, copy) NSString *fontFamily;
@property (nonatomic, copy) NSString *color;

- (NSDictionary *)attributedStyle;
- (void)updateWithDictionary:(NSDictionary *)dict;

@end


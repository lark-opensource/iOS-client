//
//  CJPayStyleCheckBox.h
//  CJPay
//
//  Created by liyu on 2019/10/28.
//

#import "CJPayButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayStyleCheckBox : CJPayButton

@property (nonatomic, strong) UIColor *selectedCheckBoxColor UI_APPEARANCE_SELECTOR;

- (void)updateWithCheckImgName:(NSString *)checkImgName
                noCheckImgName:(NSString *)noCheckImgName;

@end

NS_ASSUME_NONNULL_END

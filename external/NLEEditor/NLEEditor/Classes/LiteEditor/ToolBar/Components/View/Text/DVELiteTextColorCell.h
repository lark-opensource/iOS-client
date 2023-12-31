//
//  DVELiteTextColorCell.h
//  NLEEditor
//
//  Created by pengzhenhuan on 2022/1/19.
//

#import <UIKit/UIKit.h>
#import "DVEPickerBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVELiteTextColorCell : DVEPickerBaseCell

//参考颜色，根据当前cell颜色值和参考的颜色比较是否需要添加边框
@property (nonatomic, copy) NSArray<NSNumber *> *referColorArray;

@end

NS_ASSUME_NONNULL_END

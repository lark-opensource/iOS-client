//
//  BDPRegionPickerPluginModel.h
//  Timor
//
//  Created by 刘相鑫 on 2019/1/15.
//

#import "BDPBaseJSONModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPRegionPickerPluginModel : BDPBaseJSONModel

/**
 * 当前选中的地区，例如['北京市', '北京市', '海淀区']，如果不传或者传了非法值，选中第一个
 */
@property (nonatomic, copy) NSArray *current;
/**
 * 在每一列的顶部添加一个自定义的项，可以是任意字符串
 */
@property (nonatomic, copy) NSString *customItem;

@end

NS_ASSUME_NONNULL_END

//
//  CJPayBioGuideInfoModel.h
//  Pods
//
//  Created by 孔伊宁 on 2021/9/26.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN
// 各参数详细含义见https://bytedance.feishu.cn/wiki/wikcnrJ7O0HafimmxrmMliIBJIc#Da84d6ESEoo0eOxe43YcJclknFg

@interface CJPayBioGuideInfoModel : JSONModel

@property (nonatomic, copy) NSString *title; // 引导文案
@property (nonatomic, assign) BOOL choose; // 是否默认勾选
@property (nonatomic, copy) NSString *bioType; // 生物类型（"FINGER"：指纹，其他：面容）
@property (nonatomic, copy) NSString *guideStyle; // 勾选框样式（"SWITCH"：switch开关样式，其他checkbox样式）
@property (nonatomic, copy) NSString *btnDesc; // 勾选引导后的确认按钮文案
@property (nonatomic, assign) BOOL isShowButton; // 是否展示确认按钮

@end

NS_ASSUME_NONNULL_END

//
//  CJPaySkipPwdGuideInfoModel.h
//  Pods
//
//  Created by 尚怀军 on 2021/3/11.
//

#import "CJPayBaseGuideInfoModel.h"
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN
@interface BDPaySkipPwdSubGuideInfoModel : JSONModel

@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *iconDesc;

@end

@protocol CJPayMemAgreementModel;
@protocol BDPaySkipPwdSubGuideInfoModel;
// 各参数详细含义见https://bytedance.feishu.cn/wiki/wikcnrJ7O0HafimmxrmMliIBJIc#Fk8adAiSmoEQeox4ugAcdNhpnjd
@interface CJPaySkipPwdGuideInfoModel : CJPayBaseGuideInfoModel

@property (nonatomic, assign) BOOL isChecked;                             // 是否需要默认勾选
@property (nonatomic, assign) BOOL isSelectedManually;                    // 是否后续选中
@property (nonatomic, assign) BOOL isShowButton;                          // 是否展示确认按钮
@property (nonatomic, copy) NSString *guideType;                          // 免密引导的类型（提额/首次开通）
@property (nonatomic, copy) NSArray<BDPaySkipPwdSubGuideInfoModel> *subGuide; // 支付后提额引导副标题（icon+text）
@property (nonatomic, assign) NSInteger quota;    // 支付后提额引导的提升额度
@property (nonatomic, copy) NSString *guideStyle; //支付后免密提额引导样式
@property (nonatomic, copy) NSString *style; // 支付中免密引导样式（checkbox或switch）

@end

NS_ASSUME_NONNULL_END

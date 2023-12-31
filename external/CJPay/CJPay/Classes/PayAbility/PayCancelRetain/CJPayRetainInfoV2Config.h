//
//  CJPayRetainInfoV2Config.h
//  Aweme
//
//  Created by ByteDance on 2023/4/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayRetainInfoV2Config : NSObject // 参数信息可参照 https://bytedance.feishu.cn/docx/AjV4d2SBgoUmCbxksKocc9xunke

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *zgAppId;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *jhMerchantId;
@property (nonatomic, copy) NSString *traceId;
@property (nonatomic, copy) NSString *retainSchema; // lynx挽留弹窗的shema
@property (nonatomic, assign) BOOL notShowRetain; // 不展示取消挽留
// 以下参数用在验密流程
@property (nonatomic, copy) NSString *hostDomain;
@property (nonatomic, copy) NSDictionary *processInfo;
@property (nonatomic, copy) NSDictionary *retainInfoV2; // retainInfoV2 整个传给前端
@property (nonatomic, copy) NSString *selectedPayType; // 当前选中的支付方式 （若传向前端为空，则证明query_pay_type还未返回）
@property (nonatomic, copy) NSString *fromScene; // 打开挽留的场景
@property (nonatomic, assign) BOOL hasInputHistory; //是否输入过密码（一个数字也算）
@property (nonatomic, assign) BOOL hasTridInputPassword; // 是否验证过密码或者点击忘记密码
@property (nonatomic, assign) BOOL isOnlyShowNormalRetainStyle; // 是否仅仅展示无营销兜底挽留弹窗 (目前仅由「是否切换支付方式」控制)
@property (nonatomic, assign) BOOL defaultDialogHasVoucher; // 兜底挽留是否为有营销状态

//以下参数用在标准收银台首页
@property (nonatomic, copy) NSString *index; // 当前选中的支付方式的index
@property (nonatomic, copy) NSString *from; //前端判断是哪个端调用的
@property (nonatomic, copy) NSString *method; // 对齐聚合收银台上报埋点的method取值逻辑
@property (nonatomic, assign) BOOL isCombinePay; // 是否是组合支付

//O项目挽留弹窗
@property (nonatomic, copy) NSString *templateId; // 商家模版ID

- (NSDictionary *)buildFEParams;
- (BOOL)isOpenLynxRetain;

@end

NS_ASSUME_NONNULL_END

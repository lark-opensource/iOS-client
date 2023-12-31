//
//  CJPayBindCardPageBaseModel.h
//  Pods
//
//  Created by xutianxi on 2022/1/17.
//

#import <JSONModel/JSONModel.h>
#import "CJPayBindCardShareDataKeysDefine.h"

NS_ASSUME_NONNULL_BEGIN

// 绑卡流程页面 ViewController 需要获取共享数据需要实现的协议
@protocol CJPayBindCardPageModelProtocol;

@protocol CJPayBindCardPageProtocol <NSObject>

@required
+ (Class <CJPayBindCardPageModelProtocol>)associatedModelClass;
- (void)createAssociatedModelWithParams:(NSDictionary <NSString *, id> *)dict;

@end

// 绑卡流程页面 ViewModel 需要实现的协议
@protocol CJPayBindCardPageModelProtocol <NSObject>

@required
+ (NSArray <NSString *>*)keysOfParams;

@end

@interface CJPayBindCardPageBaseModel : JSONModel <CJPayBindCardPageModelProtocol>

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict;

@end

NS_ASSUME_NONNULL_END

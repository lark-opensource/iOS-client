//
//  BDPPackageCardProjectConfigModel.h
//  Timor
//
//  Created by houjihu on 2020/5/25.
//

#import <OPFoundation/BDPBaseJSONModel.h>
#import <OPFoundation/BDPModuleEngineType.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDPPackageCardConfigModel;

/// 单个卡片配置模型
@interface BDPPackageCardConfigModel : BDPBaseJSONModel

@property (nonatomic, copy) NSString *cardID;
@property (nonatomic, copy) NSString *entry;
@property (nonatomic, copy) NSString *version;

@end

/** 代码包内的工程配置模型，目前仅用于卡片类型
 详见：https://bytedance.feishu.cn/docs/doccnzmSQDD7DB3ut7ubI0mGGuw#Axjt8e
 project.config.json 文件结构示例：
  {
      "appid": "cli_9e8b73cd563f9107",
      "appType": "card",
      "cards": [
              {
              "entry": "card/card1.js",
              "cardID": "card_9e3959fbc3f8900e",
              "version": "1.0.0"
          },
              {
              "entry": "card/card2.js",
              "cardID": "card_9e3959fbc3f8900f",
              "version": "1.0.0"
          }
              ]
  }
 */
@interface BDPPackageCardProjectConfigModel : JSONModel

// 注意，内部有 @selector 调用，不要随意改名字或删除
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, assign) BDPType appType;
// 注意，内部有 @selector 调用，不要随意改名字或删除
@property (nonatomic, strong) NSArray<BDPPackageCardConfigModel> *cardConfigs;

@end

NS_ASSUME_NONNULL_END

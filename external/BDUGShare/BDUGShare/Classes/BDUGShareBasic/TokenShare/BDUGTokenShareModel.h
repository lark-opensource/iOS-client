//
//  BDUGTokenShareModel.h
//  BDUGShare
//
//  Created by zengzhihui on 2018/5/31.
//

#import <Foundation/Foundation.h>
#import "BDUGTokenShare.h"

NS_ASSUME_NONNULL_BEGIN

@class TTImageInfosModel;
@interface BDUGTokenShareAnalysisResultModel : NSObject

@property (nonatomic, copy, nullable) NSString *panelId;

@property(nonatomic, copy, readonly, nullable) NSDictionary *originDict;//服务返回的原始数据
@property(nonatomic, copy, readonly, nullable) NSDictionary *logInfo;//服务返回的所需要的打点信息
@property(nonatomic, copy, readonly, nullable) NSString *title;
@property(nonatomic, copy, readonly, nullable) NSString *token;
@property(nonatomic, copy, readonly, nullable) NSString *openUrl;//回流短链
@property(nonatomic, assign, readonly) NSInteger mediaType;//内容类型
@property(nonatomic, copy, readonly, nullable) NSString *shareUserName;
@property(nonatomic, copy, readonly, nullable) NSString *shareUserID;
@property(nonatomic, copy, readonly, nullable) NSString *shareUserOpenUrl;
@property(nonatomic, copy, readonly, nullable) NSArray<TTImageInfosModel *> *pics;
@property(nonatomic, assign, readonly) NSInteger picCount;
@property(nonatomic, assign, readonly) NSInteger videoDuration;//秒

@property (nonatomic, copy, readonly, nullable) NSString *clientExtra;
@property (nonatomic, copy, readonly, nullable) NSString *buttonText;

@property(nonatomic, copy) NSString *groupTypeForEvent;

- (instancetype)initWithDict:(NSDictionary *)dict;
#ifdef DEBUG
- (instancetype)initTestModel;
- (instancetype)initTestPhotosModel;
#endif
@end

NS_ASSUME_NONNULL_END

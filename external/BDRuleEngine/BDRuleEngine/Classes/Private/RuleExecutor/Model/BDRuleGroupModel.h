//
//  BDRuleGroupModel.h
//  BDRuleEngine
//
//  Created by WangKun on 2021/11/25.
//

#import <Foundation/Foundation.h>
#import "BDRECommand.h"
#import "BDRuleQuickExecutor.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDRuleModel : NSObject

@property (copy, nonatomic, nullable) NSString *key;
@property (copy, nonatomic, nullable) NSString *title;
@property (copy, nonatomic, nullable) NSDictionary *conf; //返回值
@property (copy, nonatomic, nullable) NSString *cel; // 表达式
@property (strong, nonatomic, nullable) NSArray<BDRECommand *> *commands; // 指令队列
@property (strong, nonatomic, nullable) NSArray<BDRuleModel *> *children; // 子规则组
@property (strong, nonatomic, nullable) BDRuleQuickExecutor *qucikExecutor; // 快速执行器

- (instancetype)initWithDictionary:(NSDictionary *)dict key:(NSString *)key;

- (void)loadCommandsAndEnableExecutor:(BOOL)enable;

- (NSDictionary *)jsonFormat;

@end

@interface BDRuleGroupModel : NSObject

@property (strong, nonatomic, nonnull) NSArray<NSDictionary *> *rawJsonArray;

@property (strong, nonatomic, nonnull) NSArray<BDRuleModel *> *rules;

@property (copy, nonatomic, nonnull) NSString *name;
/// rules 表达式包含的业务参数名称列表 可为空
@property (strong, nonatomic, nullable) NSArray<NSString *> *keys;

- (instancetype)initWithJsonArray:(NSArray *)jsonArray
                             name:(NSString *)name
                             keys:(nullable NSArray *)keys;

- (instancetype)initWithArray:(NSArray<BDRuleModel *> *)array
                         name:(NSString *)name;

- (instancetype)initWithMergeRuleGroupModelArray:(NSArray<BDRuleGroupModel *> *)array;

- (NSDictionary *)jsonFormat;

@end

NS_ASSUME_NONNULL_END

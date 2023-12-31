//
//  IESPrefetchAPITemplate.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/2.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchConfigTemplate.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, IESPrefetchAPIParamsType) {
    IESPrefetchAPIParamStatic,
    IESPrefetchAPIParamQuery,
    IESPrefetchAPIParamVariable,
    IESPrefetchAPIParamPathVariable,
    IESPrefetchAPIParamNested,
};

typedef NS_ENUM(NSUInteger, IESPrefetchAPIParamsDataType) {
    IESPrefetchDataTypeString,
    IESPrefetchDataTypeNumber,
    IESPrefetchDataTypeBool,
    IESPrefetchDataTypeParamsNode,
};

FOUNDATION_EXPORT NSString *paramsTypeDescription(IESPrefetchAPIParamsType paramsType);

/// 代表API配置中的参数节点
@interface IESPrefetchAPIParamsNode : NSObject

@property (nonatomic, copy) NSString *paramName;
@property (nonatomic, copy) id valueFrom;
@property (nonatomic, assign) IESPrefetchAPIParamsType type;
@property (nonatomic, assign) IESPrefetchAPIParamsDataType dataType;

@end

/// 代表配置中的API节点
@interface IESPrefetchAPINode : NSObject

@property (nonatomic, copy) NSString *apiName;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *method;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *headers;
@property (nonatomic, copy) NSDictionary<NSString *, IESPrefetchAPIParamsNode *> *params;
@property (nonatomic, copy) NSDictionary<NSString *, IESPrefetchAPIParamsNode *> *data;
@property (nonatomic, assign) BOOL needCommonParams;
@property (nonatomic, assign) int64_t expire;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *extras;

@end

@interface IESPrefetchAPITemplate : NSObject<IESPrefetchConfigTemplate>
/// 添加API节点
- (void)addAPINode:(IESPrefetchAPINode *)node;
/// 根据API节点名称获取节点
- (IESPrefetchAPINode *)apiNodeForName:(NSString *)name;
/// 节点数量
- (NSUInteger)countOfNodes;

@end

NS_ASSUME_NONNULL_END

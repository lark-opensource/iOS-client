//
//  HTSVideoDataConverterDefaultHolder.h
//  NLEPlatform
//
//  Created by bytedance on 2021/1/11.
//

#import <Foundation/Foundation.h>

typedef NSObject * (^StringToNSObjectBlock)(NSString *);

// 这个类预期是用来处理废弃或全量很久的某些属性，例如isNewTimeMachine等
// 存储时候，检查dict[key]当中的属性是否和self.defaultValues当中属性相同
// 恢复时期，如果node.Extra[key]当中没有属性，则从self.defaultValues获取
@interface HTSVideoDataConverterDefaultHolder : NSObject

@property (nonatomic, assign) BOOL isUseDefault;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSObject *> *defaultValues;
@property (nonatomic, weak) NSDictionary<NSString *, NSObject *> *videodataDict;

// 从dict当中取出dict[key]，转化为string放入NLENode的Extra[nodeKey]当中
// 如果isUseDefault == YES，则断言NSAssert([self.defaultValues[key] isEqual:dictValue])
- (void) setExtraToNLENode:(NLENode_OC *)node nodeKey:(NSString *)nodeKey;
- (void) setExtraToNLENode:(NSObject *)value node:(NLENode_OC *)node nodeKey:(NSString *)nodeKey;


- (NSNumber *)getExtraFromNLENode_int:(NLENode_OC *)node nodeKey:(NSString *)nodeKey;
- (NSNumber *)getExtraFromNLENode_float:(NLENode_OC *)node nodeKey:(NSString *)nodeKey;
- (NSDictionary *)getExtraFromNLENode_Dictionary:(NLENode_OC *)node nodeKey:(NSString *)nodeKey;

// 从node当中取出Extra[nodeKey]
// 如果没有Extra[nodeKey]且isUseDefault == YES，则设定为default值
- (NSObject *)getExtraFromNLENode:(NLENode_OC *)node nodeKey:(NSString *)nodeKey;
- (NSObject *)getExtraFromNLENode:(NLENode_OC *)node nodeKey:(NSString *)nodeKey convertBlock:(StringToNSObjectBlock)convertBlock;

- (void) serializeExtra:(NLENode_OC *)node;
- (void) deserializeExtra:(NLENode_OC *)node;

+ (NSString *)douyinKey;

@end


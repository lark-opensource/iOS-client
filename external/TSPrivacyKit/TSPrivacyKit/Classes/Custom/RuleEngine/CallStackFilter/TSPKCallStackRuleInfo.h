//
//  TSPKCallStackRuleInfo.h
//  BDAlogProtocol
//
//  Created by bytedance on 2022/7/21.
//

#import <Foundation/Foundation.h>

@interface TSPKCallStackRuleInfo : NSObject

@property (nonatomic, copy, nullable) NSString *className;
@property (nonatomic, copy, nullable) NSString *selName;
@property (nonatomic, assign) BOOL isMeta;

@property (nonatomic, copy, nullable) NSString *binaryName;
@property (nonatomic, assign) NSUInteger slide;
@property (nonatomic, assign) NSUInteger start;
@property (nonatomic, assign) NSUInteger end;

- (nullable instancetype)initWithDictionary:(nullable NSDictionary *)dict;

- (BOOL)isCompleted;

- (nonnull NSString *)uniqueKey;

- (NSComparisonResult)compare:(nullable TSPKCallStackRuleInfo *)info;

@end

@interface TPSKCallStackDataTypeInfo : NSObject

@property (nonatomic, assign) BOOL isAllow;

@property (nonatomic, strong, nullable) NSMutableArray <TSPKCallStackRuleInfo *> *rules;

@end

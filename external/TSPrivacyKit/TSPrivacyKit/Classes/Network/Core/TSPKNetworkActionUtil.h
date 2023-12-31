//
//  TSPKNetworkActionUtil.h
//  TSPrivacyKit
//
//  Created by admin on 2022/8/24.
//

#import <Foundation/Foundation.h>
@protocol TSPKCommonRequestProtocol;

typedef NS_ENUM(NSUInteger, TSPKNetworkActionType) {
    TSPKNetworkActionTypeNone,
    TSPKNetworkActionTypeFuse,
    TSPKNetworkActionTypeModify,
    TSPKNetworkActionTypeReport
};

@interface TSPKNetworkOperatePair : NSObject

@property (nonatomic, copy, nullable) NSString *originKey;
@property (nonatomic, copy, nullable) NSString *changedKey;

- (NSString *_Nullable)format2String;

@end

@interface TSPKNetworkOperateHistory : NSObject

@property (nonatomic, copy, nullable) NSString *operate;
@property (nonatomic, copy, nullable) NSString *target;
@property (nonatomic, strong, nullable) NSMutableArray<TSPKNetworkOperatePair *> *pairs;

- (NSString *_Nullable)format2String;

@end

@interface TSPKNetworkActionUtil : NSObject

+ (NSInteger)merge:(NSDictionary *_Nullable)source store:(NSMutableDictionary *_Nullable)store;
+ (NSArray<TSPKNetworkOperateHistory *> *_Nullable)doActions:(NSDictionary *_Nullable)actions request:(id<TSPKCommonRequestProtocol> _Nullable)request actionType:(NSInteger)actionType;

@end

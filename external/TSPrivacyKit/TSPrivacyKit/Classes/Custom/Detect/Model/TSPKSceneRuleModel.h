//
//  TSPKSceneRuleModel.h
//  TSPrivacyKit
//
//  Created by PengYan on 2020/7/16.
//

#import <Foundation/Foundation.h>


@interface TSPKSceneRuleModel : NSObject

@property (nonatomic) NSInteger ruleId;
@property (nonatomic, copy, nullable) NSString *ruleName;
@property (nonatomic, copy, nullable) NSString *type;
@property (nonatomic, copy, nullable) NSDictionary *params;
@property (nonatomic, copy, nullable) NSSet *ruleIgnoreCondition;

+ (instancetype _Nullable)createWithDictionary:(NSDictionary *_Nullable)dict;

@end


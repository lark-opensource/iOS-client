//
//  HMDStoreCondition.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/17.
//

typedef NS_ENUM(NSInteger, HMDConditionJudgeType)
{
    HMDConditionJudgeNone,
    HMDConditionJudgeLess,
    HMDConditionJudgeEqual,
    HMDConditionJudgeGreater,
    HMDConditionJudgeContain,
    HMDConditionJudgeIsNULL,
};

@interface HMDStoreCondition : NSObject

@property (nonatomic, assign) HMDConditionJudgeType judgeType;
@property (nonatomic, strong) NSString * _Nonnull key;
@property (nonatomic, assign) double threshold;
@property (nonatomic, copy, nullable) NSString * stringValue;

@end

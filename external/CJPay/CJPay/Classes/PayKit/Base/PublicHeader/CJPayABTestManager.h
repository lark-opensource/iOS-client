//
//  CJPayABTestManager.h
//  Pods
//
//  Created by 孟源 on 2022/5/19.
//

#import <Foundation/Foundation.h>
#import "CJPayABTestKeyDefine.h"

#define CJPayABTest [CJPayABTestManager sharedInstance]
NS_ASSUME_NONNULL_BEGIN

@interface CJPayABTestManager : NSObject
@property (nonatomic, strong) NSMutableArray<NSString *> *libraKeyArray;

+ (instancetype)sharedInstance;

- (NSDictionary *)getExperimentKeyValueDic;
// 获得试验值
- (NSString *)getABTestValWithKey:(NSString *)key; // 默认为曝光 withExposure取yes
- (NSString *)getABTestValWithKey:(NSString *)key exposure:(BOOL)exposure;
@end

NS_ASSUME_NONNULL_END

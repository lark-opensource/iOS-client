//
//	HMDInfo+AutoTestInfo.h
// 	Heimdallr
// 	
// 	Created by Hayden on 2020/2/16. 
//

#import "HMDInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDInfo (AutoTestInfo)

@property (nonatomic, copy, readonly) NSDictionary *automationTestInfoDic;
@property (nonatomic, assign, readonly, class) BOOL isBytest;
@property (nonatomic, copy, readonly, class) NSDictionary *bytestFilter; // 自动化测试的过滤字段

@end

NS_ASSUME_NONNULL_END

//
//  BDPTrackerParamInfo.h
//  Timor
//
//  Created by 维旭光 on 2019/5/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPTrackerParamInfo : NSObject

// 埋点通用参数
@property (nonatomic, copy) NSDictionary *commonParams;

// mp_enter_page使用，记录小程序的上个页面
@property (nonatomic, nullable, copy) NSString *lastPath;

@end

NS_ASSUME_NONNULL_END

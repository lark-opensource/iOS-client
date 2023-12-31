//
//  BDPSearchEventReporter.h
//  Timor
//
//  Created by 维旭光 on 2019/8/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPSearchEventReporter : NSObject

+ (instancetype)reporterWithCommonParams:(NSDictionary *)commonParams launchFrom:(NSString *)launchFrom isApp:(BOOL)isApp;

// loadSuccess  1|0|2 成功|失败|加载中
- (void)eventLoadDetail:(NSUInteger)loadSuccess;

- (void)evnetWarmBootLoadDetail;

- (void)eventStayPage;

@end

NS_ASSUME_NONNULL_END

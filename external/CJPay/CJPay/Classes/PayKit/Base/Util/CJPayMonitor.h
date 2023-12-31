//
//  CJPayMonitor.h
//  CJPay
//
//  Created by 王新华 on 8/25/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define CJMonitor [CJPayMonitor shared]

@interface CJPayMonitor : NSObject

+ (instancetype)shared;
- (void)trackServiceAllInOne:(NSString *)name
                      metric:(NSDictionary *)metric
                    category:(NSDictionary *)category
                       extra:(NSDictionary *)extra;
- (void)trackService:(NSString *)name category:(NSDictionary *)category extra:(NSDictionary *)extra;
- (void)trackService:(NSString *)name extra:(NSDictionary *)extra;
- (void)trackService:(NSString *)name metric:(NSDictionary *)metric category:(NSDictionary *)category extra:(NSDictionary *)extra;

@end

NS_ASSUME_NONNULL_END

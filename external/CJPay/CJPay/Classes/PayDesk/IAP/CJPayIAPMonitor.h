//
//  CJPayIAPMonitor.h
//  Pods
//
//  Created by 王新华 on 2021/2/18.
//

#import <Foundation/Foundation.h>
#import "CJPayMonitorHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayIAPMonitor : NSObject

@property (nonatomic, copy) NSString *businessIdentify;
@property (nonatomic, assign) BOOL useProductCache;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *iapType;

- (void)monitor:(CJPayIAPStage)stage category:(NSDictionary *)category extra:(NSDictionary *)extra;

- (void)monitorService:(NSString *)service category:(NSDictionary *)category extra:(NSDictionary *)extra;

@end

NS_ASSUME_NONNULL_END

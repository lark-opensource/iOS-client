//
//  CJPayOfflineService.h
//  Pods
//
//  Created by 易培淮 on 2021/5/6.
//

#ifndef CJPayOfflineService_h
#define CJPayOfflineService_h




NS_ASSUME_NONNULL_BEGIN

@protocol CJPayOfflineService <NSObject>

- (void)i_registerOffline:(NSString*)appId;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayOfflineService_h */

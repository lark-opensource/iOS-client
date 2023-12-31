//
//  CJPaySyncChannelsConfigModel.h
//  Aweme
//
//  Created by ByteDance on 2023/8/22.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySyncChannelsConfigModel : JSONModel

@property (nonatomic, assign) CGFloat initDelayTime;
@property (nonatomic, assign) BOOL disableThrottle;

@property (nonatomic, copy) NSDictionary<NSString *, NSArray<NSString *> *> *sdkInitChannels;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<NSString *> *> *selectNotifyChannels;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<NSString *> *> *selectHomePageChannels;

@end

NS_ASSUME_NONNULL_END

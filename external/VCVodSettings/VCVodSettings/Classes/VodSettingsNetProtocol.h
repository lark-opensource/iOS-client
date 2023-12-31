//
//  VCVodSettingsNetProtocol.h
//  VCVodSettings
//
//  Created by huangqing.yangtze on 2021/5/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VodSettingsNetProtocol <NSObject>

- (void)start:(NSString *)urlString
      queries:(NSDictionary<NSString *, NSString *> *)queries
       result:(void(^)(NSError * _Nullable error, _Nullable id jsonObject)) result;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END

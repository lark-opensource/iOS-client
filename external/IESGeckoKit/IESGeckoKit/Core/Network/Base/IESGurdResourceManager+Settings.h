//
//  IESGurdResourceManager+Settings.h
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by liuhaitian on 2021/4/22.
//

#import "IESGeckoResourceManager.h"
#import "IESGurdSettingsRequest.h"
#import "IESGurdSettingsResponse.h"
#import "IESGurdSettingsResponseExtra.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^IESGurdSettingsCompletion)(IESGurdSettingsStatus settingsStatus, IESGurdSettingsResponse *_Nullable response, IESGurdSettingsResponseExtra *_Nullable extra);

@interface IESGurdResourceManager (Settings)

+ (void)fetchSettingsWithRequest:(IESGurdSettingsRequest *)request
                      completion:(IESGurdSettingsCompletion)completion;

@end

NS_ASSUME_NONNULL_END


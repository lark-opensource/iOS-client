//
//  BDPLaunchAppConfig.h
//  Timor
//
//  Created by 张朝杰 on 2019/8/29.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPLaunchAppConfig : JSONModel

@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *androidPackageName;

@end

NS_ASSUME_NONNULL_END

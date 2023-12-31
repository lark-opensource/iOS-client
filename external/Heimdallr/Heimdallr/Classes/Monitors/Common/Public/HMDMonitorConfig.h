//
//  HMDMonitorConfig.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/14.
//

#import "HMDModuleConfig.h"

@interface HMDMonitorConfig : HMDModuleConfig

@property (nonatomic, assign)float flushInterval;
@property (nonatomic, assign)float flushCount;
@property (nonatomic, assign)float refreshInterval;
@property (nonatomic, strong, nullable) NSDictionary *customEnableUpload;

// open current module by special scene config
@property (nonatomic, assign) BOOL customOpenEnabled;
@property (nonatomic, strong, nullable) NSDictionary *customOpenScene;

@end


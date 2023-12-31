//
//  HMDHermasUploadSetting.h
//  Heimdallr
//
//  Created by liuhan on 2022/5/19.
//

#import "HMDCommonAPISetting.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDHermasUploadSetting : HMDCommonAPISetting

@property (nonatomic, assign) NSUInteger limitUploadInterval;

@property (nonatomic, assign) NSInteger limitUploadSize;

@property (nonatomic, assign) NSInteger maxLogNumber;

@property (nonatomic, assign) CGFloat maxFileSize;

@property (nonatomic, assign) NSInteger maxUploadSize;

@property (nonatomic, assign) NSInteger uploadInterval;

@property (nonatomic, assign) BOOL enableRefactorOpen;

@property (nonatomic, assign) NSInteger recordThreadShareMask;

@end

NS_ASSUME_NONNULL_END

//
//  ACCRecordMode.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/11/26.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCModuleService.h>
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import "AWESwitchModeSingleTabConfig.h"
typedef NS_ENUM(NSInteger, AWEVideoRecordButtonType);

NS_ASSUME_NONNULL_BEGIN

typedef BOOL(^ACCRecordModeShouldShowBlock)(void);

@interface ACCRecordMode : NSObject

@property (nonatomic, assign) NSInteger modeId;

// whether should start video capture
@property (nonatomic, assign) BOOL isVideo;

// whether is photo mode, this mode will allow flash
@property (nonatomic, assign) BOOL isPhoto;

/* whether is the video type
 Mixtype can take several segments and has a total duraion upper limit.
 */
@property (nonatomic, assign) BOOL isMixHoldTapVideo;

// whether this mode will be direct to the next step after tap the record
@property (nonatomic, assign) BOOL autoComplete;

// track name for report
@property (nonatomic, copy) NSString *trackIdentifier;

@property (nonatomic, assign) ACCRecordLengthMode lengthMode;

@property (nonatomic, assign) AWEVideoRecordButtonType buttonType;

@property (nonatomic, assign) ACCServerRecordMode serverMode;

@property (nonatomic, assign) BOOL isExclusive; // whether only have one mode

@property (nonatomic, assign) BOOL isInitial; // whether is the initial selected mode, if exclusive will be initial automatically.

@property (nonatomic, strong) AWESwitchModeSingleTabConfig *tabConfig;

@property (nonatomic, copy) ACCRecordModeShouldShowBlock shouldShowBlock;

@end

NS_ASSUME_NONNULL_END

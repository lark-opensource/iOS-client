//
//  TSPrivacyKitConstants.h
//  TSPrivacyKit
//
//  Created by PengYan on 2020/8/4.
//

#import <Foundation/Foundation.h>


#pragma mark - pipeline types
// album
extern NSString *_Nullable const TSPKPipelineAlbumOfPHPhotoLibrary;
extern NSString *_Nullable const TSPKPipelineAlbumOfPHPickerViewController;
extern NSString *_Nullable const TSPKPipelineAlbumOfPHImageManager;
extern NSString *_Nullable const TSPKPipelineAlbumOfALAssetsLibrary;
extern NSString *_Nullable const TSPKPipelineAlbumOfPHCollectionList;
extern NSString *_Nullable const TSPKPipelineAlbumOfPHAsset;
extern NSString *_Nullable const TSPKPipelineAlbumOfPHAssetCollection;
extern NSString *_Nullable const TSPKPipelineAlbumOfPHAssetChangeRequest;
extern NSString *_Nullable const TSPKPipelineAlbumOfUIImagePickerController;
// audio
extern NSString *_Nullable const TSPKPipelineAudioOfAudioOutput;
extern NSString *_Nullable const TSPKPipelineAudioOfAUGraph;
extern NSString *_Nullable const TSPKPipelineAudioOfAudioQueue;
extern NSString *_Nullable const TSPKPipelineAudioOfAVAudioRecorder;
extern NSString *_Nullable const TSPKPipelineAudioOfAVAudioSession;
extern NSString *_Nullable const TSPKPipelineAudioOfAVCaptureDevice;
// calendar
extern NSString *_Nullable const TSPKPipelineCalendarOfEKEventStore;
extern NSString *_Nullable const TSPKPipelineCalendarOfEKEvent;
// call center
extern NSString *_Nullable const TSPKPipelineCallCenterOfCTCallCenter;
// clipboard
extern NSString *_Nullable const TSPKPipelineClipboardOfUIPasteboard;
// contact
extern NSString *_Nullable const TSPKPipelineContactOfAddressBook;
extern NSString *_Nullable const TSPKPipelineContactOfCNContactStore;
extern NSString *_Nullable const TSPKPipelineContactOfCNContact;
// local_network
extern NSString *_Nullable const TSPKPipelineLocalNetworkOfCFHost;
extern NSString *_Nullable const TSPKPipelineLocalNetworkOfDnsSd;
extern NSString *_Nullable const TSPKPipelineLocalNetworkOfNetdb;
// health
extern NSString *_Nullable const TSPKPipelineHealthOfHKHealthStore;
// idfa
extern NSString *_Nullable const TSPKPipelineIDFAOfASIdentifierManager;
extern NSString *_Nullable const TSPKPipelineIDFAOfATTrackingManager;
// idfv
extern NSString *_Nullable const TSPKPipelineIDFVOfUIDevice;
// ip
extern NSString *_Nullable const TSPKPipelineIPOfIfAddrs;
// location
extern NSString *_Nullable const TSPKPipelineLocationOfCLLocationManager;
extern NSString *_Nullable const TSPKPipelineLocationOfCLLocationManagerReqAlwaysAuth;
// LockID
extern NSString *_Nullable const TSPKPipelineLockIDOfLAContext;
// media
extern NSString *_Nullable const TSPKPipelineMediaOfMPMediaQuery;
extern NSString *_Nullable const TSPKPipelineMediaOfMPMediaLibrary;
// message
extern NSString *_Nullable const TSPKPipelineMessageOfMFMessageComposeViewController;
// motion
extern NSString *_Nullable const TSPKPipelineMotionOfCMMotionActivityManager;
extern NSString *_Nullable const TSPKPipelineMotionOfCMPedometer;
extern NSString *_Nullable const TSPKPipelineMotionOfCMAltimeter;
extern NSString *_Nullable const TSPKPipelineMotionOfCMMotionManager;
extern NSString *_Nullable const TSPKPipelineMotionOfCLLocationManager;
extern NSString *_Nullable const TSPKPipelineMotionOfUIDevice;
// network
extern NSString *_Nullable const TSPKPipelineNetworkOfCLGeocoder;
extern NSString *_Nullable const TSPKPipelineNetworkOfCTCarrier;
extern NSString *_Nullable const TSPKPipelineNetworkOfCTTelephonyNetworkInfo;
extern NSString *_Nullable const TSPKPipelineNetworkOfNSLocale;
// push
extern NSString *_Nullable const TSPKPipelinePushOfUNUserNotificationCenter;
// screen recorder
extern NSString *_Nullable const TSPKPipelineScreenRecorderOfRPScreenRecorder;
extern NSString *_Nullable const TSPKPipelineScreenRecorderOfRPSystemBroadcastPickerView;
// snapshot
extern NSString *_Nullable const TSPKPipelineSnapShotOfUIGraphics;
extern NSString *_Nullable const TSPKPipelineSnapShotOfUIView;
// video
extern NSString *_Nullable const TSPKPipelineVideoOfAVCaptureStillImageOutput;
extern NSString *_Nullable const TSPKPipelineVideoOfAVCaptureDevice;
extern NSString *_Nullable const TSPKPipelineVideoOfAVCaptureSession;
extern NSString *_Nullable const TSPKPipelineVideoOfARSession;
// wifi
extern NSString *_Nullable const TSPKPipelineWifiOfNEHotspotNetwork;
extern NSString *_Nullable const TSPKPipelineWifiOfCaptiveNetwork;
// ciad
extern NSString *_Nullable const TSPKPipelineCIADOfBDInstall;
// openudid
extern NSString *_Nullable const TSPKPipelineOpenUDIDOfOpenUDID;
// application
extern NSString *_Nullable const TSPKPipelineApplicationOfUIApplication;
// user_input
extern NSString *_Nullable const TSPKPipelineUserInputOfUITextField;
extern NSString *_Nullable const TSPKPipelineUserInputOfUITextView;
extern NSString *_Nullable const TSPKPipelineUserInputOfYYTextView;

// data type
extern NSString *_Nullable const TSPKDataTypeAudio;
extern NSString *_Nullable const TSPKDataTypeVideo;
extern NSString *_Nullable const TSPKDataTypeLocalNetwork;
extern NSString *_Nullable const TSPKDataTypeIDFA;
extern NSString *_Nullable const TSPKDataTypeIDFV;
extern NSString *_Nullable const TSPKDataTypeCIAD;
extern NSString *_Nullable const TSPKDataTypeOpenUDID;
extern NSString *_Nullable const TSPKDataTypeIP;
extern NSString *_Nullable const TSPKDataTypeClipboard;
extern NSString *_Nullable const TSPKDataTypeLocation;
extern NSString *_Nullable const TSPKDataTypeAlbum;
extern NSString *_Nullable const TSPKDataTypeContact;
extern NSString *_Nullable const TSPKDataTypeWifi;
extern NSString *_Nullable const TSPKDataTypeScreenRecord;
extern NSString *_Nullable const TSPKDataTypeCalendar;
extern NSString *_Nullable const TSPKDataTypeCallCenter;
extern NSString *_Nullable const TSPKDataTypeMotion;
extern NSString *_Nullable const TSPKDataTypeMedia;
extern NSString *_Nullable const TSPKDataTypeLockId;
extern NSString *_Nullable const TSPKDataTypeHealth;
extern NSString *_Nullable const TSPKDataTypeSnapshot;
extern NSString *_Nullable const TSPKDataTypeMessage;
extern NSString *_Nullable const TSPKDataTypeNetwork;
extern NSString *_Nullable const TSPKDataTypeApplication;
extern NSString *_Nullable const TSPKDataTypePush;
extern NSString *_Nullable const TSPKDataTypeUserInput;

//config
extern NSString *_Nullable const TSPKConfigDidUpdateKey;

//attachment
extern NSString *_Nullable const TSPKReleaseCheckAttachmentKey;

//bpea
extern NSString *_Nullable const TSPKBPEAInfoKey;

//notification
extern NSString *_Nullable const TSPKNotificationSensitiveAPIStatistics;
extern NSString *_Nullable const TSPKNetworkChangedNotification;

//rule
extern NSString *_Nullable const TSPKRuleIdKey;
extern NSString *_Nullable const TSPKRuleNameKey;
extern NSString *_Nullable const TSPKRuleTypeKey;
extern NSString *_Nullable const TSPKRuleParamsKey;
extern NSString *_Nullable const TSPKRuleIgnoreConditionKey;

extern NSString *_Nullable const TSPKRuleTypeAdvanceAppStatusTrigger;
extern NSString *_Nullable const TSPKRuleTypePageStatusTrigger;
extern NSString *_Nullable const TSPKCrossPlatformCallingType;

extern NSString *_Nullable const TSPKRuleTypeMethodTrigger;

extern NSString *_Nullable const TSPKErrorDomain;

// Rule Engine Key
extern NSString *_Nullable const TSPKRuleEngineAction;

// common key
extern NSString *_Nullable const TSPKMonitorSceneKey;
extern NSString *_Nullable const TSPKPermissionTypeKey;
extern NSString *_Nullable const TSPKEventUnixTimeStampKey;
extern NSString *_Nullable const TSPKEventTimeStampKey;

extern NSString *_Nullable const TSPKCustomSceneCheckKey;
extern NSString *_Nullable const TSPKPairDelayClose;
extern NSString *_Nullable const TSPKCustomAnchor;

// log tag
extern NSString *_Nullable const TSPKLogCommonTag;
extern NSString *_Nullable const TSPKLogCheckTag;
extern NSString *_Nullable const TSPKLogCustomAnchorCheckTag;

// view life cycle
extern NSString *_Nullable const TSPKViewDidAppear;
extern NSString *_Nullable const TSPKViewDidDisappear;
extern NSString *_Nullable const TSPKViewWillAppear;
extern NSString *_Nullable const TSPKViewWillDisappear;
extern NSString *_Nullable const TSPKViewDealloc;
extern NSString *_Nullable const TSPKPageNameKey;
extern NSString *_Nullable const TSPKViewDidLoad;

extern NSString *_Nullable const TSPKMethodEndKey;
extern NSString *_Nullable const TSPKMethodBinaryKey;

extern NSString *_Nullable const TSPKRuleEngineSpaceALL;
extern NSString *_Nullable const TSPKRuleEngineSpaceGuard;
extern NSString *_Nullable const TSPKRuleEngineSpaceGuardFuse;
extern NSString *_Nullable const TSPKRuleEngineSpacePolicyDecision;

extern NSString *_Nullable const TSPKWarningTypeUnReleaseCheck;
extern NSString *_Nullable const TSPKWarningTypeDelayReleaseCheck;

extern NSString *_Nullable const TSPKPolicyLocationRegionLimit;

extern NSString *_Nullable const TSPKNetworkLogCommon;

// life cycle
extern NSString *_Nullable const TSPKAppWillEnterForegroundNotificationKey;
extern NSString *_Nullable const TSPKAppDidEnterBackgroundNotificationKey;
extern NSString *_Nullable const TSPKAppWillResignActiveNotificationKey;
extern NSString *_Nullable const TSPKAppDidBecomeActiveNotificationKey;
extern NSString *_Nullable const TSPKAppDidReceiveMemoryWarningNotificationKey;
extern NSString *_Nullable const TSPKAppWillTerminateNotificationKey;

extern NSString *_Nullable const TSPKPolicyDecisionSourceGuard;

extern NSString *_Nullable const TSPKAPISubTypeKey;

typedef NSSet *_Nullable (^TSPKFetchDetectContextBlock)(void);

typedef NS_ENUM(NSUInteger, TSPKDetectorType) {
    TSPKDetectorTypeFilter,
    TSPKDetectorTypeReleaseCheck
};

typedef NS_ENUM(NSUInteger, TSPKActionLevel) {
    TSPKActionLevelNone,
    TSPKActionLevelNormal,
    TSPKActionLevelBadCase,
    TSPKActionLevelDowngrade,
    TSPKActionLevelAlogReport
};

typedef NS_ENUM(NSUInteger, TSPKStoreType) {
    TSPKStoreTypeNone,
    TSPKStoreTypeRelationObjectCache
};

typedef NS_ENUM(NSUInteger, TSPKError) {
    TSPKErrorRuleDowngrade = 1,
    TSPKErrorPluginDowngrade = 2
};

typedef NS_ENUM(NSUInteger, CLLAccuracy) {
    CLLAccuracyBestForNavigation = 1,
    CLLAccuracyBest = 2,
    CLLAccuracyNearestTenMeters = 3,
    CLLAccuracyHundredMeters = 4,
    CLLAccuracyKilometer = 5,
    CLLAccuracyThreeKilometers = 6,
    CLLAccuracyReduced = 7
};

typedef NS_ENUM(NSUInteger, TSPKNetworkStatus) {
    TSPKNetworkStatusNotReachable = 0,
    TSPKNetworkStatusReachableViaWiFi,
    TSPKNetworkStatusReachableViaWWAN,
};

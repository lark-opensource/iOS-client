//
//  TSPrivacyKitConstants.m
//  TSPrivacyKit
//
//  Created by PengYan on 2020/8/4.
//

#import "TSPrivacyKitConstants.h"

#pragma mark - pipeline types
// album
NSString * const TSPKPipelineAlbumOfPHPhotoLibrary = @"AlbumOfPHPhotoLibrary";
NSString * const TSPKPipelineAlbumOfPHPickerViewController = @"AlbumOfPHPickerViewController";
NSString * const TSPKPipelineAlbumOfPHImageManager = @"AlbumOfPHImageManager";
NSString * const TSPKPipelineAlbumOfALAssetsLibrary = @"AlbumOfALAssetsLibrary";
NSString * const TSPKPipelineAlbumOfPHCollectionList = @"AlbumOfPHCollectionList";
NSString * const TSPKPipelineAlbumOfPHAsset = @"AlbumOfPHAsset";
NSString * const TSPKPipelineAlbumOfPHAssetCollection = @"AlbumOfPHAssetCollection";
NSString * const TSPKPipelineAlbumOfPHAssetChangeRequest = @"AlbumOfPHAssetChangeRequest";
NSString * const TSPKPipelineAlbumOfUIImagePickerController = @"AlbumOfUIImagePickerController";
// audio
NSString * const TSPKPipelineAudioOfAudioOutput = @"AudioOfAudioOutput";
NSString * const TSPKPipelineAudioOfAUGraph = @"AudioOfAUGraph";
NSString * const TSPKPipelineAudioOfAudioQueue = @"AudioOfAudioQueue";
NSString * const TSPKPipelineAudioOfAVAudioRecorder = @"AudioOfAVAudioRecorder";
NSString * const TSPKPipelineAudioOfAVAudioSession = @"AudioOfAVAudioSession";
NSString * const TSPKPipelineAudioOfAVCaptureDevice = @"AudioOfAVCaptureDevice";
// calendar
NSString * const TSPKPipelineCalendarOfEKEventStore = @"CalendarOfEKEventStore";
NSString * const TSPKPipelineCalendarOfEKEvent = @"CalendarOfEKEvent";
// call center
NSString * const TSPKPipelineCallCenterOfCTCallCenter = @"CallCenterOfCTCallCenter";
// clipboard
NSString * const TSPKPipelineClipboardOfUIPasteboard = @"ClipboardOfUIPasteboard";
// contact
NSString * const TSPKPipelineContactOfAddressBook = @"ContactOfAddressBook";
NSString * const TSPKPipelineContactOfCNContactStore = @"ContactOfCNContactStore";
NSString * const TSPKPipelineContactOfCNContact = @"ContactOfCNContact";
// local_network
NSString * const TSPKPipelineLocalNetworkOfCFHost = @"LocalNetworkOfCFHost";
NSString * const TSPKPipelineLocalNetworkOfDnsSd = @"LocalNetworkOfDnsSd";
NSString * const TSPKPipelineLocalNetworkOfNetdb = @"LocalNetworkOfNetdb";
// health
NSString * const TSPKPipelineHealthOfHKHealthStore = @"HealthOfHKHealthStore";
// idfa
NSString * const TSPKPipelineIDFAOfASIdentifierManager = @"IDFAOfASIdentifierManager";
NSString * const TSPKPipelineIDFAOfATTrackingManager = @"IDFAOfATTrackingManager";
// idfv
NSString * const TSPKPipelineIDFVOfUIDevice = @"IDFVOfUIDevice";
// ip
NSString * const TSPKPipelineIPOfIfAddrs = @"IPOfIfAddrs";
// location
NSString * const TSPKPipelineLocationOfCLLocationManager = @"LocationOfCLLocationManager";
NSString * const TSPKPipelineLocationOfCLLocationManagerReqAlwaysAuth = @"LocationOfCLLocationManagerReqAlwaysAuth";
// LockID
NSString * const TSPKPipelineLockIDOfLAContext = @"LockIDOfLAContext";
// media
NSString * const TSPKPipelineMediaOfMPMediaQuery = @"MediaOfMPMediaQuery";
NSString * const TSPKPipelineMediaOfMPMediaLibrary = @"MediaOfMPMediaLibrary";
// message
NSString * const TSPKPipelineMessageOfMFMessageComposeViewController = @"MessageOfMFMessageComposeViewController";
// motion
NSString * const TSPKPipelineMotionOfCMMotionActivityManager = @"MotionOfCMMotionActivityManager";
NSString * const TSPKPipelineMotionOfCMPedometer = @"MotionOfCMPedometer";
NSString * const TSPKPipelineMotionOfCMAltimeter = @"MotionOfCMAltimeter";
NSString * const TSPKPipelineMotionOfCMMotionManager = @"MotionOfCMMotionManager";
NSString * const TSPKPipelineMotionOfCLLocationManager = @"MotionOfCLLocationManager";
NSString * const TSPKPipelineMotionOfUIDevice = @"MotionOfUIDevice";
// network
NSString * const TSPKPipelineNetworkOfCLGeocoder = @"NetworkOfCLGeocoder";
NSString * const TSPKPipelineNetworkOfCTCarrier = @"NetworkOfCTCarrier";
NSString * const TSPKPipelineNetworkOfCTTelephonyNetworkInfo = @"NetworkOfCTTelephonyNetworkInfo";
NSString * const TSPKPipelineNetworkOfNSLocale = @"NetworkOfNSLocale";
// push
NSString * const TSPKPipelinePushOfUNUserNotificationCenter = @"PushOfUNUserNotificationCenter";
// screen recorder
NSString * const TSPKPipelineScreenRecorderOfRPScreenRecorder = @"ScreenRecorderOfRPScreenRecorder";
NSString * const TSPKPipelineScreenRecorderOfRPSystemBroadcastPickerView = @"ScreenRecorderOfRPSystemBroadcastPickerView";
// snapshot
NSString * const TSPKPipelineSnapShotOfUIGraphics = @"SnapShotOfUIGraphics";
NSString * const TSPKPipelineSnapShotOfUIView = @"SnapShotOfUIView";
// video
NSString * const TSPKPipelineVideoOfAVCaptureStillImageOutput = @"VideoOfAVCaptureStillImageOutput";
NSString * const TSPKPipelineVideoOfAVCaptureDevice = @"VideoOfAVCaptureDevice";
NSString * const TSPKPipelineVideoOfAVCaptureSession = @"VideoOfAVCaptureSession";
NSString * const TSPKPipelineVideoOfARSession = @"VideoOfARSession";
// wifi
NSString * const TSPKPipelineWifiOfNEHotspotNetwork = @"WifiOfNEHotspotNetwork";
NSString * const TSPKPipelineWifiOfCaptiveNetwork = @"WifiOfCaptiveNetwork";
// ciad
NSString * const TSPKPipelineCIADOfBDInstall = @"CIADOfBDInstall";
// openudid
NSString * const TSPKPipelineOpenUDIDOfOpenUDID = @"OpenUDIDOfOpenUDID";
// application
NSString * const TSPKPipelineApplicationOfUIApplication = @"ApplicationOfUIApplication";
// user_input
NSString * const TSPKPipelineUserInputOfUITextField = @"UserInputOfUITextField";
NSString * const TSPKPipelineUserInputOfUITextView = @"UserInputOfUITextView";
NSString * const TSPKPipelineUserInputOfYYTextView = @"UserInputOfYYTextView";

#pragma mark - data types
NSString * const TSPKDataTypeAudio = @"audio";
NSString * const TSPKDataTypeVideo = @"video";
NSString * const TSPKDataTypeIDFA = @"idfa";
NSString * const TSPKDataTypeIDFV = @"idfv";
NSString * const TSPKDataTypeCIAD = @"ciad";
NSString * const TSPKDataTypeOpenUDID = @"openudid";
NSString * const TSPKDataTypeIP = @"ip";
NSString * const TSPKDataTypeClipboard = @"clipboard";
NSString * const TSPKDataTypeLocation = @"location";
NSString * const TSPKDataTypeAlbum = @"album";
NSString * const TSPKDataTypeContact = @"contact";
NSString * const TSPKDataTypeLocalNetwork = @"local_network";
NSString * const TSPKDataTypeWifi = @"wifi";
NSString * const TSPKDataTypeScreenRecord = @"screen_record";
NSString * const TSPKDataTypeCalendar = @"calendar";
NSString * const TSPKDataTypeCallCenter = @"call_center";
NSString * const TSPKDataTypeMotion = @"motion";
NSString * const TSPKDataTypeMedia = @"media";
NSString * const TSPKDataTypeLockId = @"lock_id";
NSString * const TSPKDataTypeHealth = @"health";
NSString * const TSPKDataTypeSnapshot = @"snapshot";
NSString * const TSPKDataTypeMessage = @"message";
NSString * const TSPKDataTypeNetwork = @"network";
NSString * const TSPKDataTypeApplication = @"application";
NSString * const TSPKDataTypePush = @"push";
NSString * const TSPKDataTypeUserInput = @"user_input";

NSString * const  TSPKNotificationSensitiveAPIStatistics = @"TSPKNotificationAPIStatistics";

NSString * const  TSPKNetworkChangedNotification = @"TSPKNetworkChangedNotification";

NSString * const TSPKConfigDidUpdateKey = @"PrivacyKitConfigDidUpdate";

NSString * const TSPKReleaseCheckAttachmentKey = @"ReleaseCheckAttachment";

NSString * const TSPKBPEAInfoKey = @"bpea_info";

NSString * const TSPKRuleIdKey = @"ruleId";
NSString * const TSPKRuleNameKey = @"ruleName";
NSString * const TSPKRuleTypeKey = @"ruleType";
NSString * const TSPKRuleParamsKey = @"ruleParams";
NSString * const TSPKRuleIgnoreConditionKey = @"ruleIgnoreCondition";

NSString * const TSPKRuleTypeAdvanceAppStatusTrigger = @"triggerWhenAppActiveStatusChange_V2";
NSString * const TSPKRuleTypePageStatusTrigger = @"triggerWhenPageStatusChange";

NSString * const TSPKCrossPlatformCallingType = @"jsb";

NSString * const TSPKErrorDomain = @"com.tspk.domain";

NSString * const TSPKMonitorSceneKey = @"monitorScene";
NSString * const TSPKPermissionTypeKey = @"permissionType";
NSString * const TSPKCustomSceneCheckKey = @"isCustomSceneCheck";

NSString * const TSPKEventUnixTimeStampKey = @"eventUnixTimeStamp";
NSString * const TSPKEventTimeStampKey = @"eventTimeStamp";
NSString * const TSPKLogCommonTag = @"PrivacyCommonInfo";
NSString * const TSPKLogCheckTag = @"PrivacyCheckInfo";
NSString * const TSPKLogCustomAnchorCheckTag = @"PrivacyCustomAnchorCheckInfo";
NSString * const TSPKPairDelayClose = @"pair_delay_close";
NSString * const TSPKCustomAnchor = @"CustomAnchor";

NSString * const TSPKMethodEndKey = @"end";
NSString * const TSPKMethodBinaryKey = @"binary";

// view life cycle
NSString * const TSPKViewDidAppear = @"TSPKViewDidAppear";
NSString * const TSPKViewDidDisappear = @"TSPKViewDidDisappear";
NSString * const TSPKViewWillAppear = @"TSPKViewWillAppear";
NSString * const TSPKViewWillDisappear = @"TSPKViewWillDisappear";
NSString * const TSPKViewDealloc = @"TSPKViewDealloc";
NSString * const TSPKViewDidLoad = @"TSPKViewDidLoad";

NSString * const TSPKPageNameKey = @"pageName";
NSString * const TSPKRuleEngineSpaceALL = @"all";
NSString * const TSPKRuleEngineSpaceGuard = @"guard";
NSString * const TSPKRuleEngineSpaceGuardFuse = @"guard_fuse";
NSString * const TSPKRuleEngineSpacePolicyDecision = @"policy_decision";

// warning types
NSString * const TSPKWarningTypeUnReleaseCheck = @"is_pair_not_close";
NSString * const TSPKWarningTypeDelayReleaseCheck = @"is_pair_delay_close";

// policy
NSString * const TSPKPolicyLocationRegionLimit = @"location_region_limit";

// network
NSString * const TSPKNetworkLogCommon = @"PrivacyNetworkCommon";

// life cycle
NSString * const TSPKAppWillEnterForegroundNotificationKey = @"applicationWillEnterForegroundNotification";
NSString * const TSPKAppDidEnterBackgroundNotificationKey = @"applicationDidEnterBackgroundNotification";
NSString * const TSPKAppWillResignActiveNotificationKey = @"applicationWillResignActiveNotification";
NSString * const TSPKAppDidBecomeActiveNotificationKey = @"applicationDidBecomeActiveNotification";
NSString * const TSPKAppDidReceiveMemoryWarningNotificationKey = @"applicationDidReceiveMemoryWarningNotification";
NSString * const TSPKAppWillTerminateNotificationKey = @"applicationWillTerminateNotification";

NSString * const TSPKPolicyDecisionSourceGuard = @"Guard";

NSString * const TSPKAPISubTypeKey = @"api_sub_type";

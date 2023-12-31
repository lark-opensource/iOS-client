//
//  TSPKPermissionChecker.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/5/9.
//

#import "TSPKPermissionChecker.h"
#import "TSPKDetectPipeline.h"
#import "TSPKPermissionCheckerAlert.h"
#import "TSPKConfigs.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@implementation TSPKPermissionChecker

+ (void)start {
    if ([[TSPKConfigs sharedConfig] enablePermissionChecker]) {
#if DEBUG
        TSPKPermissionChecker *checker = [TSPKPermissionChecker new];
        // Album
        [checker buildPipeline:@"TSPKAlbumOfALAssetsLibraryPipeline"];
        [checker buildPipeline:@"TSPKAlbumOfPHAssetPipeline"];
        [checker buildPipeline:@"TSPKAlbumOfPHAssetChangeRequestPipeline"];
        [checker buildPipeline:@"TSPKAlbumOfPHAssetCollectionPipeline"];
        [checker buildPipeline:@"TSPKAlbumOfPHCollectionListPipeline"];
        [checker buildPipeline:@"TSPKAlbumOfPHImageManagerPipeline"];
        [checker buildPipeline:@"TSPKAlbumOfPHPhotoLibraryPipeline"];
        [checker buildPipeline:@"TSPKAlbumOfPHPickerViewControllerPipeline"];
        [checker buildPipeline:@"TSPKAlbumOfUIImagePickerControllerPipeline"];
        // Audio
        [checker buildPipeline:@"TSPKAudioOfAudioToolboxPipeline"];
        [checker buildPipeline:@"TSPKAudioOfAVAudioRecorPipeline"];
        [checker buildPipeline:@"TSPKAudioOfAVAudioSessionPipeline"];
        [checker buildPipeline:@"TSPKAudioOfAVCaptureDevicePipeline"];
        // Calendar
        [checker buildPipeline:@"TSPKCalendarOfEKEventStorePipeline"];
        // CallCenter
        [checker buildPipeline:@"TSPKCallCenterOfCTCallCenterPipeline"];
        // Clipboard
        [checker buildPipeline:@"TSPKClipboardOfUIPasteboardPipeline"];
        // Contact
        [checker buildPipeline:@"TSPKContactOfABPersonPipeline"];
        [checker buildPipeline:@"TSPKContactOfCNContactStorePipeline"];
        // Health
        [checker buildPipeline:@"TSPKHealthOfHKHealthStorePipeline"];
        // IDFA
        [checker buildPipeline:@"TSPKIDFAOfASIdentifierManagerPipeline"];
        [checker buildPipeline:@"TSPKIDFAOfATTrackingManagerPipeline"];
        // IDFV
        [checker buildPipeline:@"TSPKIDFVOfUIDevicePipeline"];
        // Location
        [checker buildPipeline:@"TSPKLocationOfCLLocationManagerPipeline"];
        [checker buildPipeline:@"TSPKLocationOfCLLocationManagerReqAlwaysAuthPipeline"];
        // LockID
        [checker buildPipeline:@"TSPKLockIDOfLAContextPipeline"];
        // Media
        [checker buildPipeline:@"TSPKMediaOfMPMediaLibraryPipeline"];
        [checker buildPipeline:@"TSPKMediaOfMPMediaQueryPipeline"];
        // Message
        [checker buildPipeline:@"TSPKMessageOfMFMessageComposeViewControllerPipeline"];
        // Motion
        [checker buildPipeline:@"TSPKMotionOfCLLocationManagerPipeline"];
        [checker buildPipeline:@"TSPKMotionOfCMAltimeterPipeline"];
        [checker buildPipeline:@"TSPKMotionOfCMMotionActivityManagerPipeline"];
        [checker buildPipeline:@"TSPKMotionOfCMMotionManagerPipeline"];
        [checker buildPipeline:@"TSPKMotionOfCMPedometerPipeline"];
        [checker buildPipeline:@"TSPKMotionOfUIDevicePipeline"];
        // Network
        [checker buildPipeline:@"TSPKNetworkOfCLGeocoderPipeline"];
        [checker buildPipeline:@"TSPKNetworkOfCTCarrierPipeline"];
        [checker buildPipeline:@"TSPKNetworkOfNSLocalePipeline"];
        // ScrrenRecorder
        [checker buildPipeline:@"TSPKScreenRecordOfRPScreenRecorderPipeline"];
        [checker buildPipeline:@"TSPKScreenRecorderOfRPSystemBroadcastPickerViewPipeline"];
        // Snapshot
        [checker buildPipeline:@"TSPKSnapShotOfUIGraphicsPipeline"];
        [checker buildPipeline:@"TSPKSnapShotOfUIViewPipeline"];
        // Video
        [checker buildPipeline:@"TSPKVideoOfAVCaptureStillImageOutputPipeline"];
        [checker buildPipeline:@"TSPKVideoOfAVCaptureDevicePipeline"];
        [checker buildPipeline:@"TSPKVideoOfAVCaptureSessionPipeline"];
        // Wifi
        [checker buildPipeline:@"TSPKWifiOfCaptiveNetworkPipeline"];
        [checker buildPipeline:@"TSPKWifiOfNEHotspotNetworkPipeline"];

#else
    
#endif
    }
}

- (void)buildPipeline:(NSString *)pipelineName {
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        Class targetClass = NSClassFromString(pipelineName);
        if (targetClass == nil) {
            return;
        }
    
        if ([self isBadcase:pipelineName]) {
            NSString *message = [NSString stringWithFormat:@"plz check these permissions [%@]", [[[self class] pipeline2PermissionDic:pipelineName] componentsJoinedByString:@","]];
            [TSPKPermissionCheckerAlert showWithMessage:message];
        }
//    });
}

- (BOOL)isBadcase:(NSString *)pipelineName {
    NSArray<NSString *> *permissions = [[self class] pipeline2PermissionDic:pipelineName];
    BOOL result = permissions.count != 0;
    for (NSString *permission in permissions) {
        if ([[NSBundle mainBundle] infoDictionary][permission]) {
            result = NO;
            break;
        }
        // sometimes permission will be defined in InfoPlist
        NSString *value = [[NSBundle mainBundle] localizedStringForKey:permission value:nil table:@"InfoPlist"];
        BOOL isPermissionDefine = !([value isEqualToString:permission] || value == nil);
        if (isPermissionDefine) {
            result = NO;
            break;
        }
    }
    
    return result;
}

+ (NSArray<NSString *> *)pipeline2PermissionDic:(NSString *)pipelineName {
    NSDictionary *dict = @{
        // Album
        @"TSPKAlbumOfALAssetsLibraryPipeline": @[@"NSPhotoLibraryUsageDescription", @"NSPhotoLibraryAddUsageDescription"],
        @"TSPKAlbumOfPHAssetPipeline": @[@"NSPhotoLibraryUsageDescription", @"NSPhotoLibraryAddUsageDescription"],
        @"TSPKAlbumOfPHAssetChangeRequestPipeline": @[@"NSPhotoLibraryUsageDescription", @"NSPhotoLibraryAddUsageDescription"],
        @"TSPKAlbumOfPHAssetCollectionPipeline": @[@"NSPhotoLibraryUsageDescription", @"NSPhotoLibraryAddUsageDescription"],
        @"TSPKAlbumOfPHCollectionListPipeline": @[@"NSPhotoLibraryUsageDescription", @"NSPhotoLibraryAddUsageDescription"],
        @"TSPKAlbumOfPHImageManagerPipeline": @[@"NSPhotoLibraryUsageDescription", @"NSPhotoLibraryAddUsageDescription"],
        @"TSPKAlbumOfPHPhotoLibraryPipeline": @[@"NSPhotoLibraryUsageDescription", @"NSPhotoLibraryAddUsageDescription"],
        @"TSPKAlbumOfPHPickerViewControllerPipeline": @[@"NSPhotoLibraryUsageDescription", @"NSPhotoLibraryAddUsageDescription"],
        @"TSPKAlbumOfUIImagePickerControllerPipeline": @[@"NSPhotoLibraryUsageDescription", @"NSPhotoLibraryAddUsageDescription"],
        // Audio
        @"TSPKAudioOfAudioToolboxPipeline": @[@"NSMicrophoneUsageDescription"],
        @"TSPKAudioOfAVAudioRecorPipeline": @[@"NSMicrophoneUsageDescription"],
        @"TSPKAudioOfAVAudioSessionPipeline": @[@"NSMicrophoneUsageDescription"],
        @"TSPKAudioOfAVCaptureDevicePipeline": @[@"NSMicrophoneUsageDescription"],
        // Calendar
        @"TSPKCalendarOfEKEventStorePipeline": @[@"NSCalendarsUsageDescription"],
        // Contact
        @"TSPKContactOfABPersonPipeline": @[@"NSContactsUsageDescription"],
        @"TSPKContactOfCNContactStorePipeline": @[@"NSContactsUsageDescription"],
        // IDFA
        @"TSPKIDFAOfASIdentifierManagerPipeline": @[@"NSUserTrackingUsageDescription"],
        @"TSPKIDFAOfATTrackingManagerPipeline": @[@"NSUserTrackingUsageDescription"],
        // Location
        @"TSPKLocationOfCLLocationManagerPipeline": @[@"NSLocationAlwaysAndWhenInUseUsageDescription", @"NSLocationUsageDescription", @"NSLocationWhenInUseUsageDescription"],
        @"TSPKLocationOfCLLocationManagerReqAlwaysAuthPipeline": @[@"NSLocationAlwaysAndWhenInUseUsageDescription", @"NSLocationAlwaysUsageDescription"],
        // LockID
        @"TSPKLockIDOfLAContextPipeline": @[@"NSFaceIDUsageDescription"],
        // Media
        @"TSPKMediaOfMPMediaLibraryPipeline": @[@"NSAppleMusicUsageDescription"],
        @"TSPKMediaOfMPMediaQueryPipeline": @[@"NSAppleMusicUsageDescription"],
        // Motion
        @"TSPKMotionOfCLLocationManagerPipeline": @[@"NSMotionUsageDescription"],
        @"TSPKMotionOfCMAltimeterPipeline": @[@"NSMotionUsageDescription"],
        @"TSPKMotionOfCMMotionActivityManagerPipeline": @[@"NSMotionUsageDescription"],
        @"TSPKMotionOfCMMotionManagerPipeline": @[@"NSMotionUsageDescription"],
        @"TSPKMotionOfCMPedometerPipeline": @[@"NSMotionUsageDescription"],
        @"TSPKMotionOfUIDevicePipeline": @[@"NSMotionUsageDescription"],
        // Video
        @"TSPKVideoOfAVCaptureStillImageOutputPipeline": @[@"NSCameraUsageDescription"],
        @"TSPKVideoOfAVCaptureDevicePipeline": @[@"NSCameraUsageDescription"],
        @"TSPKVideoOfAVCaptureSessionPipeline": @[@"NSCameraUsageDescription"],
    };
    
    return [dict btd_arrayValueForKey:pipelineName];
}



@end

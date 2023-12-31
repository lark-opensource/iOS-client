//
//  LarkSensitivityControl+OP.swift
//  OPAdapter
//
//  Created by baojianjun on 2022/9/29.
//

import Foundation
import LarkSensitivityControl
import CoreLocation
import LarkSetting
import LarkOpenAPIModel

@objc final public class OPSensitivityEntry: NSObject {
 
    static var fgDisableKey: String { "openplatform.location_api_use_psda.disable" }
    
    static func apiError(from error: Error) -> OpenAPIError {
        OpenAPIError(errno: OpenAPICommonErrno.internalError)
            .setMonitorMessage(error.localizedDescription)
    }
    
    public static func sensitivityControlEnable() -> Bool {
        return !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: fgDisableKey))
    }
    
}


@objc
public enum OPSensitivityEntryToken: Int {
    // 此API 还未纳入管控，为了API统一先占位
    case placeholder
    /// debug页面使用不要在正常的业务中使用
    case debug
    // ContinueLocationManager
    case continueLocationManagerStartLocationUpdate
    case continueLocationManagerHandleAppEnterForeground
    case continueLocationManagerRequestAuthoriztion
    // OpenPluginLocationV2
    case openPluginLocationV2StartLocationUpdateV2
    case openPluginLocationV2GetLocationV2
    case openPluginLocationV2HandleAppEnterForeground
    // GeoLocationHandler
    case geoLocationHandlerRequestLocation
    case geoLocationHandlerStartLocation
    case geoLocationHandlerGetLocation
    // OpenPluginBeaconManager
    case openPluginBeaconManagerStartBeaconDiscovery
    case openPluginBeaconManagerStartBeaconDiscoveryHandler
    // OpenPluginWiFi+GetConnectedWifi
    case openPluginWiFiGetConnectedWifi
    // EMALocationManagerV2
    case eMALocationManagerV2ReqeustLocationWithIsNeedRequestAuthoriztion
    case eMALocationManagerV2RequestAuthoriztionIsShowAlert
    // BDPMapView
    case bDPMapViewMapViewWillStartLocatingUserRequestWhenInUseAuthorization
    case bDPMapViewMapViewWillStartLocatingUserStartUpdatingLocation
    case jsSDKGeoLocationHandlerRequestLocationReverseGeocode
    case openPluginDeviceCredentialStartDeviceCredential
    case openPluginWiFiGetConnectedWifiNEHotspotNetwork
    case openPluginWiFiGetConnectedWifiCNCopyCurrentNetworkInfo
    case openLocationPickerControllerMapViewRegionDidChangeAnimated
    case openPlatformSpeedClockInGetWifiInfo
    case openPlatformSpeedClockInGetWifiInfoCNCopyCurrentNetworkInfo
    case openPlatformWifiCheckerGetCurrenWifiInfoSyncCNCopyCurrentNetworkInfo
    case openPlatformWifiCheckerGetWifiInfoNEHotspotNetwork
    case jssdkGetConnectedWifiHandlerGetConnectedWifiCNCopyCurrentNetworkInfo
    case jssdkGetInterfaceHandlerGetWifiInfo
    case jssdkScanBluetoothDeviceHandlerCentralManagerDidUpdateState
    case jssdkConnectBluetoothDeviceHandler
    case eeMicroAppSDKEMALocationManagerV2ReqeustLocation
    case openPluginContinueLocationManagerStartLocationUpdateMonitor
    case openPluginContinueLocationManagerStopLocationUpdateMonitor
//    case eeMicroAppSDKEMALocationPickerControllerMapViewRegionDidChangeAnimate
    case larkOpenCommonPluginsOpenPluginBluetoothManagerGetWifiStatus
    case openPluginBluetoothStartBluetoothDevicesDiscovery
    case openPluginBluetoothManagerDiscoverServices
    case openPluginBluetoothManagerGetBLEDeviceCharacteristics
    case openPluginBluetoothManagerReadBLECharacteristicValue
    case openPluginBluetoothManagerWriteBLECharacteristicValue
    case openPluginBluetoothManagerConnectBLEDevice
    case openPluginAccelerometerEnableAccelerometer
    case openPluginAccelerometerResumeActiveIfNeeded
    case webBrowserScreenOrientationManagerInternalStartMonitor
    case speedClockInFetchGPSInfo
//    case emaLocationPickerControllerViewDidLoad
    case openLocationPickerControllerViewDidLoad
//    case emaViewLocationControllerViewDidLoad
    case openViewLocationControllerViewDidLoad

    case webCopyLinkMenuPluginCopyLink
    case copyTextHandler
    case getClipboardInfoHandler
    case openPluginClipboardGetClipboardData
    case openPluginClipboardSetClipboardData
    case BDPInputViewCopy
    case BDPInputViewCut
    case TMAStickerTextViewCopy
    case TMAStickerTextViewCut
    case OPWebDriveMoreCopyLinkProviderCopyLink
    case BlockPreviewControllerCopyPreviewURL
    case OpenPluginImage_saveImageToPhotosAlbum_creationRequestForAsset
    case OpenPluginImage_saveVideoToPhotosAlbum_creationRequestForAsset
    case SaveImageHandler_handle_UIImageWriteToSavedPhotosAlbum
    case ContactExternalInviteHandler_requestSystemContactAuthorization_ContactsEntry_requestAccess
    case PHImageManager_requestAVAsset_chooseMedia_showMediaAlbumVideosPicker
    case PHPhotoLibrary_requestAuthorization_BDPAuthorization_checkAlbumPermission
    case BDPAuthorization_checkMicrophonePermission_AVAudioSession_requestRecordPermission
    case BDPAuthorization_checkCameraPermission_AVCaptureDevice_requestAccess
    case PHImageManager_requestImageData_OpenPluginChooseMedia_handleImageAsset
    case OpenPluginChooseMedia_showCameraVC_Utils_savePhoto
    case OpenPluginChooseMedia_showCameraVC_Utils_saveVideo
    case OPNormalCamera_startVideoCapture
    case OPNormalCamera_startRecord
    case OPScanCodeCamera_openCamera
}

extension OPSensitivityEntryToken {
    public var psdaToken: LarkSensitivityControl.Token {
        return Token(stringValue)
        
    }
    public var stringValue: String {
        switch self {
        case .placeholder:
            return "placeholder"
        case .continueLocationManagerStartLocationUpdate:
            return "LARK-PSDA-OP-ContinueLocationManager-StartLocationUpdate"
        case .continueLocationManagerHandleAppEnterForeground:
            return "LARK-PSDA-OP-ContinueLocationManager-HandleAppEnterForeground"
        case .continueLocationManagerRequestAuthoriztion:
            return "LARK-PSDA-OP-ContinueLocationManager-RequestAuthoriztion"
        case .openPluginLocationV2StartLocationUpdateV2:
            return "LARK-PSDA-OP-OpenPluginLocationV2-StartLocationUpdateV2"
        case .openPluginLocationV2GetLocationV2:
            return "LARK-PSDA-OP-OpenPluginLocationV2-GetLocationV2"
        case .openPluginLocationV2HandleAppEnterForeground:
            return "LARK-PSDA-OP-OpenPluginLocationV2-HandleAppEnterForeground"
        case .geoLocationHandlerRequestLocation:
            return "LARK-PSDA-OP-GeoLocationHandler-RequestLocation"
        case .geoLocationHandlerStartLocation:
            return "LARK-PSDA-OP-GeoLocationHandler-StartLocation"
        case .geoLocationHandlerGetLocation:
            return "LARK-PSDA-OP-GeoLocationHandler-GetLocation"
        // OpenPluginBeaconManager
        case .openPluginBeaconManagerStartBeaconDiscovery:
            return "LARK-PSDA-OP-OpenPluginBeaconManager-StartBeaconDiscovery"
        case .openPluginBeaconManagerStartBeaconDiscoveryHandler:
            return "LARK-PSDA-OP-OpenPluginBeaconManager-StartBeaconDiscoveryHandler"
        // OpenPluginWiFi+GetConnectedWifi
        case .openPluginWiFiGetConnectedWifi:
            return "LARK-PSDA-OP-OpenPluginWiFi-GetConnectedWifi"
        case .eMALocationManagerV2ReqeustLocationWithIsNeedRequestAuthoriztion:
            return "LARK-PSDA-OP-EMALocationManagerV2-ReqeustLocationWithIsNeedRequestAuthoriztion"
        case .eMALocationManagerV2RequestAuthoriztionIsShowAlert:
            return "LARK-PSDA-OP-EMALocationManagerV2-RequestAuthoriztionIsShowAlert"
        case .bDPMapViewMapViewWillStartLocatingUserRequestWhenInUseAuthorization:
            return "LARK-PSDA-OP-BDPMapView-MapViewWillStartLocatingUser-RequestWhenInUseAuthorization"
        case .bDPMapViewMapViewWillStartLocatingUserStartUpdatingLocation:
            return "LARK-PSDA-OP-BDPMapView-MapViewWillStartLocatingUser-StartUpdatingLocation"
        case .jsSDKGeoLocationHandlerRequestLocationReverseGeocode:
            return "LARK-PSDA-GeoLocationHandler-RequestLocation-reverseGeocode"
        case .openPluginDeviceCredentialStartDeviceCredential:
            return "LARK-PSDA-OpenPluginDeviceCredential-startDeviceCredential"
        case .openPluginWiFiGetConnectedWifiNEHotspotNetwork:
            return "LARK-PSDA-OpenPluginWiFi-getConnectedWifi-NEHotspotNetwork"
        case .openPluginWiFiGetConnectedWifiCNCopyCurrentNetworkInfo:
            return "LARK-PSDA-OpenPluginWiFi-getConnectedWifi-CNCopyCurrentNetworkInfo"
        case .openLocationPickerControllerMapViewRegionDidChangeAnimated:
            return "LARK-PSDA-OpenLocationPickerController-mapView_regionDidChangeAnimated"
        case .openPlatformSpeedClockInGetWifiInfo:
            return "LARK-PSDA-SpeedClockIn-getWifiInfo"
        case .openPlatformSpeedClockInGetWifiInfoCNCopyCurrentNetworkInfo:
            return "LARK-PSDA-SpeedClockIn-getWifiInfo-CNCopyCurrentNetworkInfo"
        case .openPlatformWifiCheckerGetCurrenWifiInfoSyncCNCopyCurrentNetworkInfo:
            return "LARK-PSDA-WifiChecker-getCurrenWifiInfoSync-CNCopyCurrentNetworkInfo"
        case .openPlatformWifiCheckerGetWifiInfoNEHotspotNetwork:
            return "LARK-PSDA-WifiChecker-getWifiInfo-NEHotspotNetwork"
        case .jssdkGetConnectedWifiHandlerGetConnectedWifiCNCopyCurrentNetworkInfo:
            return "LARK-PSDA-GetConnectedWifiHandler-GetConnectedWifi-CNCopyCurrentNetworkInfo"
        case .jssdkGetInterfaceHandlerGetWifiInfo:
            return "LARK-PSDA-GetInterfaceHandler-getWifiInfo"
        case .jssdkScanBluetoothDeviceHandlerCentralManagerDidUpdateState:
            return "LARK-PSDA-ScanBluetoothDeviceHandler-centralManagerDidUpdateState"
        case .jssdkConnectBluetoothDeviceHandler:
            return "LARK-PSDA-ConnectBluetoothDeviceHandler"
        case .eeMicroAppSDKEMALocationManagerV2ReqeustLocation:
            return "LARK-PSDA-EMALocationManagerV2-reqeustLocationWithIsNeedRequestAuthoriztion"
        case .openPluginContinueLocationManagerStartLocationUpdateMonitor:
            return "LARK-PSDA-OpenPluginContinueLocationManager-startLocationUpdate-monitor"
        case .openPluginContinueLocationManagerStopLocationUpdateMonitor:
            return "LARK-PSDA-OpenPluginContinueLocationManager-stopLocationUpdate-monitor"
        case .larkOpenCommonPluginsOpenPluginBluetoothManagerGetWifiStatus:
            return "LARK-PSDA-OpenPluginWiFi-getWifiStatus"
        case .openPluginBluetoothStartBluetoothDevicesDiscovery:
            return"LARK-PSDA-OpenPluginBluetooth-startBluetoothDevicesDiscovery"
        case .openPluginBluetoothManagerDiscoverServices:
            return "LARK-PSDA-OpenPluginBluetoothManager-discoverServices"
        case .openPluginBluetoothManagerGetBLEDeviceCharacteristics:
            return "LARK-PSDA-OpenPluginBluetoothManager-getBLEDeviceCharacteristics"
        case .openPluginBluetoothManagerReadBLECharacteristicValue:
            return "LARK-PSDA-OpenPluginBluetoothManager-readBLECharacteristicValue"
        case .openPluginBluetoothManagerWriteBLECharacteristicValue:
            return "LARK-PSDA-OpenPluginBluetoothManager-writeBLECharacteristicValue"
        case .openPluginBluetoothManagerConnectBLEDevice:
            return "LARK-PSDA-OpenPluginBluetoothManager-connectBLEDevice"
        case .openPluginAccelerometerEnableAccelerometer:
            return "LARK-PSDA-OpenPluginAccelerometer-enableAccelerometer"
        case .openPluginAccelerometerResumeActiveIfNeeded:
            return "LARK-PSDA-OpenPluginAccelerometer-resumeActiveIfNeeded"
        case .webBrowserScreenOrientationManagerInternalStartMonitor:
            return "LARK-PSDA-ScreenOrientationManager-internalStartMonitor"
        case .speedClockInFetchGPSInfo:
            return "LARK-PSDA-SpeedClockIn-fetchGPSInfo"
        case .openLocationPickerControllerViewDidLoad:
            return "LARK-PSDA-OpenLocationPickerController-viewDidLoad"
        case .openViewLocationControllerViewDidLoad:
            return "LARK-PSDA-OpenViewLocationController-viewDidLoad"
        case .webCopyLinkMenuPluginCopyLink:
            return "LARK-PSDA-opplatform-api-WebCopyLinkMenuPlugin-copyLink"
        case .copyTextHandler:
            return "LARK-PSDA-openplatform-CopyTextHandler"
        case .getClipboardInfoHandler:
            return "LARK-PSDA-openplatform-GetClipboardInfoHandler"
        case .openPluginClipboardGetClipboardData:
            return "LARK-PSDA-openplatform-OpenPluginClipboard-getClipboardData"
        case .openPluginClipboardSetClipboardData:
            return "LARK-PSDA-openplatform-OpenPluginClipboard-setClipboardData"
        case .BDPInputViewCopy:
            return "LARK-PSDA-openplatform-BDPInputView-copy"
        case .BDPInputViewCut:
            return "LARK-PSDA-openplatform-BDPInputView-cut"
        case .TMAStickerTextViewCopy:
            return "LARK-PSDA-openplatform-TMAStickerTextView-Copy"
        case .TMAStickerTextViewCut:
            return "LARK-PSDA-openplatform-TMAStickerTextView-Cut"
        case .debug:
            return kTokenAvoidInterceptIdentifier
        case .OPWebDriveMoreCopyLinkProviderCopyLink:
            return "LARK-PSDA-OPWebDriveMoreCopyLinkProvider-copy_link"
        case .BlockPreviewControllerCopyPreviewURL:
            return "LARK-PSDA-BlockPreviewController-copyPreviewURL"
        case .OpenPluginImage_saveImageToPhotosAlbum_creationRequestForAsset:
            return "LARK-PSDA-OpenPluginImage_saveImageToPhotosAlbum_creationRequestForAsset"
        case .OpenPluginImage_saveVideoToPhotosAlbum_creationRequestForAsset:
            return "LARK-PSDA-OpenPluginImage_saveVideoToPhotosAlbum_creationRequestForAsset"
        case .SaveImageHandler_handle_UIImageWriteToSavedPhotosAlbum:
            return "LARK-PSDA-SaveImageHandler_handle_UIImageWriteToSavedPhotosAlbum"
        case .ContactExternalInviteHandler_requestSystemContactAuthorization_ContactsEntry_requestAccess:
            return "LARK-PSDA-ContactExternalInviteHandler_requestSystemContactAuthorization_ContactsEntry_requestAccess"
        case .PHImageManager_requestAVAsset_chooseMedia_showMediaAlbumVideosPicker:
            return "LARK-PSDA-PHImageManager_requestAVAsset_chooseMedia_showMediaAlbumVideosPicker"
        case .PHPhotoLibrary_requestAuthorization_BDPAuthorization_checkAlbumPermission:
            return "LARK-PSDA-PHPhotoLibrary_requestAuthorization_BDPAuthorization_checkAlbumPermission"
        case .BDPAuthorization_checkMicrophonePermission_AVAudioSession_requestRecordPermission:
            return "LARK-PSDA-BDPAuthorization_checkMicrophonePermission_AVAudioSession_requestRecordPermission"
        case .BDPAuthorization_checkCameraPermission_AVCaptureDevice_requestAccess:
            return "LARK-PSDA-BDPAuthorization_checkCameraPermission_AVCaptureDevice_requestAccess"
        case .PHImageManager_requestImageData_OpenPluginChooseMedia_handleImageAsset:
            return "LARK-PSDA-PHImageManager_requestImageData_OpenPluginChooseMedia_handleImageAsset"
        case .OpenPluginChooseMedia_showCameraVC_Utils_savePhoto:
            return "LARK-PSDA-OpenPluginChooseMedia_showCameraVC_Utils_savePhoto"
        case .OpenPluginChooseMedia_showCameraVC_Utils_saveVideo:
            return "LARK-PSDA-OpenPluginChooseMedia_showCameraVC_Utils_saveVideo"
        case .OPNormalCamera_startVideoCapture:
            return "LARK-PSDA-OP-OPNormalCamera_startVideoCapture"
        case .OPNormalCamera_startRecord:
            return "LARK-PSDA-OP-OPNormalCamera_startRecord"
        case .OPScanCodeCamera_openCamera:
            return "LARK-PSDA-OP-OPScanCodeCamera_openCamera"
        }
    }
}

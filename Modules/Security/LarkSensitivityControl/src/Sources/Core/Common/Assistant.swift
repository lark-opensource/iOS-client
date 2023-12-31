//
//  Assistant.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/16.
//

import UIKit

/// 上下文信息
@objc(PSDAContext)
public final class Context: NSObject {
    /// 库名
    public let sdkName: String
    /// 方法名
    public let methodName: String
    /// 本地atomicInfoList
    public var atomicInfoList: [String]

    /// 构造方法
    /// - Parameters:
    ///   - sdkName: 库名
    ///   - methodName: 方法名
    @available(*, deprecated, message: "We will deprecate this method, please use init(_ atomicInfoList: [String])")
    public init(sdkName: String, methodName: String) {
        self.sdkName = sdkName
        self.methodName = methodName
        self.atomicInfoList = [AtomicInfo.Default.defaultAtomicInfo.rawValue]
    }

    @objc
    public init(_ atomicInfoList: [String]) {
        self.sdkName = ""
        self.methodName = ""
        self.atomicInfoList = atomicInfoList
    }
}

struct Assistant {

    private static let isKA = {
        return (LSC.environment?.isKA).or(false)
    }()

    private static let isDisabled = {
        var disabled: Bool?
        do {
            disabled = try LSC.settings?.bool(key: "sensitive_api_control_disable", default: false)
        } catch {
            // do nothing
        }
        return disabled.or(false)
    }()

    /// 是否降级处理
    static func isDownGraded() -> Bool {
        return isKA || isDisabled
    }

    private static var isBOE: Bool = {
        if let isBOE = LSC.environment?.boe {
            return isBOE
        }
        return false
    }()

    static func checkToken(_ token: Token,
                           context: Context) throws {
        // KA版本降级处理
        if isKA {
            return
        }

        // BOE环境不进行校验
        if isBOE {
            LSC.logger?.warn("is boe")
            return
        }
        // 功能禁用降级处理
        if isDisabled {
            LSC.logger?.warn("sensitive api control disabled")
            return
        }

        try token.check(context: context)
    }
}

/// atomicInfo枚举
public enum AtomicInfo {
    internal enum Default: String {
        case defaultAtomicInfo = "default_atomic_info"
    }

    public enum AudioRecord: String {
        case requestRecordPermission = "AVAudioSession.requestRecordPermission(_:)"
        case requestAccessAudio = "AVCaptureDevice.requestAccess(for:AVMediaType.audio completionHandler:)"
        case audioOutputUnitStart = "AudioOutputUnitStart(_:)"
        case AUGraphStart = "AUGraphStart(_:)"
        case defaultAudioDevice = "AVCaptureDevice.default(for:.Audio)"
        case defaultAudioDeviceWithDeviceType = "AVCaptureDevice.default(_:for:.Audio position:)"
        case AudioQueueStart = "AudioQueueStart(_:_:)"
    }

    public enum Calendar: String {
        case requestAccess = "EKEventStore.requestAccess(to:completion:)"
        case requestWriteOnlyAccessToEvents = "EKEventStore.requestWriteOnlyAccessToEvents(completion:)"
        case requestFullAccessToEvents = "EKEventStore.requestFullAccessToEvents(completion:)"
        case requestFullAccessToReminders = "EKEventStore.requestFullAccessToReminders(completion:)"
        case calendars = "EKEventStore.calendars(for:)"
        case calendar = "EKEventStore.calendar(withIdentifier:)"
        case saveCalendar = "EKEventStore.saveCalendar(_:commit:)"
        case removeCalendar = "EKEventStore.removeCalendar(_:commit:)"
        case calendarItem = "EKEventStore.calendarItem(withIdentifier:)"
        case calendarItems = "EKEventStore.calendarItems(withExternalIdentifier:)"
        case events = "EKEventStore.events(matching:)"
        case remove = "EKEventStore.remove(_:span:commit:)"
        case saveWithCommit = "EKEventStore.save(_:span:commit:)"
        case save = "EKEventStore.save(_:span:)"
        case calendarsWithSource = "EKSource.calendars(for:)"
        case event = "EKEventStore.event(withIdentifier:)"
    }

    public enum Camera: String {
        case requestAccessCamera = "AVCaptureDevice.requestAccess(for:AVMediaType.video completionHandler:)"
        case startRunning = "AVCaptureSession.startRunning()"
        case defaultCameraDevice = "AVCaptureDevice.default(for:.Video)"
        case captureStillImageAsynchronously = "AVCaptureStillImageOutput.captureStillImageAsynchronously(from:completionHandler:)"
        case startRecording = "AVCaptureMovieFileOutput.startRecording(to:recordingDelegate:)"
        case defaultCameraDeviceWithDeviceType = "AVCaptureDevice.default(_:for:.Video position:)"
    }

    public enum DeviceInfo: String {
        case fetchCurrent = "NEHotspotNetwork.fetchCurrent(completionHandler:)"
        case CNCopyCurrentNetworkInfo = "CNCopyCurrentNetworkInfo"
        case getifaddrs = "getifaddrs(_:)"
        case ssid = "NEHotspotNetwork.ssid"
        case bssid = "NEHotspotNetwork.bssid"
        case drawHierarchy = "UIView.drawHierarchy(in:afterScreenUpdates:)"
        case RPSystemBroadcastPickerViewInit = "RPSystemBroadcastPickerView.init(frame:)"
        case reverseGeocodeLocation = "CLGeocoder.reverseGeocodeLocation(_:completionHandler:)"
        case currentCalls = "CTCallCenter.currentCalls"
        case evaluatePolicy = "LAContext.evaluatePolicy(_:localizedReason:reply:)"
        case isProximityMonitoringEnabled = "UIDevice.isProximityMonitoringEnabled"
        case proximityState = "UIDevice.proximityState"
        case setProximityMonitoringEnabled = "UIDevice.setIsProximityMonitoringEnabled()"
        case startDeviceMotionUpdatesToQueue = "CMMotionManager.startDeviceMotionUpdates(to:withHandler:)"
        case startAccelerometerUpdatesToQueue = "CMMotionManager.startAccelerometerUpdates(to:withHandler:)"
        case queryPedometerData = "CMPedometer.queryPedometerData(from:to:withHandler:)"
        case scanForPeripherals = "CBCentralManager.scanForPeripherals(withServices:options:)"
        case connect = "CBCentralManager.connect(_:options:)"
        case discoverServices = "CBPeripheral.discoverServices(_:)"
        case discoverCharacteristics = "CBPeripheral.discoverCharacteristics(_:for:)"
        case readValueForCharacteristic = "CBPeripheral.readValue(for:CBCharacteristic)"
        case writeValue = "CBPeripheral.writeValue(_:for:type:)"
        case startAdvertising = "CBPeripheralManager.startAdvertising(_:)"
        case getDeviceName = "UIDevice.name"
    }

    public enum Location: String {
        case requestWhenInUseAuthorization = "CLLocationManager.requestWhenInUseAuthorization()"
        case requestLocation = "CLLocationManager.requestLocation()"
        case startUpdatingLocation = "CLLocationManager.startUpdatingLocation()"
        case startMonitoringSignificantLocationChanges = "CLLocationManager.startMonitoringSignificantLocationChanges()"
        case startMonitoring = "CLLocationManager.startMonitoring(for:)"
        case startRangingBeacons = "CLLocationManager.startRangingBeacons(in:)"
        case startRangingBeaconsSatisfyingConstraint = "CLLocationManager.startRangingBeacons(satisfying:)"
        case allowsBackgroundLocationUpdates = "CLLocationManager.allowsBackgroundLocationUpdates"
        case startUpdatingHeading = "CLLocationManager.startUpdatingHeading()"
        case requestAlwaysAuthorization = "CLLocationManager.requestAlwaysAuthorization()"
    }

    public enum Pasteboard: String {
        case string = "UIPasteboard.string"
        case setString = "UIPasteBoard.setString(_:)"
        case strings = "UIPasteboard.strings"
        case setStrings = "UIPasteBoard.setStrings(_:)"
        case url = "UIPasteboard.URL"
        case setUrl = "UIPasteBoard.setURL(_:)"
        case urls = "UIPasteboard.URLs"
        case setUrls = "UIPasteBoard.setURLs(_:)"
        case image = "UIPasteboard.image"
        case setImage = "UIPasteBoard.setImage(_:)"
        case images = "UIPasteboard.images"
        case setImages = "UIPasteBoard.setImages(_:)"
        case items = "UIPasteboard.items"
        case setItems = "UIPasteBoard.setItems(_:)"
        case addItems = "UIPasteBoard.addItems(_:)"
        case setItemsWithOptions = "UIPasteBoard.setItems(_:options:)"
        case itemProviders = "UIPasteBoard.itemProviders"
        case setItemProviders = "UIPasteBoard.setItemProviders(_:localOnly:expirationDate:)"
        case data = "UIPasteboard.data(forPasteboardType:)"
    }

    public enum Contacts: String {
        case enumerateContacts = "CNContactStore.enumerateContacts(with:usingBlock:)"
        case requestAccess = "CNContactStore.requestAccess(for:completionHandler:)"
        case execute = "CNContactStore.execute(_:)"
    }

    public enum Album: String {
        case fetchAssetsWithMediaType = "PHAsset.fetchAssets(with:options:)"
        case creationRequestForAsset = "PHAssetChangeRequest.creationRequestForAsset(from:)"
        case creationRequestForAssetFromImage = "PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL:)"
        case creationRequestForAssetFromVideo = "PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL:)"
        case forAsset = "PHAssetCreationRequest.forAsset()"
        case fetchTopLevelUserCollections = "PHCollectionList.fetchTopLevelUserCollections(with:)"
        case requestAuthorization = "PHPhotoLibrary.requestAuthorization(_:)"
        case requestAuthorizationForAccessLevel = "PHPhotoLibrary.requestAuthorization(for:handler:)"
        case fetchAssetCollections = "PHAssetCollection.fetchAssetCollections(with:subtype:options:)"
        case requestData = "PHAssetResourceManager.requestData(for:options:dataReceivedHandler:completionHandler:)"
        case writeData = "PHAssetResourceManager.writeData(for:toFile:options:completionHandler:)"
        case requestAVAsset = "PHImageManager.requestAVAsset(forVideo:options:resultHandler:)"
        case requestExportSession = "PHImageManager.requestExportSession(forVideo:options:exportPreset:resultHandler:)"
        case requestImage = "PHImageManager.requestImage(for:targetSize:contentMode:options:resultHandler:)"
        case requestPlayerItem = "PHImageManager.requestPlayerItem(forVideo:options:resultHandler:)"
        case createPickerViewControllerWithConfiguration = "PHPickerViewController.init(configuration:)"
        case createImagePickerController = "UIImagePickerController.init()"
        case UIImageWriteToSavedPhotosAlbum = "UIImageWriteToSavedPhotosAlbum(_:_:_:_:)"
        case UISaveVideoAtPathToSavedPhotosAlbum = "UISaveVideoAtPathToSavedPhotosAlbum(_:_:_:_:)"
        case requestImageData = "PHImageManager.requestImageData(for:options:resultHandler:)"
        case requestImageDataAndOrientation = "PHImageManager.requestImageDataAndOrientation(for:options:resultHandler:)"
    }

    public enum RTC: String {
        case startAudioCapture = "RtcWrapper.startAudioCapture()"
        case voIPJoin = "VoIPByteRtcSDK.join(channelName:channelKey:uid:secretPair:isSpeakerOn:info:)"
        case startVideoCapture = "RtcWrapper.startVideoCapture()"
    }
}

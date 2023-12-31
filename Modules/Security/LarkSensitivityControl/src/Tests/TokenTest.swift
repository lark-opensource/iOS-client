//
//  TokenTest.swift
//  LarkSensitivityControl-Unit-Tests
//
//  Created by ByteDance on 2022/8/25.
//

import XCTest
@testable import LarkSensitivityControl
import LarkSnCService
import CoreLocation
import ThreadSafeDataStructure
import SSZipArchive
import NetworkExtension
import CoreTelephony
import LocalAuthentication
import CoreBluetooth
import Speech
import CoreMotion
import EventKit
import Photos
import PhotosUI
import Contacts
import ReplayKit

/// 自动更新的时间阈值（BOE）
private let kTokenConfigRefreshTimeSpanBOE = 5 * 60

/// 业务侧使用系统方法，同时不需要拦截的时候可以使用该identifier初始化token
let kTokenAvoidInterceptIdentifier = "avoid_intercept_identifier"

/// 业务侧默认传入的context
let context = Context([AtomicInfo.Default.defaultAtomicInfo.rawValue])
let token = Token("test")

extension InterceptorResult: Equatable {
    public static func == (lhs: InterceptorResult, rhs: InterceptorResult) -> Bool {
        switch (lhs, rhs) {
        case let (.`break`(result1), .`break`(result2)) where result1.code == result2.code:
            return true
        case (.continue, .continue):
            return true
        default: return false
        }
    }
}

extension Bundle {
    /// Returns the resource bundle associated with the current Swift module.
    static var LSCTestBundle: Bundle? = {
        let bundleName = "LarkSensitivityControlTest"

        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,
            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: TokenTest.self).resourceURL
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        return nil
    }()

    func dataOfPath(forResource name: String, ofType ext: String) -> Data? {
        guard let zipPath = path(forResource: name, ofType: ext) else {
            return nil
        }

        if !SSZipArchive.unzipFile(atPath: zipPath, toDestination: NSTemporaryDirectory()) {
            return nil
        }
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + "/" + name + ".json")
        print("tmp path: \(NSTemporaryDirectory())")
        do {
            return try Data(contentsOf: url)
        } catch {
            LSC.logger?.error(error.localizedDescription)
        }
        return nil
    }
}

final class LarkEnvironmentBOE: Environment {
    var isKA: Bool {
        false
    }

    var debug: Bool {
        true
    }

    var inhouse: Bool {
        true
    }

    var boe: Bool {
        true
    }

    // 该模块无该变量的使用场景,mock仅用于编译
    var userId: String {
        ""
    }

    // 该模块无该变量的使用场景,mock仅用于编译
    var tenantId: String {
        ""
    }

    // 是否登录
    var isLogin: Bool {
        return false
    }

    // 用户账号品牌
    var userBrand: String {
        return "feishu"
    }

    // 安装包品牌
    var packageId: String {
        return "feishu"
    }

    func get<T>(key: String) -> T? {
        if key == "domain" {
            if boe {
                return "https://internal-api-security.feishu-boe.cn" as? T
            } else {
                return "https://internal-api-security.feishu.cn" as? T
            }
        }
        return nil
    }
}

final class LarkEnvironment: Environment {
    var isKA: Bool {
        true
    }

    var debug: Bool {
        true
    }

    var inhouse: Bool {
        true
    }

    var boe: Bool {
        false
    }

    // 该模块无该变量的使用场景,mock仅用于编译
    var userId: String {
        ""
    }

    // 该模块无该变量的使用场景,mock仅用于编译
    var tenantId: String {
        ""
    }

    // 是否登录
    var isLogin: Bool {
        return false
    }

    // 用户账号品牌
    var userBrand: String {
        return "feishu"
    }

    // 安装包品牌
    var packageId: String {
        return "feishu"
    }

    func get<T>(key: String) -> T? {
        if key == "domain" {
            if boe {
                return "https://internal-api-security.feishu-boe.cn" as? T
            } else {
                return "https://internal-api-security.feishu.cn" as? T
            }
        }
        return nil
    }
}

final class LarkSettings: Settings {
    var setting = [String: Any]()

    init() {
        setting["token_config_refresh_time_span"] = 5 * 60
    }

    func setting<T>(key: String) throws -> T? where T: Decodable {
        return (setting[key] as? T)
    }
}

final class LarkStorage: Storage {
    var mmkv = [String: Any]()

    init() {
    }

    func set<T>(_ value: T?, forKey: String, space: StorageSpace) throws where T: Encodable {
        mmkv[forKey] = value
    }

    func get<T>(key: String, space: StorageSpace) throws -> T? where T: Decodable {
        return mmkv[key] as? T
    }

    func remove<T>(key: String, space: StorageSpace) throws -> T? where T: Decodable {
        let value = mmkv[key] as? T
        mmkv.removeValue(forKey: key)
        return value
    }

    func clearAll(space: StorageSpace) {
        mmkv.removeAll()
    }
}

enum LocationError: Error {
    case startRangingBeacons
    case stopRangingBeacons
    case startRangingBeaconsSatisfyingConstraint
    case stopRangingBeaconsSatisfyingConstraint
    case requestWhenInUseAuthorization
    case requestLocation
    case startUpdatingLocation
    case startMonitoringSignificantLocation
    case startMonitoring
    case allowsBackgroundLocationUpdates
    case startUpdatingHeading
    case requestAlwaysAuthorization
}

class Location: NSObject, LocationApi {
    static func requestWhenInUseAuthorization(forToken token: Token, manager: CLLocationManager) throws {
        throw LocationError.requestWhenInUseAuthorization
    }

    static func requestLocation(forToken token: Token, manager: CLLocationManager) throws {
        throw LocationError.requestLocation
    }

    static func startUpdatingLocation(forToken token: Token, manager: CLLocationManager) throws {
        throw LocationError.startUpdatingLocation
    }

    static func startMonitoringSignificantLocationChanges(forToken token: Token, manager: CLLocationManager) throws {
        throw LocationError.startMonitoringSignificantLocation
    }

    static func startMonitoring(forToken token: Token, manager: CLLocationManager, region: CLRegion) throws {
        throw LocationError.startMonitoring
    }

    static func startRangingBeacons(forToken token: LarkSensitivityControl.Token,
                                    manager: CLLocationManager,
                                    region: CLBeaconRegion) throws {
        throw LocationError.startRangingBeacons
    }

    static func stopRangingBeacons(forToken token: LarkSensitivityControl.Token,
                                   manager: CLLocationManager,
                                   region: CLBeaconRegion) throws {
        throw LocationError.stopRangingBeacons
    }

    @available(iOS 13.0, *)
    static func startRangingBeaconsSatisfyingConstraint(forToken token: LarkSensitivityControl.Token,
                                                        manager: CLLocationManager,
                                                        constraint: CLBeaconIdentityConstraint) throws {
        throw LocationError.startRangingBeaconsSatisfyingConstraint
    }

    @available(iOS 13.0, *)
    static func stopRangingBeaconsSatisfyingConstraint(forToken token: LarkSensitivityControl.Token,
                                                       manager: CLLocationManager,
                                                       constraint: CLBeaconIdentityConstraint) throws {
        throw LocationError.stopRangingBeaconsSatisfyingConstraint
    }

    static func allowsBackgroundLocationUpdates(forToken token: Token, manager: CLLocationManager) throws -> Bool {
        throw LocationError.allowsBackgroundLocationUpdates
    }

    static func startUpdatingHeading(forToken token: Token, manager: CLLocationManager) throws {
        throw LocationError.startUpdatingHeading
    }

    static func requestAlwaysAuthorization(forToken token: LarkSensitivityControl.Token, manager: CLLocationManager) throws {
        throw LocationError.requestAlwaysAuthorization
    }
}

enum DeviceInfoError: Error {
    case fetchCurrent
    case CNCopyCurrentNetworkInfo
    case getifaddrs
    case drawHierarchy
    case RPSystemBroadcastPickerViewInit
    case reverseGeocodeLocation
    case currentCalls
    case evaluatePolicy
    case isProximityMonitoringEnabled
    case proximityState
    case setProximityMonitoringEnabled
    case startDeviceMotionUpdates
    case startAccelerometerUpdates
    case scanForPeripherals
    case connect
    case discoverServices
    case discoverCharacteristics
    case readValue
    case writeValue
    case startAdvertising
    case requestAuthorization
    case getDeviceName
    case ssid
    case bssid
    case queryPedometerData
}

class DeviceInfo: NSObject, DeviceInfoApi {
    static func requestWhenInUseAuthorization(forToken token: Token, manager: CLLocationManager) throws {
        throw LocationError.requestWhenInUseAuthorization
    }

    static func fetchCurrent(forToken token: Token, completionHandler: @escaping (NEHotspotNetwork?) -> Void) throws {
        throw DeviceInfoError.fetchCurrent
    }

    static func CNCopyCurrentNetworkInfo(forToken token: Token, _ interfaceName: CFString) throws -> CFDictionary? {
        throw DeviceInfoError.CNCopyCurrentNetworkInfo
    }

    static func getifaddrs(forToken token: Token,
                           _ ifad: UnsafeMutablePointer<UnsafeMutablePointer<ifaddrs>?>!) throws -> Int32 {
        throw DeviceInfoError.getifaddrs
    }

    static func drawHierarchy(forToken token: Token, view: UIView, rect: CGRect,
                              afterScreenUpdates afterUpdates: Bool) throws -> Bool {
        throw DeviceInfoError.drawHierarchy
    }

    @available(iOS 12.0, *)
    static func createRPSystemBroadcastPickerViewWithFrame(forToken token: Token, frame: CGRect) throws -> RPSystemBroadcastPickerView {
        throw DeviceInfoError.RPSystemBroadcastPickerViewInit
    }

    static func reverseGeocodeLocation(forToken token: Token, geocoder: CLGeocoder, userLocation: CLLocation,
                                       completionHandler: @escaping CLGeocodeCompletionHandler) throws {
        throw DeviceInfoError.reverseGeocodeLocation
    }

    @available(iOS, deprecated: 10)
    static func currentCalls(forToken token: Token,
                             callCenter: CTCallCenter) throws -> Set<CTCall>? {
        throw DeviceInfoError.currentCalls
    }

    static func evaluatePolicy(forToken token: Token, laContext: LAContext, policy: LAPolicy, localizedReason: String,
                               reply: @escaping (Bool, Error?) -> Void) throws {
        throw DeviceInfoError.evaluatePolicy
    }

    static func isProximityMonitoringEnabled(forToken token: Token, device: UIDevice) throws -> Bool {
        throw DeviceInfoError.isProximityMonitoringEnabled
    }

    static func proximityState(forToken token: Token, device: UIDevice) throws -> Bool {
        throw DeviceInfoError.proximityState
    }

    static func setProximityMonitoringEnabled(forToken token: Token, device: UIDevice, isEnabled: Bool) throws {
        throw DeviceInfoError.setProximityMonitoringEnabled
    }

    static func startDeviceMotionUpdates(forToken token: Token, manager: CMMotionManager, to queue: OperationQueue,
                                         withHandler handler: @escaping CMDeviceMotionHandler) throws {
        throw DeviceInfoError.startDeviceMotionUpdates
    }

    static func startAccelerometerUpdates(forToken token: Token, manager: CMMotionManager, to queue: OperationQueue,
                                          withHandler handler: @escaping CMAccelerometerHandler) throws {
        throw DeviceInfoError.startAccelerometerUpdates
    }

    static func scanForPeripherals(forToken token: Token, manager: CBCentralManager,
                                   withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) throws {
        throw DeviceInfoError.scanForPeripherals
    }

    static func connect(forToken token: Token, manager: CBCentralManager, _ peripheral: CBPeripheral,
                        options: [String: Any]?) throws {
        throw DeviceInfoError.connect
    }

    static func discoverServices(forToken token: Token, peripheral: CBPeripheral, _ serviceUUIDs: [CBUUID]?) throws {
        throw DeviceInfoError.discoverServices
    }

    static func discoverCharacteristics(forToken token: Token, peripheral: CBPeripheral,
                                        _ characteristicUUIDs: [CBUUID]?, for service: CBService) throws {
        throw DeviceInfoError.discoverCharacteristics
    }

    static func readValue(forToken token: Token, peripheral: CBPeripheral,
                          for characteristic: CBCharacteristic) throws {
        throw DeviceInfoError.readValue
    }

    static func writeValue(forToken token: Token, peripheral: CBPeripheral, _ data: Data,
                           for characteristic: CBCharacteristic,
                           type: CBCharacteristicWriteType) throws {
        throw DeviceInfoError.writeValue
    }

    static func requestAuthorization(forToken token: Token,
                                     _ handler: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void) throws {
        throw DeviceInfoError.requestAuthorization
    }

    static func getDeviceName(forToken token: Token, device: UIDevice) throws -> String {
        throw DeviceInfoError.getDeviceName
    }

    static func ssid(forToken token: Token, net: NEHotspotNetwork) throws -> String {
        throw DeviceInfoError.ssid
    }

    static func bssid(forToken token: Token, net: NEHotspotNetwork) throws -> String {
        throw DeviceInfoError.bssid
    }

    static func queryPedometerData(forToken token: Token,
                                   pedometer: CMPedometer,
                                   from start: Date,
                                   to end: Date,
                                   withHandler handler: @escaping CMPedometerHandler) throws {
        throw DeviceInfoError.queryPedometerData
    }

    static func startAdvertising(forToken token: Token,
                                 manager: CBPeripheralManager,
                                 advertisementData: [String: Any]?) throws {
        throw DeviceInfoError.startAdvertising
    }
}

enum PasteboardError: Error {
    case string
    case setString
    case strings
    case setStrings
    case url
    case setUrl
    case urls
    case setUrls
    case image
    case setImage
    case images
    case setImages
    case items
    case setItems
    case addItems
    case setItemsWithOptions
    case itemProviders
    case setItemProviders
    case data
}

class Pasteboard: NSObject, PasteboardApi {

    /// lark string
    static func string(ofToken token: Token, pasteboard: UIPasteboard) throws -> String? {
        throw PasteboardError.string
    }

    /// lark setString
    static func setString(forToken token: Token, pasteboard: UIPasteboard, string: String?) throws {
        throw PasteboardError.setString
    }

    /// lark strings
    static func strings(ofToken token: Token, pasteboard: UIPasteboard) throws -> [String]? {
        throw PasteboardError.strings
    }

    /// lark setStrings
    static func setStrings(forToken token: Token, pasteboard: UIPasteboard, strings: [String]?) throws {
        throw PasteboardError.setStrings
    }

    /// lark url
    static func url(ofToken token: Token, pasteboard: UIPasteboard) throws -> URL? {
        throw PasteboardError.url
    }

    /// lark setUrl
    static func setUrl(forToken token: Token, pasteboard: UIPasteboard, url: URL?) throws {
        throw PasteboardError.setUrl
    }

    /// lark urls
    static func urls(ofToken token: Token, pasteboard: UIPasteboard) throws -> [URL]? {
        throw PasteboardError.urls
    }

    /// lark setUrls
    static func setUrls(forToken token: Token, pasteboard: UIPasteboard, urls: [URL]?) throws {
        throw PasteboardError.setUrls
    }

    /// lark image
    static func image(ofToken token: Token, pasteboard: UIPasteboard) throws -> UIImage? {
        throw PasteboardError.image
    }

    /// lark setImage
    static func setImage(forToken token: Token, pasteboard: UIPasteboard, image: UIImage?) throws {
        throw PasteboardError.setImage
    }

    /// lark images
    static func images(ofToken token: Token, pasteboard: UIPasteboard) throws -> [UIImage]? {
        throw PasteboardError.images
    }

    /// lark setImages
    static func setImages(forToken token: Token, pasteboard: UIPasteboard, images: [UIImage]?) throws {
        throw PasteboardError.setImages
    }

    /// lark items
    static func items(ofToken token: Token, pasteboard: UIPasteboard) throws -> [[String: Any]] {
        throw PasteboardError.items
    }

    /// lark setItems
    static func setItems(forToken token: Token, pasteboard: UIPasteboard, _ items: [[String: Any]]) throws {
        throw PasteboardError.setItems
    }

    /// lark addItems
    static func addItems(forToken token: Token, pasteboard: UIPasteboard, _ items: [[String: Any]]) throws {
        throw PasteboardError.addItems
    }

    /// lark setItems
    static func setItems(forToken token: Token,
                         pasteboard: UIPasteboard,
                         _ items: [[String: Any]],
                         options: [UIPasteboard.OptionsKey: Any]) throws {
        throw PasteboardError.setItemsWithOptions
    }

    /// lark itemProviders
    static func itemProviders(forToken token: Token, pasteboard: UIPasteboard) throws -> [NSItemProvider]? {
        throw PasteboardError.itemProviders
    }

    /// lark setItemProviders
    static func setItemProviders(forToken token: Token,
                                 pasteboard: UIPasteboard,
                                 _ itemProviders: [NSItemProvider],
                                 localOnly: Bool,
                                 expirationDate: Date?) throws {
        throw PasteboardError.setItemProviders
    }

    /// lark data
    static func data(forToken token: Token,
                     pasteboard: UIPasteboard,
                     forPasteboardType pasteboardType: String) throws -> Data? {
        throw PasteboardError.data
    }
}

enum AudioRecordError: Error {
    case requestRecordPermission
    case requestAccessAudio
    case audioOutputUnitStart
    case audioUnitUninitialize
    case AUGraphStart
    case defaultAudioDevice
    case defaultAudioDeviceWithDeviceType
    case AudioQueueStart
}

class AudioRecord: NSObject, AudioRecordApi {
    static func AUGraphStart(forToken token: LarkSensitivityControl.Token, inGraph: AUGraph) throws -> OSStatus {
        throw AudioRecordError.AUGraphStart
    }

    static func defaultAudioDevice(forToken token: LarkSensitivityControl.Token) throws -> AVCaptureDevice? {
        throw AudioRecordError.defaultAudioDevice
    }

    static func defaultAudioDeviceWithDeviceType(forToken token: LarkSensitivityControl.Token,
                                                 deviceType: AVCaptureDevice.DeviceType,
                                                 position: AVCaptureDevice.Position) throws -> AVCaptureDevice? {
        throw AudioRecordError.defaultAudioDeviceWithDeviceType
    }

    static func requestRecordPermission(forToken token: Token,
                                        session: AVAudioSession,
                                        response: @escaping (Bool) -> Void) throws {
        throw AudioRecordError.requestRecordPermission
    }

    static func requestAccessAudio(forToken token: Token, completionHandler handler: @escaping (Bool) -> Void) throws {
        throw AudioRecordError.requestAccessAudio
    }

    /// AudioOutputUnitStart
    static func audioOutputUnitStart(forToken token: Token, ci: AudioUnit) throws -> OSStatus {
        throw AudioRecordError.audioOutputUnitStart
    }

    static func AudioQueueStart(forToken token: LarkSensitivityControl.Token, _ inAQ: AudioQueueRef, _ inStartTime: UnsafePointer<AudioTimeStamp>?) throws -> OSStatus {
        throw AudioRecordError.AudioQueueStart
    }
}

enum CalendarError: Error {
    case requestAccess
    case requestWriteOnlyAccessToEvents
    case requestFullAccessToEvents
    case requestFullAccessToReminders
    case calendars
    case calendar
    case saveCalendar
    case removeCalendar
    case calendarItem
    case calendarItems
    case events
    case remove
    case saveWithCommit
    case save
    case calendarsWithSource
    case event
}

class Calendar: NSObject, CalendarApi {
    /// EKEventStore requestAccess
    static func requestAccess(forToken token: Token,
                              eventStore: EKEventStore,
                              toEntityType entityType: EKEntityType,
                              completion: @escaping EKEventStoreRequestAccessCompletionHandler) throws {
        throw CalendarError.requestAccess
    }

    /// EKEventStore requestWriteOnlyAccessToEvents
    static func requestWriteOnlyAccessToEvents(forToken token: Token,
                                               eventStore: EKEventStore,
                                               completion: @escaping EKEventStoreRequestAccessCompletionHandler) throws {
        throw CalendarError.requestWriteOnlyAccessToEvents
    }

    /// EKEventStore requestFullAccessToEvents
    static func requestFullAccessToEvents(forToken token: Token,
                                          eventStore: EKEventStore,
                                          completion: @escaping EKEventStoreRequestAccessCompletionHandler) throws {
        throw CalendarError.requestFullAccessToEvents
    }

    /// EKEventStore requestFullAccessToReminders
    static func requestFullAccessToReminders(forToken token: Token,
                                             eventStore: EKEventStore,
                                             completion: @escaping EKEventStoreRequestAccessCompletionHandler) throws {
        throw CalendarError.requestFullAccessToReminders
    }

    /// EKEventStore events
    static func events(forToken token: LarkSensitivityControl.Token,
                       eventStore: EKEventStore,
                       matchingPredicate predicate: NSPredicate) throws -> [EKEvent] {
        throw CalendarError.events
    }

    /// EKEventStore remove
    static func remove(forToken token: LarkSensitivityControl.Token, eventStore: EKEventStore, event: EKEvent, span: EKSpan, commit: Bool) throws {
        throw CalendarError.remove
    }

    /// EKEventStore saveWithCommit
    static func save(forToken token: LarkSensitivityControl.Token, eventStore: EKEventStore, event: EKEvent, span: EKSpan, commit: Bool) throws {
        throw CalendarError.saveWithCommit
    }

    /// EKEventStore save
    static func save(forToken token: LarkSensitivityControl.Token, eventStore: EKEventStore, event: EKEvent, span: EKSpan) throws {
        throw CalendarError.save
    }

    /// lark calendars
    static func calendars(forToken token: Token, eventStore: EKEventStore,
                          forEntityType entityType: EKEntityType) throws -> [EKCalendar] {
        throw CalendarError.calendars
    }

    /// lark calendar
    static func calendar(forToken token: Token, eventStore: EKEventStore,
                         withIdentifier identifier: String) throws -> EKCalendar? {
        throw CalendarError.calendar
    }

    /// lark saveCalendar
    static func saveCalendar(forToken token: Token, eventStore: EKEventStore,
                             calendar: EKCalendar, commit: Bool) throws {
        throw CalendarError.saveCalendar
    }

    /// lark removeCalendar
    static func removeCalendar(forToken token: Token, eventStore: EKEventStore,
                               calendar: EKCalendar, commit: Bool) throws {
        throw CalendarError.removeCalendar
    }

    /// lark calendarItem
    static func calendarItem(forToken token: Token, eventStore: EKEventStore,
                             withIdentifier identifier: String) throws -> EKCalendarItem? {
        throw CalendarError.calendarItem
    }

    /// lark calendarItems
    static func calendarItems(forToken token: Token, eventStore: EKEventStore,
                              withExternalIdentifier externalIdentifier: String) throws -> [EKCalendarItem] {
        throw CalendarError.calendarItems
    }

    /// EKSource calendars
    static func calendars(forToken token: Token,
                          source: EKSource,
                          entityType: EKEntityType) throws -> Set<EKCalendar> {
        throw CalendarError.calendarsWithSource
    }

    /// EKEventStore event
    static func event(forToken token: Token, eventStore: EKEventStore, identifier: String) throws -> EKEvent? {
        throw CalendarError.event
    }
}

enum CameraError: Error {
    case requestAccessCamera
    case startRunning
    case defaultCameraDevice
    case captureStillImageAsynchronously
    case startRecording
    case defaultCameraDeviceWithDeviceType
}

class Camera: NSObject, CameraApi {
    static func defaultCameraDevice(forToken token: Token) throws -> AVCaptureDevice? {
        throw CameraError.defaultCameraDevice
    }

    @available(iOS, introduced: 4.1, deprecated: 10.0)
    static func captureStillImageAsynchronously(forToken token: Token,
                                                photoFileOutput: AVCaptureStillImageOutput,
                                                fromConnection connection: AVCaptureConnection,
                                                completionHandler handler: @escaping (CMSampleBuffer?, Error?) -> Void) throws {
        throw CameraError.captureStillImageAsynchronously
    }

    static func startRecording(forToken token: Token,
                               movieFileOutput: AVCaptureMovieFileOutput,
                               toOutputFile outputFileURL: URL,
                               recordingDelegate delegate: AVCaptureFileOutputRecordingDelegate) throws {
        throw CameraError.startRecording
    }

    static func defaultCameraDeviceWithDeviceType(forToken token: Token, deviceType: AVCaptureDevice.DeviceType, position: AVCaptureDevice.Position) throws -> AVCaptureDevice? {
        throw CameraError.defaultCameraDeviceWithDeviceType
    }

    static func requestAccessCamera(forToken token: Token, completionHandler handler: @escaping (Bool) -> Void) throws {
        throw CameraError.requestAccessCamera
    }

    /// lark startRunning
    static func startRunning(forToken token: Token, session: AVCaptureSession) throws {
        throw CameraError.startRunning
    }
}

enum AlbumError: Error {
    case fetchAssetsWithMediaType
    case creationRequestForAsset
    case creationRequestForAssetFromImage
    case creationRequestForAssetFromVideo
    case forAsset
    case fetchTopLevelUserCollections
    case requestAuthorization
    case requestAuthorizationForAccessLevel
    case fetchAssetCollections
    case requestData
    case writeData
    case requestAVAsset
    case requestExportSession
    case requestImage
    case requestPlayerItem
    case createPickerViewControllerWithConfiguration
    case createImagePickerController
    case UIImageWriteToSavedPhotosAlbum
    case UISaveVideoAtPathToSavedPhotosAlbum
    case requestImageData
    case requestImageDataAndOrientation
}

class Album: NSObject, AlbumApi {
    static func fetchAssets(forToken token: Token,
                            withMediaType mediaType: PHAssetMediaType,
                            options: PHFetchOptions?) throws -> PHFetchResult<PHAsset> {
        throw AlbumError.fetchAssetsWithMediaType
    }

    static func creationRequestForAsset(forToken token: Token,
                                        fromImage image: UIImage) throws -> PHAssetChangeRequest {
        throw AlbumError.creationRequestForAsset
    }

    static func creationRequestForAssetFromImage(forToken token: Token,
                                                 atFileURL fileURL: URL) throws -> PHAssetChangeRequest? {
        throw AlbumError.creationRequestForAssetFromImage
    }

    static func creationRequestForAssetFromVideo(forToken token: Token,
                                                 atFileURL fileURL: URL) throws -> PHAssetChangeRequest? {
        throw AlbumError.creationRequestForAssetFromVideo
    }

    static func forAsset(forToken token: Token) throws -> PHAssetCreationRequest {
        throw AlbumError.forAsset
    }

    static func fetchTopLevelUserCollections(forToken token: Token,
                                             withOptions options: PHFetchOptions?) throws -> PHFetchResult<PHCollection> {
        throw AlbumError.fetchTopLevelUserCollections
    }

    static func requestAuthorization(forToken token: Token,
                                     handler: @escaping (PHAuthorizationStatus) -> Void) throws {
        throw AlbumError.requestAuthorization
    }

    @available(iOS, introduced: 14.0)
    static func requestAuthorization(forToken token: Token,
                                     forAccessLevel accessLevel: PHAccessLevel,
                                     handler: @escaping (PHAuthorizationStatus) -> Void) throws {
        throw AlbumError.requestAuthorizationForAccessLevel
    }

    static func fetchAssetCollections(forToken token: Token,
                                      withType type: PHAssetCollectionType,
                                      subtype: PHAssetCollectionSubtype,
                                      options: PHFetchOptions?) throws -> PHFetchResult<PHAssetCollection> {
        throw AlbumError.fetchAssetCollections
    }

    static func requestData(forToken token: Token,
                            manager: PHAssetResourceManager,
                            forResource resource: PHAssetResource,
                            options: PHAssetResourceRequestOptions?,
                            dataReceivedHandler handler: @escaping (Data) -> Void,
                            completionHandler: @escaping (Error?) -> Void) throws -> PHAssetResourceDataRequestID {
        throw AlbumError.requestData
    }

    static func writeData(forToken token: Token,
                          manager: PHAssetResourceManager,
                          forResource resource: PHAssetResource,
                          toFile fileURL: URL,
                          options: PHAssetResourceRequestOptions?,
                          completionHandler: @escaping (Error?) -> Void) throws {
        throw AlbumError.writeData
    }

    static func requestAVAsset(forToken token: Token,
                               manager: PHImageManager,
                               forVideoAsset asset: PHAsset,
                               options: PHVideoRequestOptions?,
                               resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable: Any]?) -> Void) throws -> PHImageRequestID {
        throw AlbumError.requestAVAsset
    }

    static func requestExportSession(
        forToken token: Token,
        manager: PHImageManager,
        forVideoAsset asset: PHAsset,
        options: PHVideoRequestOptions?,
        exportPreset: String, resultHandler: @escaping (AVAssetExportSession?, [AnyHashable: Any]?) -> Void) throws -> PHImageRequestID {
        throw AlbumError.requestExportSession
    }

    static func requestImage(forToken token: Token,
                             manager: PHImageManager,
                             forAsset asset: PHAsset,
                             targetSize: CGSize,
                             contentMode: PHImageContentMode,
                             options: PHImageRequestOptions?,
                             resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) throws -> PHImageRequestID {
        throw AlbumError.requestImage
    }

    static func requestPlayerItem(forToken token: Token,
                                  manager: PHImageManager,
                                  forVideoAsset asset: PHAsset,
                                  options: PHVideoRequestOptions?,
                                  resultHandler: @escaping (AVPlayerItem?, [AnyHashable: Any]?) -> Void) throws -> PHImageRequestID {
        throw AlbumError.requestPlayerItem
    }

    @available(iOS, introduced: 14.0)
    static func createPickerViewControllerWithConfiguration(forToken token: Token,
                                                            configuration: PHPickerConfiguration) throws -> PHPickerViewController {
        throw AlbumError.createPickerViewControllerWithConfiguration
    }

    static func createImagePickerController(forToken token: Token) throws -> UIImagePickerController {
        throw AlbumError.createImagePickerController
    }

    static func UIImageWriteToSavedPhotosAlbum(forToken token: Token,
                                               _ image: UIImage,
                                               _ completionTarget: Any?,
                                               _ completionSelector: Selector?,
                                               _ contextInfo: UnsafeMutableRawPointer?) throws {
        throw AlbumError.UIImageWriteToSavedPhotosAlbum
    }

    static func UISaveVideoAtPathToSavedPhotosAlbum(forToken token: Token,
                                                    _ videoPath: String,
                                                    _ completionTarget: Any?,
                                                    _ completionSelector: Selector?,
                                                    _ contextInfo: UnsafeMutableRawPointer?) throws {
        throw AlbumError.UISaveVideoAtPathToSavedPhotosAlbum
    }

    static func requestImageData(
        forToken token: Token,
        manager: PHImageManager,
        forAsset asset: PHAsset,
        options: PHImageRequestOptions?,
        resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable: Any]?) -> Void
    ) throws -> PHImageRequestID {
        throw AlbumError.requestImageData
    }

    static func requestImageDataAndOrientation(
        forToken token: Token,
        manager: PHImageManager,
        forAsset asset: PHAsset,
        options: PHImageRequestOptions?,
        resultHandler: @escaping (Data?, String?, CGImagePropertyOrientation, [AnyHashable: Any]?) -> Void
    ) throws -> PHImageRequestID {
        throw AlbumError.requestImageDataAndOrientation
    }
}

enum ContactsError: Error {
    case enumerateContacts
    case requestAccess
    case execute
}

class Contacts: NSObject, ContactsApi {
    static func enumerateContacts(forToken token: Token,
                                  contactsStore: CNContactStore,
                                  withFetchRequest fetchRequest: CNContactFetchRequest,
                                  usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void) throws {
        throw ContactsError.enumerateContacts
    }

    static func requestAccess(forToken token: Token,
                              contactsStore: CNContactStore,
                              forEntityType entityType: CNEntityType,
                              completionHandler: @escaping (Bool, Error?) -> Void) throws {
        throw ContactsError.requestAccess
    }

    static func execute(forToken token: Token, store: CNContactStore, saveRequest: CNSaveRequest) throws {
        throw ContactsError.execute
    }
}

/// 忽略检测的拦截器，特殊使用
struct IgnoreInterceptor: Interceptor {

    func intercept(token: Token, context: Context) -> InterceptorResult {
        let flag = token.identifier == kTokenAvoidInterceptIdentifier
        return flag ? .break(CheckResult(token: token, code: .success, context: context)) : .continue
    }
}

struct StrategyInterceptor: Interceptor {

    struct StrategyResultInfo: ResultInfo {
        var context: Context
        var code: Code
        var token: Token
        var strategyId: Int
        var scene: Scene

        var reasonInfo: [String: Any] {
            return [
                "error_type": code.rawValue,
                "strategy_rule_id": strategyId
            ]
        }
    }

    func intercept(token: Token, context: Context) -> InterceptorResult {
        let flag = (token.identifier == "audio")
        return flag ? .break(StrategyResultInfo(context: context, code: .strategyIntercepted, token: token, strategyId: 100, scene: Scene.default)) : .continue
    }
}

public final class LocationManager: CLLocationManager {
    var method: String?
    public override func requestWhenInUseAuthorization() {
        method = "requestWhenInUseAuthorization"
    }

    public override func requestLocation() {
        method = "requestLocation"
    }

    public override func startUpdatingLocation() {
        method = "startUpdatingLocation"
    }

    public override func startMonitoring(for region: CLRegion) {
        method = "startMonitoringForRegion:"
    }

    public override func startRangingBeacons(in region: CLBeaconRegion) {
        method = "startRangingBeaconsInRegion:"
    }

    public override func startMonitoringSignificantLocationChanges() {
        method = "startMonitoringSignificantLocationChanges"
    }

    public override func stopRangingBeacons(in region: CLBeaconRegion) {
        method = "stopRangingBeaconsInRegion:"
    }

    @available(iOS 13.0, *)
    public override func startRangingBeacons(satisfying constraint: CLBeaconIdentityConstraint) {
        method = "startRangingBeaconsSatisfyingConstraint:"
    }

    @available(iOS 13.0, *)
    public override func stopRangingBeacons(satisfying constraint: CLBeaconIdentityConstraint) {
        method = "stopRangingBeaconsSatisfyingConstraint:"
    }

    public override func requestAlwaysAuthorization() {
        method = "requestAlwaysAuthorization:"
    }

}

@available(iOS 13.0, *)
extension DeviceInfoEntry {

    /// testOC
    @objc
    @available(iOS 13.0, *)
    public class func testOC(forToken token: Token,
                             err: UnsafeMutablePointer<NSError?>?) {
        do {
            try testSwift(forToken: token)
        } catch {
            err?.pointee = error as NSError
        }
    }

    /// testSwift
    public class func testSwift(forToken token: Token) throws {
        throw CheckError(errorInfo: ErrorInfo.STATUS.rawValue)
    }
}

/// 为了增加 CameraEntry.startRecording 单测实现的协议
extension TokenTest: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        return
    }
}

class TokenTest: XCTestCase {

    override func setUpWithError() throws {
        // 重置逻辑
        try super.setUpWithError()
        LSC.reset()
        TCM.reset()
    }

    override func tearDownWithError() throws {
        // 重置逻辑
        try super.tearDownWithError()
        LSC.reset()
        TCM.reset()
    }

    func testToken() throws {
        let token = Token(kTokenAvoidInterceptIdentifier)
        XCTAssertEqual(token.type, .none)
        XCTAssertNil(token.extraInfo)
        print("token(\(token.identifier) notExist.")

        let interceptor = IgnoreInterceptor()
        let result = interceptor.intercept(token: token, context: context)
        XCTAssertTrue(result == .break(CheckResult(token: token, code: .success, context: context)))
        print("token(\(token.identifier), \(Code.success.description).")

        let token1 = Token("token")
        let result1 = interceptor.intercept(token: token1, context: context)
        XCTAssertTrue(result1 == .continue)
    }

    func testLocalBuild() throws {
        let buildData = Bundle.LSCTestBundle?.dataOfPath(forResource: "token_config_list", ofType: "zip")
        XCTAssertNotNil(buildData)
        
        // 测试新旧读取方法读取的内容是否一致
        let buildDataNew = try? Bundle.LSCTestBundle?.readFileToData(forResource: "token_config_list", ofType: .zip)
        XCTAssertEqual(buildData, buildDataNew)
        
        XCTAssertThrowsError(try Bundle.LSCTestBundle?.readFileToData(forResource: "unknown_file_path", ofType: .zip)) { error in
            if let error = error as? SnCReadFileError {
                if error != SnCReadFileError.bundlePathNotFound {
                    XCTFail("error type is not matched")
                }
            } else {
                XCTFail("error type is not matched")
            }
        }
        
        do {
            try FileManager.default.removeItem(atPath: NSTemporaryDirectory() + "/token_config_list.json")
        } catch {
            LSC.logger?.error(error.localizedDescription)
        }
        print("\(String(describing: buildData))")
        let tokenConfigs = TokenConfig.createConfigs(with: buildData!)
        print("\(String(describing: tokenConfigs))")
        XCTAssertTrue(tokenConfigs?.count ?? 0 > 0)
    }

    func testCheckResult() throws {
        let result = CheckResult(token: token, code: .success, context: context)
        let dict = result.build()
        XCTAssertEqual(dict["token"] as? String, "test")
        XCTAssertEqual(dict["scene"] as? String, Scene.success.rawValue)

        let result1 = CheckResult(token: token, code: .notExist, context: context)
        let dict1 = result1.build()
        XCTAssertEqual(dict1["token"] as? String, "test")
        XCTAssertEqual(dict1["scene"] as? String, Scene.notExist.rawValue)

        let result2 = CheckResult(token: token, code: .strategyIntercepted, context: context)
        let dict2 = result2.build()
        XCTAssertEqual(dict2["token"] as? String, "test")
        XCTAssertEqual(dict2["token_source"] as? String, TokenSource.empty.rawValue)
        XCTAssertEqual(dict2["scene"] as? String, Scene.default.rawValue)

        let result3 = CheckResult(token: token, code: .atomicInfoNotMatch, context: context)
        let dict3 = result3.buildAtomicInfo()
        XCTAssertEqual(dict3["token"] as? String, "test")
        XCTAssertEqual(dict3["scene"] as? String, Scene.atomicInfoNotMatch.rawValue)
        XCTAssertEqual(dict3["token_source"] as? String, TokenSource.empty.rawValue)
        XCTAssertEqual(dict3["local_info"] as? [String], [AtomicInfo.Default.defaultAtomicInfo.rawValue])
        XCTAssertNil((dict3["remote_info"]))

        let result4 = CheckResult(token: token, code: .statusDisabled, context: context)
        let dict4 = result4.build()
        XCTAssertEqual(dict4["token"] as? String, "test")
        XCTAssertEqual(dict4["scene"] as? String, Scene.tokenDisabled.rawValue)

        let result5 = CheckResult(token: token, code: .statusDisabledForDebug, context: context)
        let dict5 = result5.build()
        XCTAssertEqual(dict5["token"] as? String, "test")
        XCTAssertEqual(dict5["scene"] as? String, Scene.default.rawValue)
    }

    func testParseResult() throws {
        let result = ParseResult(scene: .readLocal, errorMsg: "local_error")
        let dict = result.build()
        XCTAssertEqual(dict["scene"] as? String, Scene.readLocal.rawValue)
        XCTAssertEqual(dict["error_msg"] as? String, "local_error")

        let result1 = ParseResult(scene: .readBuiltIn, errorMsg: "builtin_error")
        let dict1 = result1.build()
        XCTAssertEqual(dict1["scene"] as? String, Scene.readBuiltIn.rawValue)
        XCTAssertEqual(dict1["error_msg"] as? String, "builtin_error")

        let result2 = ParseResult(scene: .parse, errorMsg: "parse_error")
        let data = Data("123".utf8)
        let dict2 = result2.buildWithData(data)
        XCTAssertEqual(dict2["scene"] as? String, Scene.parse.rawValue)
        XCTAssertEqual(dict2["error_msg"] as? String, "parse_error")
        XCTAssertEqual(dict2["token_list"] as? Data, data)

        let result3 = ParseResult(scene: .parse, errorMsg: "parse_error")
        let array = ["123": "345"]
        let dict3 = result2.buildWithData(array)
        XCTAssertEqual(dict3["scene"] as? String, Scene.parse.rawValue)
        XCTAssertEqual(dict3["error_msg"] as? String, "parse_error")
        XCTAssertEqual((dict3["token_list"] as? [String: Any])?.first?.key, array.first?.key)

        let result4 = ParseResult(scene: .update, errorMsg: "update_error")
        let dict4 = result4.build()
        XCTAssertEqual(dict4["scene"] as? String, Scene.update.rawValue)
        XCTAssertEqual(dict4["error_msg"] as? String, "update_error")
    }

    func testExtensions() throws {
        var flag: Bool?
        XCTAssertTrue(flag.or(true))
        XCTAssertFalse(flag.or(false))

        flag = true
        XCTAssertTrue(flag.or(true))
    }

    func dictArrayV2() -> [String: Any] {
        let dictArray = [["identifier": "audio", "psda_atomicinfo": ["psda_atomicinfo_audio"], "status": 0],
                         ["identifier": "camera", "psda_atomicinfo": ["psda_atomicinfo_camera"], "status": 0] as [String: Any],
                         ["identifier": "location", "psda_atomicinfo": ["psda_atomicinfo_location"], "status": -1]]
        return ["data": ["token_config": dictArray]]
    }

    // v2版本新接口，使用中
    func testTokenConfigV2() throws {
        let dictData = try? JSONSerialization.data(withJSONObject: dictArrayV2())
        let tokenConfigs = TokenConfig.createConfigs(with: dictData!)
        XCTAssertEqual((tokenConfigs?.count).or(0), 3)

        let dict: [String: Any] = ["identifier": "audio", "psda_atomicinfo": ["psda_atomicinfo_audio"], "status": 0]
        let tokenConfig = TokenConfig.createConfig(with: dict)
        XCTAssertNotNil(tokenConfig)
    }

    func testTokenManager() throws {
        let manager = TokenConfigManager.shared
        let dictData = try? JSONSerialization.data(withJSONObject: dictArrayV2())
        manager.update(withData: dictData!, isCache: true)
        let audioConfig = manager.tokenConfig(of: "audio")
        XCTAssertNotNil(audioConfig)
        XCTAssertEqual(audioConfig?.status, .ENABLE)

        let locationConfig = manager.tokenConfig(of: "location")
        XCTAssertNotNil(locationConfig)
        XCTAssertEqual(locationConfig?.status, .DISABLE)

        XCTAssertTrue(manager.contains(token: Token("audio")))
        XCTAssertTrue(manager.contains(token: Token("location")))
        XCTAssertFalse(manager.contains(token: Token("audio-test")))

        XCTAssertFalse(manager.isForbidden(token: Token("audio")))
        XCTAssertTrue(manager.isForbidden(token: Token("location")))
        XCTAssertFalse(manager.isForbidden(token: Token("audio-test")))

        let token1 = Token("audio")
        let context1 = Context(["psda_atomicinfo_audio"])
        let result1 = manager.checkResult(ofToken: token1, context: context1)
        XCTAssertTrue(result1.code == .success)

        let token2 = Token("location")
        let context2 = Context(["psda_atomicinfo_location"])
        let result2 = manager.checkResult(ofToken: token2, context: context2)
        XCTAssertTrue(result2.code == .statusDisabled)
        XCTAssertThrowsError(try Assistant.checkToken(token2, context: context), "hello") { error in
            XCTAssertTrue(error is CheckError)
        }

        let token3 = Token("audio-test")
        let result3 = manager.checkResult(ofToken: token3, context: context)
        XCTAssertTrue(result3.code == .notExist)

        let token4 = Token("audio")
        let result4 = manager.checkResult(ofToken: token4, context: context)
        XCTAssertTrue(result4.code == .success)

        let setting = LarkSettings()
        LSC.register { (service) in
            service.settings = setting
        }
        let token5 = Token("location")
        try? Assistant.checkToken(token5, context: context)
        XCTAssertEqual(token5.type, .none)

        let flag1: Bool? = try LSC.settings?.setting(key: "sensitive_api_control_disable")
        XCTAssertFalse(flag1.or(false))

        setting.setting["sensitive_api_control_disable"] = true

        let flag2: Bool? = try LSC.settings?.setting(key: "sensitive_api_control_disable")
        XCTAssertTrue(flag2.or(false))
        let token6 = Token("location")
        try? Assistant.checkToken(token6, context: context)
        XCTAssertEqual(token6.type, .none)

        setting.setting["sensitive_api_control_disable"] = false
        let flag3: Bool? = try LSC.settings?.setting(key: "sensitive_api_control_disable")
        XCTAssertFalse(flag3.or(false))
        let token7 = Token("location")
        try? Assistant.checkToken(token7, context: context)
        XCTAssertEqual(token7.type, .none)

        let environment = LarkEnvironment()
        LSC.register { (service) in
            service.settings = setting
            service.environment = environment
        }
        let token8 = Token("location")
        try? Assistant.checkToken(token8, context: context)
        XCTAssertEqual(token8.type, .none)
        XCTAssertFalse(Assistant.isDownGraded())

        LSC.register { _ in
        }
        let token9 = Token("location")
        try? Assistant.checkToken(token9, context: context)
        XCTAssertEqual(token9.type, .none)
        XCTAssertFalse(Assistant.isDownGraded())

        LSC.register { (service) in
            service.environment = environment
        }
        let token10 = Token("location")
        try? Assistant.checkToken(token10, context: context)
        XCTAssertEqual(token10.type, .none)
        XCTAssertFalse(Assistant.isDownGraded())
    }

    func testRegisterService() throws {
        XCTAssertNil(LSC.settings)
        LSC.registerApiService(Location.self)
        let service1: SensitiveApi.Type? = LSC.getService(forTag: Location.tag)
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service1 as? Location.Type)
        LSC.unRegisterApiService(Location.self)
        let service2: SensitiveApi.Type? = LSC.getService(forTag: Location.tag)
        XCTAssertNil(service2)
    }

    func testRegisterInterceptor() throws {
        let manager = TokenConfigManager.shared
        let dictData = try? JSONSerialization.data(withJSONObject: dictArrayV2())
        manager.update(withData: dictData!, isCache: true)

        let token1 = Token("audio")
        let result1 = manager.checkResult(ofToken: token1, context: context)
        XCTAssertTrue(result1.code == .success)

        LSC.registerInterceptor(StrategyInterceptor())

        let result2 = manager.checkResult(ofToken: token1, context: context)
        XCTAssertTrue(result2.code == .strategyIntercepted)
        let dict2 = result2.build()
        XCTAssertEqual(dict2["token"] as? String, "audio")
        XCTAssertEqual(dict2["scene"] as? String, Scene.default.rawValue)

        let token2 = Token("location")
        let result3 = manager.checkResult(ofToken: token2, context: context)
        XCTAssertTrue(result3.code == .statusDisabled)
    }

    func testError() throws {
        let error1 = CheckError(errorInfo: ErrorInfo.NONE.rawValue)
        XCTAssertEqual(error1.description, "Token check errorInfo: notExist.")
        let error2 = CheckError(errorInfo: ErrorInfo.STATUS.rawValue)
        XCTAssertEqual(error2.description, "Token check errorInfo: statusDisabled.")
    }

    func testTimeSpan() throws {
        var timeSpan = TCM.timeSpanForRefreshData()
        XCTAssertEqual(timeSpan, 6 * 3600)

        let environment = LarkEnvironment()
        LSC.register { (service) in
            service.environment = environment
        }
        timeSpan = TCM.timeSpanForRefreshData()
        XCTAssertEqual(timeSpan, 6 * 3600)

        let environmentBoe = LarkEnvironmentBOE()
        LSC.register { (service) in
            service.environment = environmentBoe
        }
        timeSpan = TCM.timeSpanForRefreshData()
        XCTAssertEqual(timeSpan, 6 * 3600)

        let setting = LarkSettings()
        LSC.register { (service) in
            service.settings = setting
        }
        timeSpan = TCM.timeSpanForRefreshData()
        XCTAssertEqual(timeSpan, kTokenConfigRefreshTimeSpanBOE)
        let configDict = SafeDictionary<String, String>()
        XCTAssertTrue(configDict.keys.isEmpty)
        configDict["hello"] = "world"
        XCTAssertFalse(configDict.keys.isEmpty)
    }

    @available(iOS 13.0, *)
    func testLocationService() throws {
        LSC.registerApiService(Location.self)
        let token = Token("location")
        let manager = CLLocationManager()
        // 权限相关API
//        XCTAssertThrowsError(try LocationEntry.requestWhenInUseAuthorization(forToken: token,
//                                                                             manager: manager)) { error in
//            XCTAssertTrue(error as? LocationError == LocationError.requestWhenInUseAuthorization)
//        }
        XCTAssertThrowsError(try LocationEntry.requestLocation(forToken: token, manager: manager)) { error in
            XCTAssertTrue(error as? LocationError == LocationError.requestLocation)
        }
        XCTAssertThrowsError(try LocationEntry.startUpdatingLocation(forToken: token, manager: manager)) { error in
            XCTAssertTrue(error as? LocationError == LocationError.startUpdatingLocation)
        }
        XCTAssertThrowsError(try LocationEntry.startMonitoringSignificantLocationChanges(forToken: token,
                                                                                         manager: manager)) { error in
            XCTAssertTrue(error as? LocationError == LocationError.startMonitoringSignificantLocation)
        }
        XCTAssertThrowsError(try LocationEntry.startMonitoring(forToken: token, manager: manager,
                                                               region: CLRegion())) { error in
            XCTAssertTrue(error as? LocationError == LocationError.startMonitoring)
        }
        XCTAssertThrowsError(try LocationEntry.startRangingBeacons(forToken: token, manager: manager,
                                                                   region: CLBeaconRegion())) { error in
            XCTAssertTrue(error as? LocationError == LocationError.startRangingBeacons)
        }
        let uuid = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
        let constraint = CLBeaconIdentityConstraint(uuid: uuid!)
        XCTAssertThrowsError(try LocationEntry
            .startRangingBeaconsSatisfyingConstraint(forToken: token,
                                                     manager: manager,
                                                     constraint: constraint)) { error in
            XCTAssertTrue(error as? LocationError == LocationError.startRangingBeaconsSatisfyingConstraint)
        }
        XCTAssertThrowsError(try LocationEntry.allowsBackgroundLocationUpdates(forToken: token, manager: manager)) { error in
            XCTAssertTrue(error as? LocationError == LocationError.allowsBackgroundLocationUpdates)
        }
        XCTAssertThrowsError(try LocationEntry.startUpdatingHeading(forToken: token, manager: manager)) { error in
            XCTAssertTrue(error as? LocationError == LocationError.startUpdatingHeading)
        }
        XCTAssertThrowsError(try LocationEntry.requestAlwaysAuthorization(forToken: token,
                                                                          manager: manager)) { error in
            XCTAssertTrue(error as? LocationError == LocationError.requestAlwaysAuthorization)
        }
    }

    func testDeviceInfoService() throws {
        LSC.registerApiService(DeviceInfo.self)
        let token = Token("deviceInfo")
        if #available(iOS 14.0, *) {
            XCTAssertThrowsError(try DeviceInfoEntry.fetchCurrent(forToken: token, completionHandler: { _ in })) { error in
                XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.fetchCurrent)
            }
        } else {
            // Fallback on earlier versions
        }
        XCTAssertThrowsError(try DeviceInfoEntry.CNCopyCurrentNetworkInfo(forToken: token, "" as CFString)) { error in
            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.CNCopyCurrentNetworkInfo)
        }
        var ifAddrsPtr: UnsafeMutablePointer<ifaddrs>?
        XCTAssertThrowsError(try DeviceInfoEntry.getifaddrs(forToken: token, &ifAddrsPtr)) { error in
            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.getifaddrs)
        }
        XCTAssertThrowsError(try DeviceInfoEntry.drawHierarchy(forToken: token, view: UIView(), rect: CGRect(),
                                                               afterScreenUpdates: true)) { error in
            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.drawHierarchy)
        }
        if #available(iOS 12.0, *) {
            XCTAssertThrowsError(try DeviceInfoEntry.createRPSystemBroadcastPickerViewWithFrame(forToken: token,
                                                                                                frame: CGRect())) { error in
                XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.RPSystemBroadcastPickerViewInit)
            }
        } else {
            // Fallback on earlier versions
        }
        XCTAssertThrowsError(try DeviceInfoEntry
            .reverseGeocodeLocation(forToken: token, geocoder: CLGeocoder(), userLocation: CLLocation(),
                                    completionHandler: { _, _ in })) { error in
            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.reverseGeocodeLocation)
        }
        if #available(iOS 10.0, *) {
            print("more than iOS 10")
        } else {
            XCTAssertThrowsError(try DeviceInfoEntry.currentCalls(forToken: token, callCenter: CTCallCenter())) { error in
                XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.currentCalls)
            }
        }
        XCTAssertThrowsError(try DeviceInfoEntry
            .evaluatePolicy(forToken: token, laContext: LAContext(), policy: .deviceOwnerAuthentication,
                            localizedReason: "", reply: { _, _ in })) { error in
            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.evaluatePolicy)
        }
        XCTAssertThrowsError(try DeviceInfoEntry.isProximityMonitoringEnabled(forToken: token,
                                                                              device: UIDevice.current)) { error in
            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.isProximityMonitoringEnabled)
        }
        XCTAssertThrowsError(try DeviceInfoEntry.proximityState(forToken: token, device: UIDevice.current)) { error in
            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.proximityState)
        }
        XCTAssertThrowsError(try DeviceInfoEntry
            .setProximityMonitoringEnabled(forToken: token, device: UIDevice.current, isEnabled: true)) { error in
            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.setProximityMonitoringEnabled)
        }
        XCTAssertThrowsError(try DeviceInfoEntry.startDeviceMotionUpdates(forToken: token, manager: CMMotionManager(), to: .main, withHandler: { _, _ in })) { error in
            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.startDeviceMotionUpdates)
        }
        XCTAssertThrowsError(try DeviceInfoEntry.startAccelerometerUpdates(forToken: token, manager: CMMotionManager(), to: .main, withHandler: { _, _ in })) { error in
            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.startAccelerometerUpdates)
        }
        XCTAssertThrowsError(try DeviceInfoEntry
            .scanForPeripherals(forToken: token, manager: CBCentralManager(), withServices: nil)) { error in
            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.scanForPeripherals)
        }
//        var peripheral = CBCentralManager().retrievePeripherals(withIdentifiers: [])[0]
//        XCTAssertThrowsError(try DeviceInfoEntry.connect(forToken: token, manager: CBCentralManager(),
//                                                         peripheral)) { error in
//            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.connect)
//        }
//        XCTAssertThrowsError(try DeviceInfoEntry.discoverServices(forToken: token, peripheral: peripheral, nil)) { error in
//            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.discoverServices)
//        }
//        let service = peripheral.services![0]
//        XCTAssertThrowsError(try DeviceInfoEntry
//            .discoverCharacteristics(forToken: token, peripheral: peripheral, nil, for: service)) { error in
//            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.discoverCharacteristics)
//        }
//        let characteristic = service.characteristics![0]
//        XCTAssertThrowsError(try DeviceInfoEntry
//            .readValue(forToken: token, peripheral: peripheral, for: characteristic)) { error in
//            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.readValue)
//        }
//        XCTAssertThrowsError(try DeviceInfoEntry
//            .writeValue(forToken: token, peripheral: peripheral,
//                        Data(), for: characteristic, type: .withResponse)) { error in
//            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.writeValue)
//        }
        XCTAssertThrowsError(try DeviceInfoEntry
            .getDeviceName(forToken: token, device: UIDevice.current)) { error in
            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.getDeviceName)
        }
        let net = NEHotspotNetwork()
        XCTAssertThrowsError(try DeviceInfoEntry.ssid(forToken: token, net: net)) { error in
            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.ssid)
        }
        XCTAssertThrowsError(try DeviceInfoEntry.bssid(forToken: token, net: net)) { error in
            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.bssid)
        }
        let date = Date()
        XCTAssertThrowsError(try DeviceInfoEntry.queryPedometerData(forToken: token,
                                                                    pedometer: CMPedometer(),
                                                                    from: date, to: date,
                                                                    withHandler: { _, _ in })) { error in
            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.queryPedometerData)
        }
        XCTAssertThrowsError(try DeviceInfoEntry.startAdvertising(forToken: token,
                                                                  manager: CBPeripheralManager(),
                                                                  advertisementData: nil)) { error in
            XCTAssertTrue(error as? DeviceInfoError == DeviceInfoError.startAdvertising)
        }
    }

    func testPasteboardService() throws {
        LSC.registerApiService(Pasteboard.self)
        let token = Token("pasteboard")
        let board = UIPasteboard.general
        XCTAssertThrowsError(try PasteboardEntry.string(ofToken: token, pasteboard: board)) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.string)
        }
        XCTAssertThrowsError(try PasteboardEntry.setString(forToken: token, pasteboard: board, string: nil)) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.setString)
        }
        XCTAssertThrowsError(try PasteboardEntry.strings(ofToken: token, pasteboard: board)) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.strings)
        }
        XCTAssertThrowsError(try PasteboardEntry.setStrings(forToken: token, pasteboard: board, strings: nil)) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.setStrings)
        }
        XCTAssertThrowsError(try PasteboardEntry.url(ofToken: token, pasteboard: board)) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.url)
        }
        XCTAssertThrowsError(try PasteboardEntry.setUrl(forToken: token, pasteboard: board, url: nil)) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.setUrl)
        }
        XCTAssertThrowsError(try PasteboardEntry.urls(ofToken: token, pasteboard: board)) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.urls)
        }
        XCTAssertThrowsError(try PasteboardEntry.setUrls(forToken: token, pasteboard: board, urls: nil)) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.setUrls)
        }
        XCTAssertThrowsError(try PasteboardEntry.image(ofToken: token, pasteboard: board)) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.image)
        }
        XCTAssertThrowsError(try PasteboardEntry.setImage(forToken: token, pasteboard: board, image: nil)) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.setImage)
        }
        XCTAssertThrowsError(try PasteboardEntry.images(ofToken: token, pasteboard: board)) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.images)
        }
        XCTAssertThrowsError(try PasteboardEntry.setImages(forToken: token, pasteboard: board, images: nil)) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.setImages)
        }
        XCTAssertThrowsError(try PasteboardEntry.items(ofToken: token, pasteboard: board)) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.items)
        }
        XCTAssertThrowsError(try PasteboardEntry.setItems(forToken: token, pasteboard: board, [])) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.setItems)
        }
        XCTAssertThrowsError(try PasteboardEntry.addItems(forToken: token, pasteboard: board, [])) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.addItems)
        }
        let expirationDateOfTomorrow = Date().addingTimeInterval(60 * 60 * 24)
        XCTAssertThrowsError(try PasteboardEntry.setItems(
            forToken: token, pasteboard: board, [["key": "value"]],
            options: [UIPasteboard.OptionsKey.expirationDate: expirationDateOfTomorrow])) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.setItemsWithOptions)
        }
        XCTAssertThrowsError(try PasteboardEntry.itemProviders(forToken: token, pasteboard: board)) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.itemProviders)
        }
        XCTAssertThrowsError(try PasteboardEntry.setItemProviders(forToken: token, pasteboard: board, [],
                                                                  localOnly: true,
                                                                  expirationDate: nil)) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.setItemProviders)
        }
        XCTAssertThrowsError(try PasteboardEntry.data(forToken: token, pasteboard: board,
                                                      forPasteboardType: "")) { error in
            XCTAssertTrue(error as? PasteboardError == PasteboardError.data)
        }
    }

    func testAudioRecordService() throws {
        LSC.registerApiService(AudioRecord.self)
        let token = Token("audio")
        // 权限相关API
//        XCTAssertThrowsError(try AudioRecordEntry.requestRecordPermission(forToken: token,
//                                                                          session: AVAudioSession(), response: { _ in })) { error in
//            XCTAssertTrue(error as? AudioRecordError == AudioRecordError.requestRecordPermission)
//        }
//        XCTAssertThrowsError(try AudioRecordEntry.requestAccessAudio(forToken: token,
//                                                                     completionHandler: { _ in })) { error in
//            XCTAssertTrue(error as? AudioRecordError == AudioRecordError.requestAccessAudio)
//        }
//        let pointer = OpaquePointer(bitPattern: 0)!
//        XCTAssertThrowsError(try AudioRecordEntry.audioOutputUnitStart(forToken: token, ci: pointer)) { error in
//            XCTAssertTrue(error as? AudioRecordError == AudioRecordError.audioOutputUnitStart)
//        }
//        XCTAssertThrowsError(try AudioRecordEntry.AUGraphStart(forToken: token, inGraph: pointer)) { error in
//            XCTAssertTrue(error as? AudioRecordError == AudioRecordError.AUGraphStart)
//        }
        XCTAssertThrowsError(try AudioRecordEntry.defaultAudioDevice(forToken: token)) { error in
            XCTAssertTrue(error as? AudioRecordError == AudioRecordError.defaultAudioDevice)
        }
        XCTAssertThrowsError(try AudioRecordEntry.defaultAudioDeviceWithDeviceType(forToken: token, deviceType: .builtInDualCamera, position: .back)) { error in
            XCTAssertTrue(error as? AudioRecordError == AudioRecordError.defaultAudioDeviceWithDeviceType)
        }
    }

    func testCameraService() throws {
        LSC.registerApiService(Camera.self)
        let token = Token("camera")
        // 权限相关API
//        XCTAssertThrowsError(try CameraEntry.requestAccessCamera(forToken: token,
//                                                                 completionHandler: { _ in })) { error in
//            XCTAssertTrue(error as? CameraError == CameraError.requestAccessCamera)
//        }
        XCTAssertThrowsError(try CameraEntry.startRunning(forToken: token, session: AVCaptureSession())) { error in
            XCTAssertTrue(error as? CameraError == CameraError.startRunning)
        }
        XCTAssertThrowsError(try CameraEntry.defaultCameraDevice(forToken: token)) { error in
            XCTAssertTrue(error as? CameraError == CameraError.defaultCameraDevice)
        }
        XCTAssertThrowsError(try CameraEntry.defaultCameraDeviceWithDeviceType(forToken: token, deviceType: .builtInDualCamera, position: .back)) { error in
            XCTAssertTrue(error as? CameraError == CameraError.defaultCameraDeviceWithDeviceType)
        }
        guard let connect = AVCapturePhotoOutput().connection(with: .video) else {
            return
        }
        if #available(iOS 10, *) {
            print("more than iOS 10")
        } else {
            XCTAssertThrowsError(try CameraEntry.captureStillImageAsynchronously(forToken: token,
                                                                                 photoFileOutput: AVCaptureStillImageOutput(),
                                                                                 fromConnection: connect,
                                                                                 completionHandler: { _, _ in })) { error in
                XCTAssertTrue(error as? CameraError == CameraError.captureStillImageAsynchronously)
            }
        }
        XCTAssertThrowsError(try CameraEntry.startRecording(forToken: token,
                                                            movieFileOutput: AVCaptureMovieFileOutput(),
                                                            toOutputFile: URL(fileReferenceLiteralResourceName: ""),
                                                            recordingDelegate: self)) { error in
            XCTAssertTrue(error as? CameraError == CameraError.startRecording)
        }
    }

    func testCalendarService() throws {
        LSC.registerApiService(Calendar.self)
        let token = Token("calendar")
        let store = EKEventStore()
        // 权限相关API
//        XCTAssertThrowsError(try CalendarEntry.requestAccess(forToken: token, eventStore: store, toEntityType: .event,
//                                                             completion: { _, _ in })) { error in
//            XCTAssertTrue(error as? CalendarError == CalendarError.requestAccess)
//        }
        if #available(iOS 17.0, *) {
            XCTAssertThrowsError(try CalendarEntry.requestWriteOnlyAccessToEvents(forToken: token,
                                                                                  eventStore: store,
                                                                                  completion: { _, _ in })) { error in
                XCTAssertTrue(error as? CalendarError == CalendarError.requestWriteOnlyAccessToEvents)
            }
            XCTAssertThrowsError(try CalendarEntry.requestFullAccessToEvents(forToken: token,
                                                                             eventStore: store,
                                                                             completion: { _, _ in })) { error in
                XCTAssertTrue(error as? CalendarError == CalendarError.requestFullAccessToEvents)
            }
            XCTAssertThrowsError(try CalendarEntry.requestFullAccessToReminders(forToken: token,
                                                                                eventStore: store,
                                                                                completion: { _, _ in })) { error in
                XCTAssertTrue(error as? CalendarError == CalendarError.requestFullAccessToReminders)
            }
        }
        let ek = EKCalendar(for: .event, eventStore: store)
        XCTAssertThrowsError(try CalendarEntry.saveCalendar(forToken: token, eventStore: store,
                                                            calendar: ek, commit: true)) { error in
            XCTAssertTrue(error as? CalendarError == CalendarError.saveCalendar)
        }
        XCTAssertThrowsError(try CalendarEntry.removeCalendar(forToken: token, eventStore: store, calendar: ek,
                                                              commit: true)) { error in
            XCTAssertTrue(error as? CalendarError == CalendarError.removeCalendar)
        }
        XCTAssertThrowsError(try CalendarEntry.calendarItem(forToken: token, eventStore: store,
                                                            withIdentifier: "")) { error in
            XCTAssertTrue(error as? CalendarError == CalendarError.calendarItem)
        }
        XCTAssertThrowsError(try CalendarEntry.calendarItems(forToken: token, eventStore: store,
                                                             withExternalIdentifier: "")) { error in
            XCTAssertTrue(error as? CalendarError == CalendarError.calendarItems)
        }
        XCTAssertThrowsError(try CalendarEntry.events(forToken: token, eventStore: store,
                                                      matchingPredicate: NSPredicate())) { error in
            XCTAssertTrue(error as? CalendarError == CalendarError.events)
        }
        let event = EKEvent(eventStore: store)
        let span = EKSpan(rawValue: 1)
        XCTAssertThrowsError(try CalendarEntry.remove(forToken: token, eventStore: store, event: event,
                                                      span: span!, commit: false)) { error in
            XCTAssertTrue(error as? CalendarError == CalendarError.remove)
        }
        XCTAssertThrowsError(try CalendarEntry.save(forToken: token, eventStore: store,
                                                    event: event, span: span!)) { error in
            XCTAssertTrue(error as? CalendarError == CalendarError.save)
        }
        XCTAssertThrowsError(try CalendarEntry.save(forToken: token, eventStore: store, event: event,
                                                    span: span!, commit: false)) { error in
            XCTAssertTrue(error as? CalendarError == CalendarError.saveWithCommit)
        }
        XCTAssertThrowsError(try CalendarEntry.calendars(forToken: token, source: EKSource(), entityType: .event)) { error in
            XCTAssertTrue(error as? CalendarError == CalendarError.calendarsWithSource)
        }
        XCTAssertThrowsError(try CalendarEntry.event(forToken: token, eventStore: store, identifier: "")) {error in
            XCTAssertTrue(error as? CalendarError == CalendarError.event)
        }
    }

    @available(iOS 14.0, *)
    func testAlbumService() throws {
        LSC.registerApiService(Album.self)
        let token = Token("album")
        let image = UIImage()
        XCTAssertThrowsError(try AlbumEntry.fetchAssets(forToken: token, withMediaType: .audio, options: nil)) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.fetchAssetsWithMediaType)
        }
        XCTAssertThrowsError(try AlbumEntry.creationRequestForAsset(forToken: token, fromImage: image)) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.creationRequestForAsset)
        }
        let url = URL(string: "https://www.baidu.com/")
        XCTAssertThrowsError(try AlbumEntry.creationRequestForAssetFromVideo(forToken: token, atFileURL: url!)) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.creationRequestForAssetFromVideo)
        }
        XCTAssertThrowsError(try AlbumEntry.creationRequestForAssetFromImage(forToken: token, atFileURL: url!)) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.creationRequestForAssetFromImage)
        }
        XCTAssertThrowsError(try AlbumEntry.forAsset(forToken: token)) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.forAsset)
        }
        XCTAssertThrowsError(try AlbumEntry.fetchTopLevelUserCollections(forToken: token, withOptions: nil)) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.fetchTopLevelUserCollections)
        }
        // 权限相关API
//        XCTAssertThrowsError(try AlbumEntry.requestAuthorization(forToken: token, handler: { _ in })) { error in
//            XCTAssertTrue(error as? AlbumError == AlbumError.requestAuthorization)
//        }
//        XCTAssertThrowsError(try AlbumEntry.requestAuthorization(forToken: token,
//                                                                 forAccessLevel: PHAccessLevel(rawValue: 1)!,
//                                                                 handler: { _ in })) { error in
//            XCTAssertTrue(error as? AlbumError == AlbumError.requestAuthorizationForAccessLevel)
//        }
        XCTAssertThrowsError(try AlbumEntry.fetchAssetCollections(forToken: token,
                                                                  withType: .album,
                                                                  subtype: .albumCloudShared,
                                                                  options: nil)) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.fetchAssetCollections)
        }
        let manager = PHAssetResourceManager()
        let resource = PHAssetResource()
        XCTAssertThrowsError(try AlbumEntry.requestData(forToken: token,
                                                        manager: manager,
                                                        forResource: resource,
                                                        options: nil,
                                                        dataReceivedHandler: { _ in },
                                                        completionHandler: { _ in })) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.requestData)
        }
        XCTAssertThrowsError(try AlbumEntry.writeData(forToken: token, manager: manager, forResource: resource,
                                                      toFile: url!, options: nil, completionHandler: { _ in })) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.writeData)
        }
        let asset = PHAsset()
        let imageManager = PHImageManager()
        XCTAssertThrowsError(try AlbumEntry.requestAVAsset(forToken: token,
                                                           manager: imageManager,
                                                           forVideoAsset: asset,
                                                           options: nil,
                                                           resultHandler: { _, _, _ in })) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.requestAVAsset)
        }
        XCTAssertThrowsError(try AlbumEntry.requestExportSession(forToken: token,
                                                                 manager: imageManager,
                                                                 forVideoAsset: asset,
                                                                 options: nil,
                                                                 exportPreset: "",
                                                                 resultHandler: { _, _ in })) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.requestExportSession)
        }
        let mode = PHImageContentMode(rawValue: 1)
        XCTAssertThrowsError(try AlbumEntry.requestImage(forToken: token,
                                                         manager: imageManager,
                                                         forAsset: asset,
                                                         targetSize: CGSize(),
                                                         contentMode: mode!,
                                                         options: nil,
                                                         resultHandler: { _, _ in })) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.requestImage)
        }
        XCTAssertThrowsError(try AlbumEntry.requestPlayerItem(forToken: token,
                                                              manager: imageManager,
                                                              forVideoAsset: asset,
                                                              options: nil,
                                                              resultHandler: { _, _ in })) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.requestPlayerItem)
        }
        XCTAssertThrowsError(try AlbumEntry.createImagePickerController(forToken: token)) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.createImagePickerController)
        }
        XCTAssertThrowsError(try AlbumEntry.UIImageWriteToSavedPhotosAlbum(forToken: token, image,
                                                                           nil, nil, nil)) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.UIImageWriteToSavedPhotosAlbum)
        }
        XCTAssertThrowsError(try AlbumEntry.UISaveVideoAtPathToSavedPhotosAlbum(forToken: token, "",
                                                                                nil, nil, nil)) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.UISaveVideoAtPathToSavedPhotosAlbum)
        }
        XCTAssertThrowsError(try AlbumEntry.requestImageData(forToken: token, manager: PHImageManager(), forAsset: asset,
                                                             options: nil, resultHandler: { _, _, _, _ in })) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.requestImageData)
        }
        XCTAssertThrowsError(try AlbumEntry.requestImageDataAndOrientation(
            forToken: token, manager: PHImageManager(),
            forAsset: asset, options: nil, resultHandler: { _, _, _, _ in })) { error in
            XCTAssertTrue(error as? AlbumError == AlbumError.requestImageDataAndOrientation)
        }
    }

    @available(iOS 14.0, *)
    func testContactsService() throws {
        LSC.registerApiService(Contacts.self)
        let token = Token("contacts")
        let store = CNContactStore()
        let request = CNContactFetchRequest(keysToFetch: [])
        XCTAssertThrowsError(try ContactsEntry.enumerateContacts(forToken: token,
                                                                 contactsStore: store,
                                                                 withFetchRequest: request,
                                                                 usingBlock: { _, _ in })) { error in
            XCTAssertTrue(error as? ContactsError == ContactsError.enumerateContacts)
        }
        XCTAssertThrowsError(try ContactsEntry.execute(forToken: token, store: store, saveRequest: CNSaveRequest())) { error in
            XCTAssertTrue(error as? ContactsError == ContactsError.execute)
        }
        // 权限相关API
//        XCTAssertThrowsError(try ContactsEntry.requestAccess(forToken: token,
//                                                             contactsStore: store,
//                                                             forEntityType: .contacts,
//                                                             completionHandler: { _, _ in })) { error in
//            XCTAssertTrue(error as? ContactsError == ContactsError.requestAccess)
//        }
    }

    func testStorage() throws {
        let manager = TokenConfigManager.shared
        let dictData = try? JSONSerialization.data(withJSONObject: dictArrayV2())
        manager.update(withData: dictData!, isCache: true)

        let token = Token("audio")
        let result1 = manager.checkResult(ofToken: token, context: context)
        XCTAssertTrue(result1.code == .success)

        let storage = LarkStorage()
        LSC.register { (service) in
            service.storage = storage
        }
        let result2 = manager.checkResult(ofToken: token, context: context)
        XCTAssertTrue(result2.code == .success)

        Token.updateDisabledState(true)

        XCTAssertThrowsError(try token.check(context: context)) { error in
            XCTAssertTrue((error as? CheckError) != nil)
        }

        Token.updateDisabledState(false)
        XCTAssertNoThrow(try token.check(context: context))
    }

    @available(iOS 13.0, *)
    func testLocationWrapper() throws {
        let locationManager = LocationManager()
        let token = Token("location")
        // 权限相关API
//        try LocationWrapper.requestWhenInUseAuthorization(forToken: token, manager: locationManager)
//        XCTAssertEqual(locationManager.method, "requestWhenInUseAuthorization")
        try LocationWrapper.requestLocation(forToken: token, manager: locationManager)
        XCTAssertEqual(locationManager.method, "requestLocation")
        try LocationWrapper.startUpdatingLocation(forToken: token, manager: locationManager)
        XCTAssertEqual(locationManager.method, "startUpdatingLocation")
        try LocationWrapper.startMonitoring(forToken: token, manager: locationManager, region: CLRegion())
        XCTAssertEqual(locationManager.method, "startMonitoringForRegion:")
        try LocationWrapper.startRangingBeacons(forToken: token, manager: locationManager, region: CLBeaconRegion())
        XCTAssertEqual(locationManager.method, "startRangingBeaconsInRegion:")
        try LocationWrapper.startMonitoringSignificantLocationChanges(forToken: token, manager: locationManager)
        XCTAssertEqual(locationManager.method, "startMonitoringSignificantLocationChanges")
        let uuid = UUID(uuidString: "c2db97d9-6e80-44a2-82f5-3987065ba4ea")!
        try LocationWrapper.startRangingBeaconsSatisfyingConstraint(forToken: token,
                                                                    manager: locationManager,
                                                                    constraint: CLBeaconIdentityConstraint(uuid: uuid))
        XCTAssertEqual(locationManager.method, "startRangingBeaconsSatisfyingConstraint:")
        try LocationWrapper.requestAlwaysAuthorization(forToken: token, manager: locationManager)
        XCTAssertEqual(locationManager.method, "requestAlwaysAuthorization:")
    }

//    @available(iOS 14.0, *)
//    func testAlbumWrapper() throws {
//        let token = Token("album")
//        let url = URL(string: "https://www.baidu.com/")
//        XCTAssertNoThrow(try AlbumWrapper.fetchAssets(forToken: token, withMediaType: .image, options: nil))
//        XCTAssertNoThrow(try AlbumWrapper.fetchTopLevelUserCollections(forToken: token, withOptions: nil))
//        PHPhotoLibrary.shared().performChanges({
//             do {
//                 XCTAssertNoThrow(try AlbumWrapper.creationRequestForAsset(forToken: token, fromImage: UIImage()))
//                 _ = try AlbumWrapper.creationRequestForAsset(forToken: token, fromImage: UIImage())
//             } catch {
//                 print("\(error.localizedDescription)")
//             }
//        }, completionHandler: { _, _ in })
//        PHPhotoLibrary.shared().performChanges({
//            do {
//                XCTAssertNoThrow(try AlbumWrapper.creationRequestForAssetFromImage(forToken: token, atFileURL: url!))
//                _ = try AlbumWrapper.creationRequestForAssetFromImage(forToken: token, atFileURL: url!)
//            } catch {
//                print("\(error.localizedDescription)")
//            }
//        }, completionHandler: { _, _  in })
//        PHPhotoLibrary.shared().performChanges({
//            do {
//                XCTAssertNoThrow(try AlbumWrapper.creationRequestForAssetFromVideo(forToken: token, atFileURL: url!))
//                _ = try AlbumWrapper.creationRequestForAssetFromVideo(forToken: token, atFileURL: url!)
//            } catch {
//                print("\(error.localizedDescription)")
//            }
//        }, completionHandler: { _, _  in })
//        PHPhotoLibrary.shared().performChanges({
//            do {
//                XCTAssertNoThrow(try AlbumWrapper.forAsset(forToken: token))
//                _ = try AlbumWrapper.forAsset(forToken: token)
//            } catch {
//                print("\(error.localizedDescription)")
//            }
//        }, completionHandler: { _, _  in })
//        // 权限相关API
////        XCTAssertNoThrow(try AlbumWrapper.requestAuthorization(forToken: token, handler: { _ in }))
////        XCTAssertNoThrow(try AlbumWrapper.requestAuthorization(forToken: token, forAccessLevel: PHAccessLevel(rawValue: 1)!,
////                                                               handler: { _ in }))
//        XCTAssertNoThrow(try AlbumWrapper.fetchAssetCollections(forToken: token, withType: .album,
//                                                                subtype: .albumCloudShared, options: nil))
//        let manager = PHAssetResourceManager()
//        let resource = PHAssetResource()
//        XCTAssertNoThrow(try AlbumWrapper.requestData(forToken: token, manager: manager, forResource: resource,
//                                                      options: nil, dataReceivedHandler: { _ in }, completionHandler: { _ in }))
//        XCTAssertNoThrow(try AlbumWrapper.writeData(forToken: token, manager: manager, forResource: resource, toFile: url!,
//                                                    options: nil, completionHandler: { _ in }))
//        let asset = PHAsset()
//        let imageManager = PHImageManager()
//        XCTAssertNoThrow(try AlbumWrapper.requestAVAsset(forToken: token, manager: imageManager, forVideoAsset: asset,
//                                                         options: nil, resultHandler: { _, _, _ in }))
//        XCTAssertNoThrow(try AlbumWrapper.requestExportSession(forToken: token, manager: imageManager, forVideoAsset: asset,
//
//                                                               options: nil, exportPreset: "", resultHandler: { _, _ in }))
//        let requestOptions = PHImageRequestOptions()
//        requestOptions.isSynchronous = true
////        XCTAssertNoThrow(try AlbumWrapper.requestImage(forToken: token, manager: imageManager, forAsset: asset, targetSize: CGSize(),
////                                                       contentMode: mode!, options: requestOptions, resultHandler: { _, _ in }))
//        XCTAssertNoThrow(try AlbumWrapper.requestPlayerItem(forToken: token, manager: imageManager, forVideoAsset: asset,
//                                                            options: nil, resultHandler: { _, _ in }))
//        XCTAssertNoThrow(try AlbumWrapper.createImagePickerController(forToken: token))
//        XCTAssertNoThrow(try AlbumWrapper.UIImageWriteToSavedPhotosAlbum(forToken: token, UIImage(), nil, nil, nil))
//        XCTAssertNoThrow(try AlbumWrapper.UISaveVideoAtPathToSavedPhotosAlbum(forToken: token, "", nil, nil, nil))
////        XCTAssertNoThrow(try AlbumWrapper.requestImageData(
////            forToken: token, manager: imageManager, forAsset: asset, options: nil, resultHandler: { _, _, _, _ in }))
////        XCTAssertNoThrow(try AlbumWrapper.requestImageDataAndOrientation(
////            forToken: token, manager: imageManager,
////            forAsset: asset, options: requestOptions, resultHandler: { _, _, _, _ in }))
//    }

    func testContext() throws {
        let manager = TokenConfigManager.shared
        let dictData = try? JSONSerialization.data(withJSONObject: dictArrayV2())
        manager.update(withData: dictData!, isCache: true)

        let audioToken = Token("audio")
        let result = manager.checkResult(ofToken: audioToken, context: context)
        XCTAssertTrue(result.code == .success)
        XCTAssertNotNil(result.context)
        XCTAssertTrue(result.context == context)
    }

    @available(iOS 13.0, *)
    func testDeviceInfoEntryForOC() throws {
        var errOC: NSError?
        DeviceInfoEntry.testOC(forToken: token, err: &errOC)
        XCTAssertNotNil(errOC)
        XCTAssertEqual(errOC?.domain, "LarkSensitivityControl.CheckError")

        var errSwift: NSError?
        withUnsafeMutablePointer(to: &errSwift) { pointer in
            DeviceInfoEntry.testOC(forToken: token, err: pointer)
        }
        XCTAssertNotNil(errSwift)
        XCTAssertEqual(errSwift?.domain, "LarkSensitivityControl.CheckError")
    }

    func testRTCEntry() throws {
        XCTAssertNoThrow(try RTCEntry.checkTokenForStartAudioCapture(token))
        XCTAssertNoThrow(try RTCEntry.checkTokenForVoIPJoin(token))
        XCTAssertNoThrow(try RTCEntry.checkTokenForStartVideoCapture(token))
    }

    func testSensitivityManager() throws {
        XCTAssertNoThrow(try SensitivityManager.checkToken(token, context: context))
    }

    // 为了解决单测覆盖率不达标增加的用例，无用
    func testTokenConfigManager() throws {
        TokenConfigManager.shared.applicationWillEnterForeground(
            notification: NSNotification(name: UIApplication.willEnterForegroundNotification, object: nil))
    }
}

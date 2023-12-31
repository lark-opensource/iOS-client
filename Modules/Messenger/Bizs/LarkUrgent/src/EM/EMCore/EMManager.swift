//
//  EMManager.swift
//  LarkEM
//
//  Created by Saafo on 2021/8/9.
//

import UserNotifications
import Foundation
import UIKit
import CoreLocation
import MediaPlayer
import AVFoundation
import CoreHaptics
import NotificationCenter
import LarkExtensions

// swiftlint:disable all

// MARK: - Internal PB
public struct CheckStatusResponse {
    let active: Bool
    let recordID: Int64?
    let lastSendInfoTime: Date?
    public init(active: Bool, recordID: Int64?, lastSendInfoTime: Date?) {
        self.active = active
        self.recordID = recordID
        self.lastSendInfoTime = lastSendInfoTime
    }
}

public struct PullEMRecordsResponse {
    public struct EMRecord {
        let createTime: Int64
        let active: Bool
        let recordID: Int64
        let deviceID: Int64
        public init(createTime: Int64, active: Bool, recordID: Int64, deviceID: Int64) {
            self.createTime = createTime
            self.active = active
            self.recordID = recordID
            self.deviceID = deviceID
        }
    }
    let records: [EMRecord]
    public init(records: [EMRecord]) {
        self.records = records
    }
}

public struct CancelResponse {
    let recordID: Int64
    let existActiveTask: Bool
    public init(recordID: Int64, existActiveTask: Bool) {
        self.recordID = recordID
        self.existActiveTask = existActiveTask
    }
}

public final class EMRecord {

    public let title: String
    public var active: Bool
    public let id: Int64
    public var handlerCompletion: ((Bool) -> Void)?

    init(emRecord: PullEMRecordsResponse.EMRecord) {
        let timeInterval = TimeInterval(Int(emRecord.createTime))
        let date = Date(timeIntervalSince1970: timeInterval)
        title = Self.dateFormatter.string(from: date)
        active = emRecord.active
        id = emRecord.recordID
    }

    public func cancelHandler() {
        guard active else { return }
        EMManager.shared.network?.cancelRequest(recordID: id) { [weak self] result in
            switch result {
            case .success(let response):
                self?.active = false
                internalLogger?.info("response recordID: \(response.recordID); " +
                                              "current:\(String(describing: EMManager.shared.recordID))")
                if response.recordID == EMManager.shared.recordID {
                    EMManager.shared.active = false
                }
                EMManager.shared.postExistActiveNotification(exist: response.existActiveTask)
                self?.handlerCompletion?(true)
            case .failure:
                self?.handlerCompletion?(false)
            }
        }
    }

    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return dateFormatter
    }()
}

public enum EMError: Int, Error {
    case redundantTask = 311_000
    case authFailed = 311_001
    case alreadyDone = 311_002
    case getDataFailed = 311_003
}

public extension Notification {
    enum EM {
        public static let existActive = Notification(name: Notification.Name(rawValue: "existActiveEMNotification"))
        public static let exist = "existActive"

        public static let authChanged = Notification(name: Notification.Name("EMAuthChanged"))
    }
}

// MARK: - EMManager

public protocol EMManagerNetworkProvider {
    func sendToUser(completion: @escaping (Result<Int64, Error>) -> Void)
    func sendInfo(_ info: Data, completion: @escaping (Result<Date, Error>) -> Void)
    func checkStatus(completion: @escaping (Result<CheckStatusResponse, Error>) -> Void)
    func existActiveRecord(completion: @escaping (Result<Bool, Error>) -> Void)
    func pullRecords(completion: @escaping (Result<PullEMRecordsResponse, Error>) -> Void)
    func cancelRequest(recordID: Int64, completion: @escaping (Result<CancelResponse, Error>) -> Void)
}

public protocol EMManagerStorageProvider {
    func intValue(for key: String) -> Int?
    func set(int value: Int?, for key: String)
    func dateValue(for key: String) -> Date?
    func set(date value: Date?, for key: String)
}

public protocol EMManagerLogProvider: AnyObject {
    func error(_ message: String)
    func info(_ message: String)
}

var internalLogger: EMManagerLogProvider?

public final class EMManager {

    public static var shared: EMManager {
        if let shared = _shared {
            return shared
        } else {
            assertionFailure("应该先用 setup 初始化")
            return EMManager()
        }
    }

    private static var _shared: EMManager?

    public static var isEnabled: Bool {
        _shared != nil
    }

    var network: EMManagerNetworkProvider?

    var storage: EMManagerStorageProvider?

    let volumeService = VolumeService()

    let coffeeService = CoffeeService()

    #if(IS_EM_ENABLE)
    let dataService = DataService()
    #endif

    var recordID: Int64? {
        didSet {
            storage?.set(int: recordID.flatMap(Int.init), for: Key.emRecordID.rawValue)
            internalLogger?.info("recordID changed to \(String(describing: recordID))")
        }
    }

    var lastSentTime: Date? {
        didSet {
            storage?.set(date: lastSentTime, for: Key.emLastSentTime.rawValue)
            internalLogger?.info("lastSentTime changed to \(String(describing: lastSentTime))")
        }
    }

    public enum Cons {
        public static let settingTitle: String = decryptedString("57Sn5oCl6IGU57O76K6w5b2V")
        public static let end = decryptedString("57uT5p2f")
        public static let ended = decryptedString("5bey57uT5p2f")
        public static let ok = decryptedString("5aW955qE")
        public static let auth = decryptedString("5o6I5p2D5aeL57uI5a6a5L2N5p2D6ZmQ")
        public static let detailAuth =
        decryptedString("5o6I5p2D5LmL5ZCO77yM57Sn5oCl6IGU57O75Yqf6IO95pa55Y+v5q2j5bi45L2/55So")
        public static let someError = decryptedString("6YGH5Yiw5LiA5Lqb6Zeu6aKY77yM6K+356iN5ZCO6YeN6K+V")
        public static let offDesc = decryptedString("6K+35Zyo6K6+572u5Lit6LCD5pW05L2N572u5p2D6ZmQ")
        public static let goToAppSetting = decryptedString("5YmN5b6A5bqU55So6K6+572u")
        public static let openAuth =
        decryptedString("6K+35Zyo6K6+572uLeWumuS9jeW8gOWQr+OAjOWni+e7iOOAjeadg+mZkO+8jOW5tuaJk+W8gOOAjOeyvuehruS9jee9ruOAjQ==")
        static let emEnabled = decryptedString("bGFya19jb3JlX2VtX25vdGlmeQ==")
        static let sendInterval: TimeInterval = 5 * 60
        static let retryInterval: TimeInterval = 1 * 60

        static func decryptedString(_ encryptedString: String) -> String {
            String(data: Data(base64Encoded: encryptedString) ?? Data(), encoding: .utf8) ?? ""
        }
    }

    enum Key: String {
        case emState
        case emRecordID
        case emLastSentTime
    }

    public func fetchExistActive() {
        network?.existActiveRecord { [weak self] result in
            switch result {
            case .success(let exist):
                self?.postExistActiveNotification(exist: exist)
            case .failure:
                break
            }
        }

    }

    public func getList(completion: @escaping (Result<[EMRecord], Error>) -> Void) {
        network?.pullRecords { result in
            switch result {
            case .success(let response):
                completion(.success(response.records.map { EMRecord(emRecord: $0) }))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public enum Auth: String {
        case none
        case ask
        case part
        case full
    }

    public var auth: Auth {
        #if(IS_EM_ENABLE)
        var fullAccuracy = true
        if #available(iOS 14, *), dataService.manager.accuracyAuthorization == .reducedAccuracy {
            fullAccuracy = false
        }
        let current = dataService.currentAuth
        if current == .authorizedAlways && fullAccuracy {
            return .full
        } else if current == .authorizedWhenInUse && fullAccuracy {
            return .part
        } else if current == .notDetermined {
            return .ask
        } else {
            return .none
        }
        #else
        return .none
        #endif
    }

    public func request(auth: Auth) {
        #if(IS_EM_ENABLE)
        switch auth {
        case .part, .full:
            dataService.request(auth: auth)
        default:
            break
        }
        #endif
    }

    var active: Bool = false {
        didSet {
            if active {
                startSend()
            } else {
                stopSend()
            }
            internalLogger?.info("active changed to: \(active)")
        }
    }

    public static func setup(networkProvider: EMManagerNetworkProvider,
                             storageProvider: EMManagerStorageProvider,
                             logProvider: EMManagerLogProvider) {
        #if(IS_EM_ENABLE)
        _shared = EMManager()
        shared.network = networkProvider
        shared.storage = storageProvider
        shared.dataService.delegate = shared
        shared.volumeService.delegate = shared
        internalLogger = logProvider

        shared.volumeService.startObserve()

        shared.dataService.request(auth: .full)

        shared.fetchConfig()
        #endif
    }

    public static func destruct() {
        _shared = nil
    }

    func fetchConfig() {
        network?.checkStatus { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                if response.active {
                    self.lastSentTime = response.lastSendInfoTime
                    self.recordID = response.recordID
                    self.active = true
                } else {
                    self.active = false
                }
            case .failure(let error):
                if let error = error as? EMError, error == .authFailed { return }
                self.lastSentTime = self.storage?.dateValue(for: Key.emLastSentTime.rawValue)
                let recordID = self.storage?.intValue(for: Key.emRecordID.rawValue)
                self.recordID = recordID.flatMap(Int64.init)
                self.active = self.recordID != nil
            }
        }
        return
    }

    func startSend() {
        #if(IS_EM_ENABLE)
        coffeeService.startCoffee()
        dataService.startMonitoring()
        if let lastSentTime = lastSentTime {
            let lastTillNow = Date().timeIntervalSince(lastSentTime)
            if lastTillNow < Self.Cons.sendInterval, lastTillNow > 0 {
                dataService.fetchData(after: Self.Cons.sendInterval - lastTillNow)
                return
            }
        }
        dataService.fetchData(after: 0)
        #endif
    }

    func stopSend() {
        #if(IS_EM_ENABLE)
        coffeeService.stopCoffee()
        dataService.stopMonitoring()
        recordID = nil
        lastSentTime = nil
        #endif
    }

    func postExistActiveNotification(exist: Bool) {
        NotificationCenter.default.post(
            name: Notification.EM.existActive.name,
            object: self,
            userInfo: [Notification.EM.exist: exist]
        )
    }
}

extension EMManager: VolumeServiceDelegate {
    func volumeServiceConfirmActive() {
        network?.sendToUser { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let recordID):
                self.active = true
                self.recordID = recordID
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .failure(let error):
                if let error = error as? EMError, error == .redundantTask {
                    self.fetchConfig()
                }
            }
        }
    }
    var volumeServiceWindowCanAppear: Bool {
        (auth == .part || auth == .full) && !active
    }
}

// MARK: - Volume

protocol VolumeServiceDelegate: AnyObject {
    func volumeServiceConfirmActive()
    var volumeServiceWindowCanAppear: Bool { get }
}

final class VolumeService {

    weak var delegate: VolumeServiceDelegate?

    var window: VolumeWindow?

    let observer: VolumeObserver

    var observing: Bool = false

    init() {
        observer = VolumeObserver()
        observer.delegate = self
    }

    func startObserve() {
        observer.startObserve()
        observing = true

        window = VolumeWindow()
        window?.delegate = self
    }

    func stopObserve() {
        observer.stopObserve()
        observing = false

        window?.resignKey()
        window = nil
    }

    private func showVolume() {
        window?.isHidden = false
    }

    private func hideVolume() {
        window?.isHidden = true
    }
}

extension VolumeService: VolumeObserverDelegate {
    func volumeDidPressMinusThreeTimes() {
        if delegate?.volumeServiceWindowCanAppear == true {
            showVolume()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            observer.clearCount()
        }
    }

    func volumeDidPressPlus() {
        hideVolume()
    }
}

protocol VolumeObserverDelegate: AnyObject {
    func volumeDidPressMinusThreeTimes()
    func volumeDidPressPlus()
}

final class VolumeObserver: NSObject {

    private var lastVolume: Float = -1

    private var lastSequence: Int = -1

    private var lastTime: CFTimeInterval = 0

    private var continuousCount = 0 {
        didSet {
            internalLogger?.info("continuousCount: \(continuousCount)")
        }
    }

    private func validate(reason: String, volume: Float, sequence: Int?, time: CFTimeInterval) {
        guard reason == "ExplicitVolumeChange" else { return }
        if volumeWindowIsShowing {
            if volume > lastVolume {
                delegate?.volumeDidPressPlus()
            }
            return
        }
        if volume != lastVolume {
            clearCount()
        } else {
            if volume < 0.5, volume == lastVolume, sequence != lastSequence, time - lastTime > 0.08 {
                continuousCount += 1
            }
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(clearCount), object: nil)
            if continuousCount >= 2 {
                delegate?.volumeDidPressMinusThreeTimes()
            } else {
                perform(#selector(clearCount), with: nil, afterDelay: 0.5)
            }
        }
        lastVolume = volume
        lastSequence = sequence ?? -1
        lastTime = time
    }

    @objc
    func clearCount() {
        lastVolume = -1
        lastSequence = -1
        lastTime = 0
        continuousCount = 0
    }

    var volumeWindowIsShowing: Bool = false {
        didSet {
            if !volumeWindowIsShowing {
                clearCount()
            }
        }
    }

    weak var delegate: VolumeObserverDelegate?

    private var volumeNotiObject: NSObjectProtocol?

    func startObserve() {
        let volumeView = MPVolumeView(frame: .zero)
        UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(volumeView)

        let name: Notification.Name
        let block: (Notification) -> Void
        if #available(iOS 15, *) {
            name = NSNotification.Name(rawValue: "SystemVolumeDidChange")
            block = { [weak self] notification in
                guard Thread.isMainThread,
                      UIApplication.shared.applicationState == .active,
                      let self = self,
                      let info = notification.userInfo,
                      let reason = info["Reason"] as? String,
                      let sequence = info["SequenceNumber"] as? Int,
                      let volume = info["Volume"] as? Float else { return }
                self.validate(reason: reason, volume: volume, sequence: sequence, time: CACurrentMediaTime())
            }
        } else {
            name = NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification")
            block = { [weak self] notification in
                guard Thread.isMainThread,
                      UIApplication.shared.applicationState == .active,
                      let self = self,
                      let info = notification.userInfo,
                      let reason = info["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String,
                      let volume = info["AVSystemController_AudioVolumeNotificationParameter"] as? Float else { return }
                self.validate(reason: reason, volume: volume, sequence: nil, time: CACurrentMediaTime())
            }
        }
        volumeNotiObject = NotificationCenter.default.addObserver(
            forName: name, object: nil, queue: .main, using: block
        )
        volumeView.removeFromSuperview()
    }

    func stopObserve() {
        if let volumeNotiObject = volumeNotiObject {
            NotificationCenter.default.removeObserver(volumeNotiObject)
        }
        volumeNotiObject = nil
    }

    deinit {
        if let volumeNotiObject = volumeNotiObject {
            NotificationCenter.default.removeObserver(volumeNotiObject)
        }
    }
}

extension VolumeService: VolumeWindowDelegate {
    func volumeWindowConfirmActive() {
        delegate?.volumeServiceConfirmActive()
    }

    func volumeWindowDid(hidden: Bool) {
        observer.volumeWindowIsShowing = !hidden
    }
}

protocol VolumeWindowDelegate: AnyObject {
    func volumeWindowConfirmActive()
    func volumeWindowDid(hidden: Bool)
}


final class VolumeWindow: UIWindow {

    weak var delegate: VolumeWindowDelegate?

    let viewController: VolumeVC

    init() {
        viewController = VolumeVC()
        super.init(frame: .zero)
        rootViewController = viewController
        viewController.window = self
        windowLevel = .alert - 1
        isHidden = true
        self.windowIdentifier = "LarkUrgent.VolumeWindow"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHidden: Bool {
        willSet {
            if #available(iOS 13, *), isHidden == true && newValue == false,
               let keyWindow = UIApplication.shared.keyWindow {
                windowScene = keyWindow.windowScene
                frame = keyWindow.bounds
            }
        }
        didSet {
            if oldValue == true && isHidden == false {
                makeKey()
                viewController.startCountDown()
            } else if oldValue == false && isHidden == true {
                viewController.doBeforeHide()
                resignKey()
            }
            delegate?.volumeWindowDid(hidden: isHidden)
            print("Volume window isHidden: \(isHidden)")
        }
    }
}

final class VolumeVC: UIViewController {

    weak var window: VolumeWindow?

    /// @available(iOS 13, *)
    var engine: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        let button = UIButton()
        button.setTitle("取消", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15)

        button.backgroundColor = .black.withAlphaComponent(0.6)
        button.layer.cornerRadius = 20
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: 100),
            button.heightAnchor.constraint(equalToConstant: 40)
        ]
        NSLayoutConstraint.activate(constraints)
        button.addTarget(self, action: #selector(hide), for: .touchUpInside)
        view.backgroundColor = .black.withAlphaComponent(0.4)

        // prepare haptic
        guard #available(iOS 13, *),
              CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            try engine = CHHapticEngine()
        } catch {
            internalLogger?.error("init haptic failed: \(error)")
        }
    }

    func startCountDown() {
        // haptic
        if #available(iOS 13, *), let engine = engine as? CHHapticEngine {
            do {
                let pattern = try CHHapticPattern(events: [
                    CHHapticEvent(eventType: .hapticContinuous,
                                  parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)],
                                  relativeTime: 0,
                                  duration: 0.6),
                    CHHapticEvent(eventType: .hapticContinuous,
                                  parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)],
                                  relativeTime: 1.6,
                                  duration: 0.6),
                    CHHapticEvent(eventType: .hapticContinuous,
                                  parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)],
                                  relativeTime: 3.2,
                                  duration: 0.6)
                ], parameters: [])
                let player = try engine.makePlayer(with: pattern)

                try engine.start()
                try player.start(atTime: 0)
            } catch {
                let error = error
                internalLogger?.error("play haptic failed: \(error)")
            }
        }
        perform(#selector(confirmActive), with: nil, afterDelay: 3.8)
    }

    @objc
    private func confirmActive() {
        window?.delegate?.volumeWindowConfirmActive()
        hide()
    }

    @objc
    private func hide() {
        window?.isHidden = true
    }

    @objc
    func doBeforeHide() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(confirmActive), object: nil)

        // haptic
        if #available(iOS 13, *),
           let engine = engine as? CHHapticEngine {
            engine.stop(completionHandler: nil)
        }
    }
}

// MARK: - Coffee

final class CoffeeService {

    private var addedObserver = false

    func startCoffee() {
        guard !addedObserver && hasDeclareFullConfig else { 
            internalLogger?.info("Didn't add coffee: \(!addedObserver), \(hasDeclareFullConfig)")
            return
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillTerminate),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
        addedObserver = true
        internalLogger?.info("Added coffee")
    }

    func stopCoffee() {
        NotificationCenter.default.removeObserver(self)
        addedObserver = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func appWillTerminate() {
        let badge = UIApplication.shared.applicationIconBadgeNumber

        let content = UNMutableNotificationContent()
        content.badge = NSNumber(integerLiteral: badge)
        let request = UNNotificationRequest(identifier: "coffee", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        internalLogger?.info("Send silent noti when terminating")
    }
}

var hasDeclareFullConfig: Bool = {
    let alwaysKey = "NSLocationAlwaysUsageDescription"
    let backgroundModesKey = "UIBackgroundModes"
    let locationKey = "location"
    if Bundle.main.object(forInfoDictionaryKey: alwaysKey) != nil,
       let modes = (Bundle.main.object(forInfoDictionaryKey: backgroundModesKey) as? [String]),
       modes.contains(locationKey) {
        return true
    }
    internalLogger?.error("Didn't declare enough config in info.plist")
    return false
}()
// swiftlint:enable all

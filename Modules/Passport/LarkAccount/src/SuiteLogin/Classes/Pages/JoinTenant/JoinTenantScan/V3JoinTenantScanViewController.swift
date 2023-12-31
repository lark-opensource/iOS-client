//
//  V3JoinTenantScanViewController.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/2.
//

import Foundation
import RxSwift
import QRCode
import LKCommonsLogging
import Lottie
import LarkAlertController
import Homeric
import RoundedHUD
import LarkUIKit

class UnderlineLayout: NSLayoutManager {
    override func drawUnderline(forGlyphRange glyphRange: NSRange, underlineType underlineVal: NSUnderlineStyle, baselineOffset: CGFloat, lineFragmentRect lineRect: CGRect, lineFragmentGlyphRange lineGlyphRange: NSRange, containerOrigin: CGPoint) {
        if let container = textContainer(forGlyphAt: glyphRange.location, effectiveRange: nil) {
            let boundingRect = self.boundingRect(forGlyphRange: glyphRange, in: container)
            var offsetRect = boundingRect.offsetBy(dx: containerOrigin.x, dy: containerOrigin.y)
            offsetRect.origin.y = offsetRect.minY + 0.5
            drawUnderline(under: offsetRect)
        }
    }
    func drawUnderline(under rect: CGRect) {
        let path = UIBezierPath()
        path.lineWidth = 1
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.stroke()
    }
}

class V3JoinTenantScanViewController: ScanCodeViewController, UITextViewDelegate {

    private let disposeBag: DisposeBag = DisposeBag()

    private let vm: V3JoinTenantScanViewModel

    var useHUDLoading: Bool = false
    private var loadingHUD: RoundedHUD?

    init(vm: V3JoinTenantScanViewModel) {
        self.vm = vm
        super.init(type: .qrCode)
        self.didScanQRCodeBlock = { [weak self] (result, _) in
            guard let self = self else { return }
            self.vm.qrUrl = result
            if let handler = vm.externalHandler {
                handler(result)
                self.popSelf()
            } else {
                self.handleNext()
            }
        }
        delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static let logger = Logger.plog(V3JoinTenantScanViewController.self, category: "SuiteLogin.V3JoinTenantScanViewController")

    private lazy var errorHandler: ErrorHandler = {
        return V3ErrorHandler(vc: self, context: vm.context, contextExpiredPostEvent: true)
    }()

    lazy private var loadingMaskView: UIView = {
        return BaseViewController.createLoadingMaskView(loadingView)
    }()

    lazy private var loadingView: LOTAnimationView = {
        return BaseViewController.createLoading()
    }()

    lazy var subtitleLabel: UITextView = {
        let layout = UnderlineLayout()
        let storage = NSTextStorage()
        storage.addLayoutManager(layout)
        let initialSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        let container = NSTextContainer(size: initialSize)
        container.widthTracksTextView = true
        layout.addTextContainer(container)
        let label = LinkClickableLabel(frame: .zero, textContainer: container)
        label.setupStyle(true)
        label.delegate = self
        label.linkTextAttributes = [
            .foregroundColor: UIColor.ud.primaryOnPrimaryFill //lk.css("#FFFFFF")
        ]
        return label
    }()

    override func viewDidLoad() {
        setupLoading()
        super.viewDidLoad()
        if Display.pad {
            view.backgroundColor = .black
            self.navigationController?.navigationBar.barTintColor = UIColor.ud.bgBody
        }
        subtitleLabel.attributedText = vm.subtitle
        let vh = view.frame.height
        let rectSize: CGFloat = 257
        let h = vh / 2 + rectSize / 2 + 40 - rectSize * 0.15
        view.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(h)
            make.centerX.equalToSuperview()
            make.height.equalTo(32)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Self.logger.info("n_page_scan_qrcode")
        SuiteLoginTracker.track(pageName(), params: [TrackConst.path: vm.trackPath])
    }

    func handleNext() {
        PassportMonitor.flush(PassportMonitorMetaJoin.joinTenantQrcodeStart,
                eventName: ProbeConst.monitorEventName,
                categoryValueMap: [ProbeConst.flowType: vm.joinTenantScanInfo.flowType],
                context: vm.context)
        let startTime = Date()
       showLoading()
       vm.joinWithQRCode().subscribe(onError: { [weak self] (err) in
           guard let self = self else { return }
           self.stopLoading()
           PassportMonitor.monitor(PassportMonitorMetaJoin.joinTenantQrcodeResult,
                                   eventName: ProbeConst.monitorEventName,
                                   categoryValueMap: [ProbeConst.flowType: self.vm.joinTenantScanInfo.flowType],
                                   context: self.vm.context)
           .setResultTypeFail()
           .setPassportErrorParams(error: err)
           .flush()
           self.handle(err)
       }, onCompleted: { [weak self] in
           guard let self = self else { return }
           PassportMonitor.monitor(PassportMonitorMetaJoin.joinTenantQrcodeResult,
                                         eventName: ProbeConst.monitorEventName,
                                         categoryValueMap: [ProbeConst.flowType: self.vm.joinTenantScanInfo.flowType,
                                                            ProbeConst.duration: Int(Date().timeIntervalSince(startTime) * 1000)],
                                         context: self.vm.context)
           .setResultTypeSuccess()
           .flush()
           self.stopLoading()
       }).disposed(by: self.disposeBag)
    }

    func pageName() -> String {
        return Homeric.ENTER_JOIN_TENANT_SCAN
    }

    // MARK: Label 点击 UITextViewDelegate
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        Self.logger.info("n_action_click_how_to_get_qrcode")
        if interaction == .invokeDefaultAction {
            SuiteLoginTracker.track(Homeric.JOIN_TENANT_SCAN_CLICK_HOW_GET_QRCODE)
            BaseViewController.clickLink(
                URL,
                serverInfo: vm.joinTenantScanInfo,
                vm: vm,
                vc: self,
                errorHandler: self
            )
        }
        return false
    }
}

extension V3JoinTenantScanViewController: QRCodeViewControllerDelegate {
    func didClickAlbum() {
        SuiteLoginTracker.track(Homeric.JOIN_TENANT_SCAN_CLICK_ALBUM)
    }

    func didClickBack() {
        SuiteLoginTracker.track(Homeric.CLICK_BACK, params: ["from": pageName()])
    }
}

extension V3JoinTenantScanViewController: ErrorHandler, BaseViewControllerLoadingProtocol {

    public func showLoading() {
        // 目前用全局loading替换了
        view.endEditing(true)
        if useHUDLoading {
            loadingHUD = RoundedHUD.showLoading(on: self.view)
        } else {
            loadingMaskView.isHidden = false
            view.bringSubviewToFront(loadingMaskView)
            loadingView.play()
        }
    }

    public func stopLoading() {
        if useHUDLoading {
            loadingHUD?.remove()
            loadingHUD = nil
        } else {
            loadingView.stop()
            loadingMaskView.isHidden = true
        }
    }

    public func handleBiz(_ error: Error) -> Bool {
        if let err = error as? V3LoginError,
            case let .badServerCode(info) = err,
            case .normalAlertError = info.type {
            stopLoading()
            V3ErrorHandler.showAlert(info.message, vc: self) {
                self.startScanning()
            }
            return true
        }
        return false
    }

    public func handle(_ error: Error) {
        if !handleBiz(error) {
            errorHandler.handle(error)
            stopLoading()

            startScanning()
        }
    }

    public func setupLoading() {
        view.addSubview(loadingMaskView)
        loadingMaskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

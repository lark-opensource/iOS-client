//
//  MagicShareWrapperViewController.swift
//  ByteView
//
//  Created by Prontera on 2020/4/14.
//

import UIKit
import SnapKit
import ByteViewNetwork

final class MagicShareWrapperViewController: BaseViewController, UIGestureRecognizerDelegate {

    let runtime: MagicShareRuntime
    let context: InMeetViewContext
    let meeting: InMeetMeeting

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackNewPageShow()
        // 在ios16以下，如果横屏弹文档，需要转一下方向
        if #unavailable(iOS 16.0) {
            let docSubType = self.runtime.documentInfo.shareSubType
            // 进入unknown类型时，不主动转屏，跟随当前方向
            let isLandscapeEnabled = docSubType.isLandscapeEnabled(setting: meeting.setting) || [.ccmPpt, .unknown].contains(docSubType)
            if !isLandscapeEnabled, currentLayoutContext.layoutType.isPhoneLandscape, meeting.setting.canOrientationManually {
                InMeetOrientationToolComponent.switchOrientation(for: self.view)
            }
        }
    }

    let runtimeOwnerID: ObjectIdentifier?

    init(runtime: MagicShareRuntime, meeting: InMeetMeeting, context: InMeetViewContext) {
        self.runtime = runtime
        self.context = context
        self.meeting = meeting
        self.runtimeOwnerID = runtime.ownerID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func stop() {
        runtime.stop()
    }

    func startFollow() {
        runtime.startFollow()
    }

    func startRecord() {
        runtime.startRecord()
    }

    func startSSToMSFollow() {
        runtime.startSSToMS()
    }

    func isTheSame(with document: MagicShareDocument) -> Bool {
        return runtime.documentInfo.hasEqualContentTo(document)
    }

    func updateDocument(_ document: MagicShareDocument) {
        runtime.updateDocument(document)
    }

    private func setUpUI() {
        view.backgroundColor = .white
        addChild(runtime.documentVC)
        view.addSubview(runtime.documentVC.view)
        runtime.documentVC.view.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        runtime.documentVC.didMove(toParent: self)

        // 点击手势 & 上滑手势触发流转至沉浸态
        let tapGr = UITapGestureRecognizer(target: self, action: #selector(switchToFullScreen))
        tapGr.delegate = self
        tapGr.cancelsTouchesInView = false
        runtime.documentVC.view.addGestureRecognizer(tapGr)

        let swipeGr = UISwipeGestureRecognizer(target: self, action: #selector(switchToFullScreen))
        swipeGr.direction = .up
        swipeGr.delegate = self
        swipeGr.cancelsTouchesInView = false
        runtime.documentVC.view.addGestureRecognizer(swipeGr)
    }

    private func trackNewPageShow() {
        let pageNum = navigationController?.viewControllers.count ?? 1
        let type: String = "ccm"
        CommonReciableTracker.trackMagicShareDidNewPageShow(pageNum: pageNum, type: type)
    }

    override var shouldAutorotate: Bool {
        return runtime.documentVC.shouldAutorotate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        var mask = runtime.documentVC.supportedInterfaceOrientations
        if !mask.contains(.portrait) { // 保证必有竖屏，原因是Lark里面有该保证
            mask.insert(.portrait)
        }
        return mask
    }

    deinit {
        // NOTE: MS 复用
        guard runtime.ownerID == self.runtimeOwnerID else {
            return
        }
        runtime.cancelAllMagicShareTimeouts()
        runtime.documentVC.willMove(toParent: nil)
        runtime.documentVC.view.removeFromSuperview()
        runtime.documentVC.removeFromParent()
        runtime.documentVC.didMove(toParent: nil)
    }

    @objc
    private func switchToFullScreen() {
        context.fullScreenDetector?.postEnterFullScreenEvent()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

}

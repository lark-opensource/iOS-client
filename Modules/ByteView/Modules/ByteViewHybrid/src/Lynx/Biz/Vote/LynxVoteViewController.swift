//
// Created by maozhixiang.lip on 2022/10/20.
//

import Foundation
import ByteViewUI
import SnapKit
import UniverseDesignColor
import ByteViewNetwork
import ByteViewCommon
import ByteViewTracker
import BDXLynxKit

final class LynxVoteViewController: LynxBaseViewController {
    let name: String
    private let vm: LynxVoteViewModel
    private let initProps: [String: Any]
    private weak var lynxParent: LynxVoteViewController?

    init(name: String,
         vm: LynxVoteViewModel,
         initProps: [String: Any]? = nil,
         lynxParent: LynxVoteViewController? = nil) {
        self.name = name
        self.vm = vm
        self.initProps = initProps ?? [:]
        self.lynxParent = lynxParent
        super.init(userId: vm.userId, path: "vote/\(name)/template.js")
        self.vm.addListener(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupLynxView(with builder: LynxViewBuilder) {
        let networkParams = LynxNetworkParam(userId: vm.userId, httpClient: vm.httpClient)
        builder.group("vc.vote")
        builder.lifecycleDelegate(self)
        builder.nativeModule(LynxVoteNetworkModule.self, param: networkParams)
        builder.nativeModule(LynxI18nModule.self, param: networkParams)
        builder.initProps([
            "initProps": self.initProps
        ])
        builder.globalProps([
            "meeting": self.vm.lynxMeeting.dict,
            "safeAreaInsets": self.view.safeAreaInsets.dict,
            "scene": self.vm.scene.dict
            // "votes": self.vm.votes.map { $0.dict },
        ])
        builder.bridgeHandler("vc.vote.dismissSelf") { [weak self] _, _ in
            self?.dismiss(animated: true)
            self?.configDismissTransition()
        }
        builder.bridgeHandler("vc.showToast") { [weak self] params, _ in
            guard let content = params?["content"] as? String else { return }
            let icon = (params?["icon"] as? Int).flatMap { LynxToastIconType.init(rawValue: $0) }
            let duration = (params?["duration"] as? Int).flatMap { TimeInterval($0) }
            self?.vm.showToast(content, icon: icon, duration: duration)
        }
        builder.bridgeHandler("vc.showToolbarGuide") { [weak self] params, _ in
            guard let type = params?["type"] as? String else { return }
            guard let content = params?["content"] as? String else { return }
            self?.vm.showToolbarGuide(type: type, content: content)
        }
        builder.bridgeHandler("vc.showUserProfile") { [weak self] params, _ in
            guard let uid = params?["uid"] as? String else { return }
            self?.vm.showUserProfile(uid: uid)
        }
        builder.bridgeHandler("vc.view.globalFrame") { [weak self] _, callback in
            callback(.succeeded, (self?.globalFrame ?? .zero).dict)
        }
        builder.bridgeHandler("vc.vote.voteList") { [weak self] _, callback in
            callback(.succeeded, ["voteList": self?.vm.votes.map { $0.dict } ?? []])
        }
        builder.bridgeHandler("vc.vote.openPage") { [weak self] params, _ in
            guard let self = self else { return }
            guard let name = params?["name"] as? String else { return }
            guard let initProps = params?["initProps"] as? [String: Any] else { return }
            let vc = LynxVoteViewController(name: name, vm: self.vm, initProps: initProps, lynxParent: self)

            var regularStyle: DynamicModalPresentationStyle = .formSheet
            var compactStyle: DynamicModalPresentationStyle = .pageSheet
            var disableSwipeDismiss = false
            if let disablePullDown = params?["disablePullDown"] as? Bool {
                disableSwipeDismiss = disablePullDown
            }
            if let presentStyle = params?["presentStyle"] as? [String: Int] {
                if let rawStyle = presentStyle["regular"], let style = DynamicModalPresentationStyle(rawValue: rawStyle) {
                    regularStyle = style
                }
                if let rawStyle = presentStyle["compact"], let style = DynamicModalPresentationStyle(rawValue: rawStyle) {
                    compactStyle = style
                }
            }
            let regularConfig = DynamicModalConfig(presentationStyle: regularStyle,
                                                   backgroundColor: UIColor.ud.vcTokenMeetingFillMask,
                                                   disableSwipeDismiss: disableSwipeDismiss,
                                                   needNavigation: true)
            let compactConfig = DynamicModalConfig(presentationStyle: compactStyle,
                                                   backgroundColor: UIColor.ud.vcTokenMeetingFillMask,
                                                   disableSwipeDismiss: disableSwipeDismiss,
                                                   needNavigation: true)
            self.vm.present(vc, regularConfig: regularConfig, compactConfig: compactConfig)
        }
        builder.bridgeHandler("vc.vote.sendEventToParent") { [weak self] params, _ in
            guard let eventName = params?["name"] as? String else { return }
            guard let eventParams = params?["params"] as? [String: Any] else { return }
            self?.lynxParent?.lynxView?.sendEvent(name: eventName, params: eventParams)
        }
        builder.bridgeHandler("vc.dismissKeyboard") { _, _ in
            UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private func updateMeeting(_ meeting: LynxMeetingInfo) {
        self.lynxView?.sendEvent(name: "meeting", params: meeting.dict)
        self.lynxView?.updateGlobalProps(["meeting": meeting.dict], needReload: true)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        self.lynxView?.updateGlobalProps(["safeAreaInsets": self.view.safeAreaInsets.dict], needReload: true)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.lynxView?.updateGlobalProps(["scene": self.vm.scene.dict], needReload: true)
    }

    private func configDismissTransition() {
        guard let ctx = self.transitionCoordinator,
              let transitionView = self.navigationController?.view.superview else {
            return
        }
        transitionView.backgroundColor = .clear
        let animation = CABasicAnimation(keyPath: #keyPath(CALayer.backgroundColor))
        animation.fromValue = UIColor.ud.vcTokenMeetingFillMask.cgColor
        animation.toValue = UIColor.ud.vcTokenMeetingFillMask.withAlphaComponent(0).cgColor
        animation.duration = ctx.transitionDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        transitionView.layer.add(animation, forKey: nil)
    }
}

extension LynxVoteViewController: LynxVoteViewModelListener {
    func meetingDidChange(_ meeting: LynxMeetingInfo) {
        if Thread.isMainThread {
            updateMeeting(meeting)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.updateMeeting(meeting)
            }
        }
    }

    func votesDidChange(_ votes: [VoteStatisticInfo]) {
        let voteList = votes.map { $0.dict }
        self.lynxView?.sendEvent(name: "voteList", params: ["voteList": voteList])
        // self.lynxView?.updateGlobalProps(["votes": voteList], needReload: false)
    }
}

public extension LynxManager {
    func createVoteIndexPage(vm: LynxVoteViewModel) -> UIViewController {
        LynxVoteViewController(name: "index", vm: vm)
    }

    func createVotePanelPage(vm: LynxVoteViewModel, voteID: String) -> UIViewController {
        let vc = LynxVoteViewController(name: "panel", vm: vm, initProps: ["voteID": voteID])
        return vc
    }
}

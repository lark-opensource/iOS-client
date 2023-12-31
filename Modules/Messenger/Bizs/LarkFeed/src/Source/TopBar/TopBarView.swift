//
//  TopBarView.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/22.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkBadge
import UniverseDesignNotice
import LarkMessengerInterface
import LarkOpenFeed
import EENavigator
import LarkContainer
import LarkSetting
import UniverseDesignIcon
import Homeric
import LKCommonsTracker

final class TopBarView: UIView, UserResolverWrapper {
    var userResolver: UserResolver { viewModel.userResolver }

    private let disposeBag: DisposeBag = DisposeBag()
    let viewModel: TopBarViewModel
    private weak var networkView: UDNotice?
    @ScopedInjectedLazy private var feedContext: FeedContextService?

    init(viewModel: TopBarViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.N00
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    private func bind() {
        // 网络状态通知
        viewModel.netStatusDriver.drive(onNext: { [weak self] (status) in
            self?.showNetworkView(status: status)
        }).disposed(by: disposeBag)
    }

    private func showNetworkView(status: NetworkState) {
        let isShowNetView = !(status == .normal ? true : false)
        var goNetSettingsGesture: UITapGestureRecognizer?
        var goNetDiagnoseGesture: UITapGestureRecognizer?
        var title = status.title
        if status == .serviceUnavailable {
            title = BundleI18n.LarkFeed.Lark_NetworkDiagnosis_NetworkError_GoToDiagnosis_Mobile
        }
        if isShowNetView {
            let font = UIFont.ud.body1(.fixed)
            let attributedText = NSAttributedString(string: title ?? "",
                                                    attributes: [.font: font,
                                                                 .foregroundColor: UIColor.ud.textTitle])
            var config = UDNoticeUIConfig(backgroundColor: UIColor.ud.functionDangerFillSolid02, attributedText: attributedText)
            config.leadingIcon = status.icon
            let networkView = UDNotice(config: config)
            self.isUserInteractionEnabled = true
            networkView.isUserInteractionEnabled = false
            networkView.update()
            self.networkView = networkView
            self.addSubview(networkView)
            networkView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            self.bringSubviewToFront(networkView)

            let rightImageView = UIImageView()
            rightImageView.image = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN2)
            self.addSubview(rightImageView)
            rightImageView.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-16)
            }
            rightImageView.isHidden = true
            self.bringSubviewToFront(rightImageView)
            if status == .noNetwork {
                goNetSettingsGesture = UITapGestureRecognizer(target: self, action: #selector(goNetSettings))
                if let goNetSettingsGesture = goNetSettingsGesture {
                    self.addGestureRecognizer(goNetSettingsGesture)
                }
                rightImageView.isHidden = false
                FeedTeaTrack.trackNetworkUnconnectedView()
            }
            if status == .serviceUnavailable {
                goNetDiagnoseGesture = UITapGestureRecognizer(target: self, action: #selector(goNetDiagnose))
                if let goNetDiagnoseGesture = goNetDiagnoseGesture {
                    self.addGestureRecognizer(goNetDiagnoseGesture)
                }
                rightImageView.isHidden = false
                FeedTeaTrack.trackNetworkUnavailableView()
            }
        } else {
            if let goNetSettingsGesture = goNetSettingsGesture {
                self.removeGestureRecognizer(goNetSettingsGesture)
            }
            if let goNetDiagnoseGesture = goNetDiagnoseGesture {
                self.removeGestureRecognizer(goNetDiagnoseGesture)
            }
            networkView?.removeFromSuperview()
            networkView = nil
        }
    }

    //去系统网络设置页
    @objc
    private func goNetSettings() {
        FeedTeaTrack.trackNetworkUnconnectedClick()
        // 将openUrl任务放到下一下runloop里，尝试解决下卡死问题
        DispatchQueue.main.async {
            if let url = URL(string: "App-Prefs:root=WIFI"), UIApplication.shared.canOpenURL(url as URL) {
                UIApplication.shared.openURL(url as URL)
            }
        }

    }
    //去网络诊断页
    @objc
    private func goNetDiagnose() {
        FeedTeaTrack.trackNetworkUnavailableClick()
        guard let fromVC = feedContext?.page else { return }
        let body = NetDiagnoseSettingBody(from: .feed_banner)
        navigator.push(body: body, from: fromVC)
    }
}

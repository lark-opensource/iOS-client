//
//  DocsViewController.swift
//  Lark
//
//  Created by liuwanlin on 2017/12/26.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import LarkUIKit
import SpaceKit
import RxSwift
import RxCocoa
import LKCommonsLogging
import UniverseDesignToast
import SKUIKit

#if MessengerMod
import LarkSDKInterface
#endif

import SKBrowser
import LarkFeatureGating
import UniverseDesignColor
import UniverseDesignIcon

public protocol DocsDependency {
    #if MessengerMod
    var docAPI: DocAPI { get }
    #endif
    /*NOTE: doc内部现在打开链接调用的是UIApplication.openUrl，
     其封装的跳转逻辑不符合需求，提供该方法返回一webvc，doc拿到vc后自己控制跳转逻辑*/
    func open(url: URL) -> UIViewController?
}

private let logger = Logger.log(BrowserViewController.self, category: "Module.Doc")

extension BrowserViewController {
    func shareAccessoryView(dependency: DocsDependency) -> UIView? {
        guard let feedID = self.feedID else {
            return nil
        }
        return DocsAccessoryView(dependency, with: feedID)
    }
}

class DocsAccessoryView: UIView {
    private var feedID: String
    private var dependency: DocsDependency
    private let disposeBag = DisposeBag()
    private lazy var remindSwitch: UISwitch = {
        let sw = UISwitch()
        sw.onTintColor = UDColor.primaryContentDefault
        sw.tintColor = UDColor.lineBorderComponent
        sw.addTarget(self, action: #selector(remindSwitchAction(sender:)), for: .valueChanged)
        return sw
    }()
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UDIcon.bellOutlined.ud.withTintColor(UDColor.iconN1)
        return imageView
    }()

    init(_ dependency: DocsDependency, with feedID: String) {
        self.dependency = dependency
        self.feedID = feedID
        super.init(frame: CGRect(x: 0, y: 0, width: SKDisplay.activeWindowBounds.width, height: 52))
        fetchDocFeeds(feedID: feedID)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fetchDocFeeds(feedID: String) {
        #if MessengerMod
        DispatchQueue.global().async {
            let request = self.dependency.docAPI.fetchDocFeeds(feedIds: [feedID])
            request.flatMap { (res) -> Observable<Bool> in
                return Observable.just(res[feedID]?.isRemind ?? true)
            }.catchErrorJustReturn(true)
             .observeOn(MainScheduler.instance)
             .subscribe(onNext: { [weak self] (isRemind) in
                guard let self = self else { return }
                let accessoryView = self.accessoryView(with: isRemind)
                self.addSubview(accessoryView)
                accessoryView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }).disposed(by: self.disposeBag)
        }
        #endif
    }

    func accessoryView(with isRemind: Bool) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .clear

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UDColor.textTitle
        label.textAlignment = .left
        label.text = BundleI18n.CCMMod.Lark_Legacy_DocsWidgetNotification
        container.addSubview(label)
        container.addSubview(remindSwitch)

        remindSwitch.isOn = isRemind
        updateSwitchStatus()

        container.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.size.equalTo(20)
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        remindSwitch.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        label.snp.makeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(remindSwitch.snp.left).offset(-12)
        }
        return container
    }

    private func updateSwitchStatus() {
        #if MessengerMod
        // 去服务端拉取最新的消息提醒状态矫正
        dependency.docAPI.fetchDocFeeds(feedIds: [feedID])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (docFeedsMap) in
                if let feedID = self?.feedID, let docFeed = docFeedsMap[feedID] {
                    self?.remindSwitch.setOn(docFeed.isRemind, animated: true)
                }
            }).disposed(by: disposeBag)
        #endif
    }

    @objc
    private func remindSwitchAction(sender: UISwitch) {
        #if MessengerMod
        let toastDisplayView = window ?? self
        dependency.docAPI.updateDocFeed(feedId: feedID, isRemind: remindSwitch.isOn)
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] (error) in
                guard let feedID = self?.feedID, let sw = self?.remindSwitch else { return }
                sw.setOn(!sw.isOn, animated: true)
                UDToast.showFailure(
                    with: BundleI18n.CCMMod.Lark_Legacy_DocsWidgetFail,
                    on: toastDisplayView,
                    error: error)
                logger.error("update doc feed is remind failed.",
                                                additionalData: ["feedId": feedID,
                                                                 "isRemind": "\(sw.isOn)"],
                                                error: error)
            }).disposed(by: self.disposeBag)
        #endif
    }

}

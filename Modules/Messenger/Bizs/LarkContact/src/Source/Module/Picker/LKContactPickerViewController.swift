//
//  LKContactPickerViewController.swift
//  LarkContact
//
//  Created by Sylar on 2018/3/19.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import LarkUIKit
import LarkCore
import Swinject
import LarkMessengerInterface

final class LKContactPickerViewController: LkNavigationController {
    var configuration: LarkContactConfiguration!
    var dataSource: LKContactViewControllerDataSource!
    var selectedCallback: ((UINavigationController, ContactPickerResult) -> Void)?

    var pickerToolBar: PickerToolBar? {
        return toolbar as? PickerToolBar
    }

    private var tracker: PickerAppReciable?
    private let disposeBag = DisposeBag()

    required init(configuration: LarkContactConfiguration,
                  currentTenantId: String,
                  rootViewController: UIViewController,
                  selectedCallback: ((UINavigationController, ContactPickerResult) -> Void)? = nil,
                  tracker: PickerAppReciable) {
        self.tracker = tracker
        super.init(navigationBarClass: nil, toolbarClass: configuration.toolbarClass)

        self.configuration = configuration
        self.dataSource = LKContactViewControllerDataSource(forceSelectedChatterIds: configuration.forceSelectedChatterIds,
                                                            defaultSelectedChatterIds: configuration.defaultSelectedChatterIds,
                                                            defaultSelectedChatIds: configuration.defaultSelectedChatIds)
        self.selectedCallback = selectedCallback

        if let toolbar = pickerToolBar {
            toolbar.navigationController = self
            toolbar.isTranslucent = true
            toolbar.barTintColor = UIColor.ud.primaryOnPrimaryFill
            toolbar.allowSelectNone = configuration.allowSelectNone
        }

        self.viewControllers = [rootViewController]

        self.modalPresentationStyle = .fullScreen
        tracker.initViewEnd()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let defaultToolBar = self.toolbar as? DefaultPickerToolBar {
            defaultToolBar.confirmButtonTappedBlock = { [weak self] _ in
                self?.finishSelect()
            }
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillChangeFrame),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)

        dataSource.getSelectedObservable
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.pickerToolBar?.updateSelectedItem(firstSelectedItems: self.dataSource.selectedChatters(),
                                                       secondSelectedItems: self.dataSource.selectedChats(),
                                                       updateResultButton: false)
            })
            .disposed(by: disposeBag)
        self.tracker?.firstRenderEnd()
    }

    func finishSelect(reset: Bool = false, extra: Any? = nil) {
        let chatterInfos = dataSource.selectedChatters()
        let botInfos = dataSource.selectedBots()
        let chatIds = dataSource.selectedChats()
        let mails = dataSource.selectedMails()
        let meetingGroupChatIds = dataSource.selectedMeetingGroups()
        if reset {
            dataSource.reset()
        }
        var extra = extra
        if let channel = extra as? SelectChannel {
            extra = channel.rawValue
        }
        // 点击完成，收起键盘
        UIApplication.shared.sendAction(#selector(resignFirstResponder), to: nil, from: nil, for: nil)
        selectedCallback?(self, ContactPickerResult(chatterInfos: chatterInfos,
                                                    botInfos: botInfos,
                                                    chatInfos: chatIds.map { SelectChatInfo(id: $0) },
                                                    departments: [],
                                                    mails: mails,
                                                    meetingGroupChatIds: meetingGroupChatIds,
                                                    mailContacts: [],
                                                    extra: extra))
    }

    @objc
    private func keyboardWillChangeFrame(notification: Notification) {
        let userInfo = notification.userInfo
        guard let frame = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        if frame.minY >= self.view.frame.height {
            /// 收起时需要考虑安全距离
            var bottomSafeAreaHeight: CGFloat = 0
            bottomSafeAreaHeight = self.view.safeAreaInsets.bottom
            self.toolbar.frame.origin.y = self.view.frame.height - self.toolbar.frame.height - bottomSafeAreaHeight
        } else {
            self.toolbar.frame.origin.y = frame.origin.y - self.toolbar.frame.height
        }
    }
}

//
//  FakeTabController.swift
//  LarkTourDev
//
//  Created by Meng on 2020/9/29.
//

import UIKit
import Foundation
import EENavigator
import LarkNavigation
import AnimatedTabBar
import SnapKit
import LarkAccountInterface
import LarkContainer
import LarkTourInterface
import RxSwift
import LarkTab

class FakeTabControllerHandler: RouterHandler {
    private let tab: Tab

    init(tab: Tab) {
        self.tab = tab
    }

    func handle(req: EENavigator.Request, res: Response) {
        res.end(resource: FakeTabViewController(tab: tab))
    }
}

class FakeTabViewController: FakeTabController {
    private let startLabel = UILabel(frame: .zero)
    private let idField = UITextField(frame: .zero)
    private let startButton = UIButton(frame: .zero)
    private let logoutButton = UIButton(frame: .zero)

    @Provider private var accountService: AccountService
    @Provider private var tourService: TourService
    @Provider private var userspace: UserSpaceService
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(startLabel)
        view.addSubview(idField)
        view.addSubview(startButton)
        view.addSubview(logoutButton)

        startLabel.text = "填写MockId:"
        startLabel.font = .systemFont(ofSize: 16.0)
        idField.font = .systemFont(ofSize: 16.0)
        idField.placeholder = "id"
        idField.borderStyle = .roundedRect
        startButton.setTitle("Start mock", for: .normal)
        startButton.backgroundColor = .systemBlue
        startButton.layer.cornerRadius = 6.0
        startButton.addTarget(self, action: #selector(start), for: .touchUpInside)
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.backgroundColor = .systemRed
        logoutButton.layer.cornerRadius = 6.0
        logoutButton.addTarget(self, action: #selector(logout), for: .touchUpInside)

        startLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(16.0)
            make.trailing.equalTo(idField.snp.leading).inset(16.0)
            make.height.equalTo(36.0)
            make.centerY.equalToSuperview().inset(32.0)
        }

        idField.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().inset(16.0)
            make.centerY.equalTo(startLabel)
            make.height.equalTo(36.0)
            make.width.equalTo(62.0)
        }

        startButton.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(16.0)
            make.height.equalTo(36.0)
            make.top.equalTo(startLabel.snp.bottom).offset(16.0)
        }

        logoutButton.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(16.0)
            make.height.equalTo(36.0)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(36.0)
        }
    }

    @objc func start() {
        FakeData.id = idField.text ?? ""
        FakeData.platform = "Mobile"
        userspace.clear(for: .currentUser)
        tourService.checkOnboardingIfNeeded().subscribe().disposed(by: disposeBag)
    }

    @objc func logout() {
        accountService.relogin(
            conf: .default,
            onError: { _ in }, onSuccess: {}, onInterrupt: {})
    }
}

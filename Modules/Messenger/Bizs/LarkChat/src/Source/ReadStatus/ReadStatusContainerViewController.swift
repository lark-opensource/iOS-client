//
//  ReadStatusContainerViewController.swift
//  LarkChat
//
//  Created by zhenning on 2002/02/05.
//  Copyright © 2020年. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import LKCommonsLogging
import SnapKit
import LarkModel
import RxSwift
import LarkTraitCollection
import LarkMessageCore
import LarkContainer
import LarkMessengerInterface

final class ReadStatusContainerViewController: BaseUIViewController, UserResolverWrapper {
    var userResolver: UserResolver { viewModel.userResolver }
    private static let logger = Logger.log(ReadStatusContainerViewController.self, category: "ReadStatusContainerViewController")
    let viewModel: ReadStatusViewModel
    private lazy var readStatusVC: ReadStatusViewController = {
        ReadStatusViewController(viewModel: self.viewModel)
    }()
    private lazy var newReadStatusVC: NewReadStatusViewController = {
       NewReadStatusViewController(viewModel: self.viewModel)
    }()
    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy private var chatDurationStatusTrackService: ChatDurationStatusTrackService?

    init(viewModel: ReadStatusViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if Display.pad {
            self.modalPresentationControl.dismissEnable = true
        }
        self.view.backgroundColor = UIColor.ud.N00
        self.title = viewModel.title
        let currentVC = viewModel.isDisplayPad ? self.newReadStatusVC : self.readStatusVC
        addChildReadStatusVC(currentVC)
        ReadStatusContainerViewController.logger.debug("ReadStatus isDisplayPad = \(viewModel.isDisplayPad), currentVC = \(currentVC)")

        /// CR切换, switch DoubleLine / Segment
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self)
            .subscribe(onNext: { [weak self] change in
                guard let self = self else { return }
                let isDoubleLine = self.viewModel.isDisplayPad && (change.new.horizontalSizeClass == .regular)
                let currentVC = isDoubleLine ? self.newReadStatusVC : self.readStatusVC
                self.addChildReadStatusVC(currentVC)
                ReadStatusContainerViewController.logger.debug("ReadStatus: traitSizeClass changed", additionalData: ["traitSizeClass": "\(change.new.horizontalSizeClass)"])
            }).disposed(by: disposeBag)

        chatDurationStatusTrackService?.setGetChatBlock { [weak self] in
            return self?.viewModel.chat
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        chatDurationStatusTrackService?.markIfViewControllerIsAppear(value: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        chatDurationStatusTrackService?.markIfViewControllerIsAppear(value: false)
    }

    private func addChildReadStatusVC(_ childController: UIViewController) {
        self.addChild(childController)
        self.view.addSubview(childController.view)

        childController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        // switch DoubleLine / Segment
        let isDoubleLine = viewModel.isDisplayPad && (newCollection.horizontalSizeClass == .regular)
        let currentVC = isDoubleLine ? self.newReadStatusVC : self.readStatusVC
        self.addChildReadStatusVC(currentVC)
        ReadStatusContainerViewController.logger.debug("ReadStatus: traitSizeClass changed", additionalData: ["traitSizeClass": "\(newCollection.horizontalSizeClass)"])
    }
}

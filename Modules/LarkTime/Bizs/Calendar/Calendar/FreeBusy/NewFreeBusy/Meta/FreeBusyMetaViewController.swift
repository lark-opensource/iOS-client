//
//  FreeBusyMetaViewController.swift
//  Calendar
//
//  Created by pluto on 2023/8/28.
//

import Foundation
import LKCommonsLogging

class FreeBusyMetaViewController: UIViewController {
    let logger = Logger.log(FreeBusyMetaViewController.self, category: "Calendar.FreeBusyMetaViewController")

    private let viewModel: FreeBusyMetaViewModel
    init(viewModel: FreeBusyMetaViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        loadContentVC()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - ContentVC
extension FreeBusyMetaViewController {
    private func loadContentVC() {
        guard let contentViewModel = viewModel.buildContentViewModel() else {
            logger.error("error buildContentViewModel.")
            return
        }
        /// 一期 区分下VC，构造
        let contentViewController: UIViewController
        
        switch viewModel.sceneType {
        case .profile:
            guard let vm = contentViewModel as? FreeBusyViewModel else { return }
            contentViewController = FreeBusyController(viewModel: vm)
        case .group:
            guard let vm = contentViewModel as? GroupFreeBusyViewModel else { return }
            contentViewController = GroupFreeBusyController(viewModel: vm)
        case .meetingRoom:
            guard let vm = contentViewModel as? MeetingRoomFreeBusyViewModel else { return }
            contentViewController = MeetingRoomFreeBusyController(viewModel: vm)
        case .append:
            guard let vm = contentViewModel as? ArrangementViewModel else { return }
            contentViewController = ArrangementController(viewModel: vm)
        }

        addChild(contentViewController)
        view.addSubview(contentViewController.view)
        contentViewController.view.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        contentViewController.didMove(toParent: self)
    }
}

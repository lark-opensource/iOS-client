//
//  BoxFeedsViewController.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/6/9.
//

import Foundation
import RxSwift
import LarkTab

final class BoxFeedsViewController: BaseFeedsViewController {

    let boxViewModel: BoxFeedsViewModel

    var feedIds: [String] = [] // Header显示用

    lazy var naviBar: BoxFeedsTitleNaviBar = {
        let naviBar = BoxFeedsTitleNaviBar()
        naviBar.backButtonClickedBlock = { [weak self] in
            guard let `self` = self else { return }
            self.navigationController?.popViewController(animated: true)
        }
        return naviBar
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(boxViewModel: BoxFeedsViewModel) throws {
        self.boxViewModel = boxViewModel
        try super.init(feedsViewModel: boxViewModel)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        isNavigationBarHidden = true
        self.view.addSubview(naviBar)
        naviBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }

        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.naviBar.snp.bottom)
        }

        // NaviBar左边Badge
        boxViewModel.dependency.badgeDriver.drive(onNext: { [weak self] (type) in
            self?.naviBar.setBadge(type)
        }).disposed(by: disposeBag)
    }
}

//
//  FavoriteListController.swift
//  Lark
//
//  Created by lichen on 2018/6/4.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import UniverseDesignToast
import UniverseDesignEmpty

public final class EnterFavoriteCostInfo {
    private let start = CACurrentMediaTime()
    var sdkCost: Int?
    var initViewStamp: TimeInterval?
    var firstRenderStamp: TimeInterval?
    var end: TimeInterval?

    lazy var reciableLatencyDetail: [String: Any] = {
            guard let sdkCost = self.sdkCost,
                  let initViewStamp = self.initViewStamp,
                  let firstRenderStamp = self.firstRenderStamp,
                  let end = end else {
                return [:]
            }
            return ["sdk_cost": sdkCost,
                    "init_view_cost": Int((initViewStamp - start) * 1000),
                    "first_render_cost": Int((firstRenderStamp - start) * 1000)]
        }()

    lazy var cost: Int = {
        guard let end = end else { return 0 }
        return Int((end - start) * 1000)
    }()
}

public final class FavoriteListController: FavoriteBaseControler {
    static let pageName = "\(FavoriteListController.self)"
    public var viewModel: FavoriteViewModel

    var loadingHud: UDToast?
    var emptyView: UDEmptyView = UDEmptyView(config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: BundleI18n.LarkChat.Lark_Legacy_FavoriteEmpty), type: .noCollection))

    public var pushDetailController: ((FavoriteCellViewModel, UIViewController) -> Void)?

    private let enterCostInfo: EnterFavoriteCostInfo

    public init(viewModel: FavoriteViewModel, enterCostInfo: EnterFavoriteCostInfo) {
        self.viewModel = viewModel
        self.enterCostInfo = enterCostInfo
        super.init(nibName: nil, bundle: nil)
        self.title = BundleI18n.LarkChat.Lark_Legacy_FavoritesTitle
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.table.reloadData()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        emptyView.isHidden = true

        self.loadingHud = UDToast.showLoading(on: self.view, disableUserInteraction: true)

        self.viewModel.datasource.asDriver().skip(1)
            .drive(onNext: { [weak self] (datasource) in
                guard let `self` = self else { return }
                self.datasource = datasource
                self.table.reloadData()
                self.emptyView.isHidden = !self.datasource.isEmpty
                self.loadingHud?.remove()
                self.loadingHud = nil
            })
            .disposed(by: self.disposeBag)

        self.viewModel.dataProvider.is24HourTime
            .drive(onNext: { [weak self] _ in
                self?.table.reloadData()
            }).disposed(by: self.disposeBag)
        self.viewModel.loadMore()
        self.enterCostInfo.firstRenderStamp = CACurrentMediaTime()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewModel.dataProvider.audioPlayer.stopPlayingAudio()
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        self.pushDetailController?(self.datasource[indexPath.row], self)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.height

        if offset + height * 2 > contentHeight {
            self.viewModel.loadMore()
        }
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? FavoriteListCell {
            cell.willDisplay()
        }
        guard indexPath.row < datasource.count else { return }
        let viewModel = datasource[indexPath.row]
        viewModel.willDisplay()
    }

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? FavoriteListCell {
            cell.didEndDisplay()
        }
        guard indexPath.row < datasource.count else { return }
        let viewModel = datasource[indexPath.row]
        viewModel.didEndDisplay()
    }
}

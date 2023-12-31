//
//  SearchCardTableViewCell.swift
//  LarkSearch
//
//  Created by bytedance on 2021/7/26.
//

import UIKit
import Foundation
import LarkModel
import LarkAccountInterface
import Lynx
import LarkSearchCore
import UniverseDesignTheme
import LKCommonsLogging
import SnapKit
import LarkUIKit
import LarkLocalizations
import LarkReleaseConfig
import LarkContainer

class SearchCardTableViewCell: UITableViewCell, SearchTableViewCellProtocol {

    static let logger = Logger.log(SearchCardTableViewCell.self, category: "LarkSearch.SearchCardTableViewCell")

    var isRecommend: Bool = false
    var viewModel: SearchCellViewModel?
    var lynxView: LynxView?
    var lynxViewTemplate: Data?
    var heightConstraint: Constraint?
    var analysisParams: [String: Any]?
    var imageFetcher: SearchLynxImageFetcher?
    var lynxPropsManager: LynxPropsManagerProtocol?
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupLynxViewIfNeeded(userResolver: UserResolver) {
        guard self.lynxView == nil else { return }
        let params = ASLynxBridgeDependencyWrapper(userResolver: userResolver, cell: self)
        self.imageFetcher = SearchLynxImageFetcher(userResolver: userResolver)
        self.lynxPropsManager = LynxPropsManager(userResolver: userResolver)
        self.lynxView = LynxView(builderBlock: { lynxViewBuilder in
            lynxViewBuilder.group = LynxGroup(name: "search", withPreloadScript: nil, useProviderJsEnv: false, enableCanvas: true, enableCanvasOptimization: true)
            lynxViewBuilder.screenSize = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
            lynxViewBuilder.config = LynxConfig(provider: SearchLynxTemplateProvider())
            lynxViewBuilder.config?.register(ASLynxBridge.self, param: params)
        })
        guard let lynxView = self.lynxView,
              let imageFetcher = self.imageFetcher,
              let lynxPropsManager = self.lynxPropsManager else {
            return
        }
        let containerGuide = UILayoutGuide()
        contentView.addLayoutGuide(containerGuide)
        containerGuide.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            heightConstraint = make.height.equalTo(200).priority(.high).constraint
        }
        contentView.addSubview(lynxView)
        if #available(iOS 13.0, *), lynxView.traitCollection.userInterfaceStyle == .dark {
            let theme = LynxTheme()
            theme.updateValue("dark", forKey: "brightness")
            lynxView.setTheme(theme)
        }
        lynxView.bridge.globalPropsData = lynxPropsManager.getGlobalProps()
        lynxView.layoutWidthMode = .exact
        lynxView.imageFetcher = imageFetcher
        lynxView.addLifecycleClient(self)
        lynxView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        lynxView.backgroundColor = .ud.bgBase
    }
    // 暗黑/明亮模式切换监听函数
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            // 如果当前设置主题一致，则不需要切换资源
            return
        }
        guard let lynxView = self.lynxView else {
            return
        }
        if UITraitCollection.current.userInterfaceStyle == UIUserInterfaceStyle.dark {
            //暗黑模式
            let theme = LynxTheme()
            theme.updateValue("dark", forKey: "brightness")
            lynxView.setTheme(theme)
        } else {
            //明亮模式
            let theme = LynxTheme()
            theme.updateValue("light", forKey: "brightness")
            lynxView.setTheme(theme)
        }
    }

    func set(viewModel: SearchCellViewModel, currentAccount: User?, searchText: String?) {
        guard let vm = viewModel as? SearchCardViewModel else { return }
        var widthOffset = 16
        if vm.isMainTab == false {
            widthOffset = 0
        }
        setupLynxViewIfNeeded(userResolver: vm.userResolver)

        if Display.pad {
            let width = vm.preferredWidth ?? UIScreen.main.bounds.size.width
            lynxView?.preferredLayoutWidth = width - CGFloat(widthOffset)
        } else {
            lynxView?.preferredLayoutWidth = UIScreen.main.bounds.size.width - CGFloat(widthOffset)
        }
    }
}

extension SearchCardTableViewCell: LynxViewLifecycle {
    func lynxViewDidChangeIntrinsicContentSize(_ view: LynxView!) {
        let height = view.intrinsicContentSize.height
        Self.logger.info("lynxViewDidChangeIntrinsicContentSize called, height=\(height)")
        if height <= 0 {
            return
        }
        self.heightConstraint?.update(offset: height)
    }
}

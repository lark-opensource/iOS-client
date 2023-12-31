//
//  LynxCardMenuBarViewModel.swift
//  LarkAI
//
//  Created by bytedance on 2021/9/24.
//

import UIKit
import Foundation
import LarkMenuController
import Lynx
import LarkSearchCore
import LKCommonsLogging
import SnapKit

final class LynxCardMenuBarViewModel: NSObject, MenuBarViewModel {
    private let cardWidth = CGFloat(336)
    private let cardMaxHeight = CGFloat(600)
    private static let logger = Logger.log(LynxCardMenuBarViewModel.self, category: "EnterpriseEntityWord.LynxCardMenuBarViewModel")
    let viewModel: TopicLynxViewModel
    public var completion: (() -> Void)?
    var realSize = CGSize(width: 336, height: 600)
    private let originSize: CGSize

    private var lynxView: LynxView

    weak var menu: MenuVCProtocol?
    var imageFetcher: SearchLynxImageFetcher

    var type: String {
        return "LynxCardMenuBarViewModel"
    }

    var identifier: String {
        return "LynxCardMenuBarViewModel"
    }

    var menuView: UIView {
        return lynxView
    }

    var menuSize: CGSize {
        return realSize
    }

    init(_ viewModel: TopicLynxViewModel, originSize: CGSize) {
        self.viewModel = viewModel
        self.originSize = originSize
        let params = TopicLynxDependency(userResolver: viewModel.userResolver, viewModel: viewModel)
        self.imageFetcher = SearchLynxImageFetcher(userResolver: viewModel.userResolver)
        self.lynxView = LynxViewFactory(userResovler: viewModel.userResolver).newLynxView(viewModel: viewModel, params: params, imageFetcher: imageFetcher)
        lynxView.layoutWidthMode = .exact
        lynxView.preferredLayoutWidth = cardWidth
        lynxView.layoutHeightMode = .max
        lynxView.preferredMaxLayoutHeight = cardMaxHeight
        super.init()
        lynxView.addLifecycleClient(self)
        if var data = LynxTemplateData(json: self.viewModel.json) {
            if let clientArgs = viewModel.clientArgs {
                data.update(clientArgs, forKey: "ClientArgs")
            }
            ASTemplateManager.loadTemplateWithData(templateName: self.viewModel.templateName,
                                                   channel: ASTemplateManager.EnterpriseWordChannel,
                                                   initData: data,
                                                   lynxView: lynxView,
                                                   resultCallback: nil)
        }
    }

    func updateMenuVCSize(_ size: CGSize) {
        if originSize != size {
            menu?.dismiss(animated: false, params: nil, completion: nil)
        }
        LynxCardMenuBarViewModel.logger.info("In updateMenuVCSize! \(size)")
    }

    func update(rect: CGRect, info: MenuLayoutInfo, isFirstTime: Bool) {

    }

    deinit {
        Self.logger.info("deinit called")
    }
}

extension LynxCardMenuBarViewModel: LynxViewLifecycle {
    func lynxViewDidChangeIntrinsicContentSize(_ view: LynxView!) {
        var height = view.intrinsicContentSize.height
        Self.logger.info("lynxViewDidChangeIntrinsicContentSize called, height=\(height)")
        if height <= 0 {
            return
        } else if height >= cardMaxHeight {
            height = cardMaxHeight
        }
        if height > 200 {
            realSize = CGSize(width: self.cardWidth, height: height)
            self.completion?()
        }
    }
}

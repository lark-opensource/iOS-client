//
//  BlockDemoListViewController.swift
//  LarkWorkplace
//
//  Created by chenziyi on 2021/8/10.
//

import EENavigator
import OPSDK
import LarkUIKit
import LarkTab
import LKCommonsLogging
import LarkOPInterface
import LarkAppLinkSDK
import UIKit
import LarkNavigator
import LarkContainer
import LarkWorkplaceModel

/// block demo列表页
final class BlockDemoListViewController: BaseUIViewController {
    static let logger = Logger.log(BlockDemoListViewController.self)

    // WPBlockView 使用
    private let userResolver: UserResolver
    private let navigator: UserNavigator
    private var params: BlockDemoParams

    private var didMount: Bool = false

    private lazy var blockView: WPBlockView = {
        /// 针对不同的block来更改sourceData
        self.params.sourceData["tab"] = self.params.title
        let blockModel = BlockModel(
            item: self.params.item,
            badgeKey: nil,
            scene: .demoBlock,
            elementId: UUID().uuidString,
            editorProps: nil,
            styles: nil,
            sourceData: self.params.sourceData
        )
        let blockView = WPBlockView(userResolver: userResolver, model: blockModel, trace: nil)
        return blockView
    }()

    init(userResolver: UserResolver, navigator: UserNavigator, params: BlockDemoParams) {
        self.userResolver = userResolver
        self.navigator = navigator
        self.params = params
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Self.logger.info("\(params.title) viewdidload")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Self.logger.info("\(params.title) viewdidappear")
        if !didMount {
            setupBlockView()
        }
		blockView.blockVCShow = true
    }

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		blockView.blockVCShow = false
	}

    private func setupBlockView() {

        view.addSubview(self.blockView)

        blockView.delegate = self

        blockView.snp.makeConstraints {(make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        blockView.clipsToBounds = true
    }
}

extension BlockDemoListViewController: WPBlockViewDelegate {

    func onTitleClick(_ view: WPBlockView, link: String?) {}

    func onActionClick(_ view: WPBlockView) {}

    func onLongPress(_ view: WPBlockView, gesture: UIGestureRecognizer) {}

    func blockDidFail(_ view: WPBlockView, error: OPError) {}

    func blockRenderSuccess(_ view: WPBlockView) {}

    func blockDidReceiveLogMessage(_ view: WPBlockView, message: WPBlockLogMessage) {}

    func blockContentSizeDidChange(_ view: WPBlockView, newSize: CGSize) {}

    func handleAPI(
        _ plugin: BlockCellPlugin,
        api: WPBlockAPI.InvokeAPI,
        param: [AnyHashable: Any],
        callback: @escaping WPBlockAPICallback
    ) {
        switch api {
        case .openDemoBlock:
            openDemoBlock(param: param)
        default:
            break
        }
    }

    private func openDemoBlock(param: [AnyHashable: Any]) {
        var params = OpenDemoBlockParams()
        if let appId = param["appId"] as? String {
            params.appId = appId
        }
        if let blockTypeId = param["blockTypeId"] as? String {
            params.blockTypeId = blockTypeId
        }
        if let title = param["title"] as? String {
            params.title = title
        }

        if let blockEntity = param["blockEntity"] as? [String: Any],
           let sourceData = blockEntity["sourceData"] as? [String: Any],
           let blockId = blockEntity["blockID"] as? String,
           let sourceMeta = blockEntity["sourceMeta"] as? [String: Any] {
            params.sourceData = sourceData
            params.sourceMeta = sourceMeta
            params.blockId = blockId
        }

        let blockInfo = WPBlockInfo(blockId: params.blockId, blockTypeId: params.blockTypeId)
        let item = WPAppItem.buildBlockDemoItem(appId: params.appId, blockInfo: blockInfo)

        let blockDemoParams = BlockDemoParams(
            item: item,
            title: params.title,
            sourceData: params.sourceData,
            sourceMeta: params.sourceMeta
        )

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let body = BlockDemoDetailBody(params: blockDemoParams, listPageData: [:])
            self.navigator.push(body: body, from: self)
        }
    }

    func longGestureShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

//
//  FeedActionDebugFactory.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/6/28.
//

import LarkEMM
import LarkOpenFeed
import LarkSensitivityControl
import UniverseDesignToast

final class FeedActionDebugFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .debug
    }

    func createActionViewModel(model: FeedActionModel, context: FeedCardContext) -> FeedActionViewModelInterface? {
        return FeedActionDebugViewModel(model: model)
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return FeedActionDebugHandler(type: type, model: model)
    }
}

final class FeedActionDebugViewModel: FeedActionViewModelInterface {
    let title: String
    let contextMenuImage: UIImage
    init(model: FeedActionModel) {
        self.title = "copy feed"
        self.contextMenuImage = Resources.feed_done_contextmenu
    }
}

final class FeedActionDebugHandler: FeedActionHandler {
    override func executeTask() {
        self.willHandle()

        let info = "feedId: \(model.feedPreview.id)"
        let config = PasteboardConfig(token: Token("psda_token_avoid_intercept"))
        SCPasteboard.general(config).string = info

        if let vc = model.fromVC {
            UDToast.showTips(with: info, on: vc.view.window ?? vc.view)
        }
        self.didHandle()
    }
}

//
//  EmailSearchViewModel.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/9/25.
//

import Foundation
import LKCommonsLogging
import UIKit
import LarkModel
import LarkUIKit
import LarkTag
import RxSwift
import LarkCore
import UniverseDesignToast
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkSceneManager
import LarkAppLinkSDK
import LarkSearchCore
import LarkContainer
import LarkTab

struct EmailSearchRenderDataModel: Codable {
    var hasAttachment: Bool?
    var createTimeStamp: Int64?

    enum CodingKeys: String, CodingKey {
        case hasAttachment = "has_attachment"
        case createTimeStamp = "create_time_stamp"
    }

    public init() {}

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.hasAttachment, forKey: .hasAttachment)
        try container.encode(self.createTimeStamp, forKey: .createTimeStamp)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.hasAttachment = try values.decode(Bool.self, forKey: .hasAttachment)
        self.createTimeStamp = try values.decode(Int64.self, forKey: .createTimeStamp)
    }
}

final class EmailSearchViewModel: SearchCellViewModel, UserResolverWrapper {
    static let logger = Logger.log(EmailSearchViewModel.self, category: "Module.IM.Search")

    let router: SearchRouter
    let searchResult: SearchResultType
    var renderDataModel: EmailSearchRenderDataModel?
    var tab: SearchTab?

    var searchClickInfo: String { return "open_search" }

    var resultTypeInfo: String { return "emails" }

    let userResolver: UserResolver
    init(userResolver: UserResolver, searchResult: SearchResultType, router: SearchRouter) {
        self.userResolver = userResolver
        self.searchResult = searchResult
        self.router = router
        if let searchResult = searchResult as? Search.Result,
           !searchResult.renderData.isEmpty,
           let renderData = searchResult.renderData.data(using: .utf8) {
             do {
                 let renderModel = try JSONDecoder().decode(EmailSearchRenderDataModel.self, from: renderData)
                 self.renderDataModel = renderModel
             } catch {
                 Self.logger.error("[LarkSearch] mainSearch email renderData is error \(error)")
             }
        }
    }

    func supprtPadStyle() -> Bool {
        return UIDevice.btd_isPadDevice() && isPadFullScreenStatus(resolver: userResolver)
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        guard case .slash(let meta) = searchResult.meta else { return nil }
        switch meta.slashCommand {
        case .entity:
            goToURL(meta.appLink, from: vc)
        case .filter:
            assertionFailure("current should handle by page container")
            break
        @unknown default: break
        }
        return nil
    }

    private func goToURL(_ url: String, from: UIViewController) {
        if let url = URL(string: url)?.lf.toHttpUrl() {
            var searchOuterService: SearchOuterService? { try? self.userResolver.resolve(assert: SearchOuterService.self) }
            if let searchOuterService = searchOuterService, searchOuterService.enableUseNewSearchEntranceOnPad() {
                userResolver.navigator.switchTab(Tab.mail.url, from: from, animated: false) { [weak self] _ in
                    guard let self = self else { return }
                    guard let topVC = self.userResolver.navigator.mainSceneTopMost else { return }
                    navigator.pushOrShowDetail(url, context: [FromSceneKey.key: FromScene.global_search.rawValue], from: topVC)
                }
                return
            }
            navigator.pushOrShowDetail(url, context: [FromSceneKey.key: FromScene.global_search.rawValue], from: from)
        } else {
            Self.logger.error("[LarkSearch] useless url \(url)")
        }
    }

    func supportDragScene() -> Scene? {
        // TODO:
        return nil
    }
}

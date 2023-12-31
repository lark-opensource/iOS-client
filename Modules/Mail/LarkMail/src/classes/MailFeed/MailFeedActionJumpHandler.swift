//
//  MailFeedActionJumpHandler.swift
//  LarkMail
//
//  Created by ByteDance on 2023/9/15.
//

import LarkModel
import LarkOpenFeed
import RustPB
import LarkUIKit
import MailSDK
#if MessengerMod
import LarkMessengerInterface
#endif

final class MailFeedActionJumpFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .jump
    }

    var bizType: FeedPreviewType? {
        return .mailFeed
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return MailFeedActionJumpHandler(type: type, model: model, context: context)
    }
}

final class MailFeedActionJumpHandler: FeedActionHandler {
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        guard let vc = model.fromVC ?? context.feedContextService.page else { return }
        self.willHandle()
        Self.routerToEventList(feedPreview: model.feedPreview,
                               basicData: model.basicData,
                               groupType: model.groupType ?? .unknown,
                               context: context,
                               from: vc)
        self.didHandle()
    }
    static func routerToEventList(feedPreview: FeedPreview,
                                  basicData: IFeedPreviewBasicData?,
                                  groupType: Feed_V1_FeedFilter.TypeEnum,
                                  context: FeedCardContext,
                                  from: UIViewController) {
        var mailName : String
        var mailAddress : String
        var mailAvatar : String
        var fromNotice : Int = 0 // 这个值代表需要给请求强拉数据
        if (feedPreview.uiMeta.name.isEmpty) {
            mailName = ""
            mailAddress = ""
            mailAvatar = ""
        } else {
            let nameAndEmail = extractNameAndEmail(from: feedPreview.uiMeta.name)
            mailName = nameAndEmail.name ?? ""
            mailAddress = nameAndEmail.email ?? ""
            mailAvatar = feedPreview.uiMeta.avatarKey
            fromNotice = feedPreview.basicMeta.unreadCount > 0 ? 1 : 0
        }
        #if MessengerMod
        let body = MailFeedReadBody(feedCardId: feedPreview.basicMeta.bizId, mail: mailAddress, name:mailName, avatar: mailAvatar, fromNotice: fromNotice)
        let contextData: [String: Any] = [FeedSelection.contextKey: FeedSelection(feedId: feedPreview.id)]
        context.userResolver.navigator.showDetailOrPush(
        body: body,
        context: contextData,
        wrap: LkNavigationController.self,
        from: from)
        #endif
    }
    
    static func extractNameAndEmail(from input: String) -> (name: String?, email: String?) {
        let pattern = #"([^<]+)<([^>]+)>"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return (nil, nil)
        }

        let range = NSRange(location: 0, length: input.utf16.count)
        let matches = regex.matches(in: input, options: [], range: range)

        guard let match = matches.first else {
            return (nil, nil)
        }

        let nameRange = match.range(at: 1)
        let emailRange = match.range(at: 2)

        if let name = Range(nameRange, in: input), let email = Range(emailRange, in: input) {
            let extractedName = String(input[name])
            let extractedEmail = String(input[email])
            return (extractedName.trimmingCharacters(in: .whitespacesAndNewlines), extractedEmail.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return (nil, nil)
    }
}

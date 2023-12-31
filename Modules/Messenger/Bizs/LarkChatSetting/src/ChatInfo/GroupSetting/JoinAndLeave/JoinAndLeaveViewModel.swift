//
//  JoinAndLeaveViewModel.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/10/12.
//

import UIKit
import Foundation
import EENavigator
import LarkCore
import LarkModel
import LarkSDKInterface
import LKCommonsLogging
import RichLabel
import RxCocoa
import RxSwift
import LarkExtensions
import RustPB
import LarkContainer

final class JoinAndLeaveViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    private static let logger = Logger.log(JoinAndLeaveViewModel.self, category: "LarkChat.JoinAndLeaveViewModel")
    typealias TapEvent = (_ type: TapType) -> Void
    enum TapType {
        case user(id: String)
        case chat(id: String)
        case doc(url: URL)
    }

    private let disposeBag = DisposeBag()

    private let chatID: String
    private var chatAPI: ChatAPI

    private var datas: [JoinAndLeaveItem] = []
    private var _dataSource = PublishSubject<Result<[JoinAndLeaveItem], Error>>()
    var dataSource: Driver<Result<[JoinAndLeaveItem], Error>> {
        return _dataSource.asDriver(onErrorJustReturn: .success(datas))
    }

    private var pageCount: Int32 = 40
    private var cursor: String? = "0"
    private(set) var hasMore: Bool = false

    private var maxDispalyNameLength: Int = 25
    private var font = UIFont.systemFont(ofSize: 14)

    // pass tap event to controller
    // 将点击事件交由Controller处理
    var onTap: TapEvent?

    init(chatID: String, chatAPI: ChatAPI, userResolver: UserResolver) {
        self.chatID = chatID
        self.chatAPI = chatAPI
        self.userResolver = userResolver
    }

    func loadData() {
        let chatID = self.chatID
        chatAPI.getChatJoinLeaveHistory(chatID: chatID, cursor: cursor, count: pageCount)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                self.cursor = result.nextCursor
                self.hasMore = result.hasMore_p
                self.datas += result.chatterHistory.map { self.item(with: $0) }
                JoinAndLeaveViewModel.logger.info(
                    "get chat join leave history error",
                    additionalData: [
                        "count": "\(result.chatterHistory.count)",
                        "totalCount": "\(self.datas.count)"
                    ]
                )
                self._dataSource.onNext(.success(self.datas))
            }, onError: { [weak self] error in
                self?._dataSource.onNext(.failure(error))
                JoinAndLeaveViewModel.logger.error(
                    "get chat join leave history error",
                    additionalData: ["chatID": chatID],
                    error: error)
            }).disposed(by: disposeBag)
    }
}

// MARK: - parse RustPB.Basic_V1_ChatJoinLeaveHistory

private extension JoinAndLeaveViewModel {
    // `key` and `{key}` and `key's range of template`
    typealias KeyRange = (key: String, wrapped: String, range: NSRange)

    @inline(__always)
    func wrapper(_ key: String) -> String {
        return "{\(key)}"
    }

    func createAttachmentString(with icon: UIImage, displaySize: CGSize) -> NSAttributedString {
        // create attachment
        let attachment = LKAsyncAttachment(viewProvider: { () -> UIView in
            UIImageView(image: icon)
        }, size: displaySize, verticalAlign: .middle)

        // set attributed
        attachment.fontAscent = font.ascender
        attachment.fontDescent = font.descender
        attachment.margin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)

        // packaged into `NSAttributedString`
        let attachmentString = NSAttributedString(
            string: LKLabelAttachmentPlaceHolderStr,
            attributes: [LKAttachmentAttributeName: attachment]
        )

        return attachmentString
    }

    // get replace value and tap closure by `content`: RustPB.Basic_V1_ChatJoinLeaveHistory.ContentValue
    // 解析 content 获取用于替换的字符串和对应的点击事件
    func parse(content: RustPB.Basic_V1_ChatJoinLeaveHistory.ContentValue) -> (NSAttributedString, LKTextLink.LKTextLinkBlock?) {
        let display = content.displayText.count > maxDispalyNameLength ?
            String(content.displayText.prefix(maxDispalyNameLength - 1)) + "…" :
            content.displayText

        var attributedDispaly = NSMutableAttributedString(string: display)

        switch content.type {
        case .user:
            let userID = content.id
            attributedDispaly.insert(NSAttributedString(string: "@"), at: 0)
            return (attributedDispaly, { [weak self] _, _ in self?.onTap?(.user(id: userID)) })

        case .chat:
            let attachmentString = createAttachmentString(
                with: Resources.join_and_leave_group_icon,
                displaySize: CGSize(width: 16, height: 13.5)
            )

            attributedDispaly.insert(attachmentString, at: 0)

            let chatID = content.id
            return (attributedDispaly, { [weak self] _, _ in self?.onTap?(.chat(id: chatID)) })

        case .doc:

            if content.displayText.isEmpty, content.unauthorizedDoc {
                attributedDispaly = NSMutableAttributedString(string: BundleI18n.LarkChatSetting.Lark_Group_UnauthorizedDoc)
            }

            // create doc icon
            // 创建Doc图标
            let attachmentString = createAttachmentString(
                with: Resources.join_and_leave_doc_icon,
                displaySize: CGSize(width: 16, height: 16)
            )

            attributedDispaly.insert(attachmentString, at: 0)

            if let url = URL(string: content.docURL) {
                return (attributedDispaly, { [weak self] _, _ in self?.onTap?(.doc(url: url)) })
            } else {
                JoinAndLeaveViewModel.logger.error("join group form doc without url")
                return (attributedDispaly, nil)
            }

        case .bot, .team, .unknownValueType:
            return (attributedDispaly, nil)

        case .dep:
            return (attributedDispaly, nil)

        @unknown default:
            assert(false, "new value")
            return (attributedDispaly, nil)
        }
    }

    // get display message and textlinks by `template` and `map`
    // 解析模板和Map，生成显示的字符串和点击事件所需的`textlinks`
    func parse(
        template: String,
        with map: [String: RustPB.Basic_V1_ChatJoinLeaveHistory.ContentValue]
    ) -> (NSAttributedString, [LKTextLink]?) {
        let addDefaultAttriburedTo: (NSMutableAttributedString) -> Void = {
            let style = NSMutableParagraphStyle()
            style.maximumLineHeight = 20
            style.minimumLineHeight = 20
            style.lineSpacing = 0
            $0.addAttributes(
                [
                    .foregroundColor: UIColor.ud.N500,
                    .font: self.font,
                    .paragraphStyle: style
                ],
                range: NSRange(location: 0, length: $0.length)
            )
        }

        let result = NSMutableAttributedString(string: template)
        let keys = map.keys

        // skip empty datas
        // 跳过空数据
        if keys.isEmpty {
            addDefaultAttriburedTo(result)
            return (result, nil)
        }

        // get every key range at template, and sorted by range start index
        // 获取每个Key的range，并按照从前到后的顺序排序
        let keyRanges = keys.compactMap { (key) -> KeyRange? in
            let wrapped = wrapper(key)
            if let range = template.range(of: wrapped) {
                return (key, wrapped, NSRange(range, in: template))
            }
            return nil
        }.sorted { $0.range.location < $1.range.location }

        // skip empty datas
        // 跳过空数据
        if keyRanges.isEmpty {
            addDefaultAttriburedTo(result)
            return (result, nil)
        }

        // everykey base offset
        var offset = 0
        var textlinks = [LKTextLink]()

        // replace key by formated content
        // 格式化`ContentValue`, 并替换模板中的key
        for keyRange in keyRanges {
            if let content = map[keyRange.key] {
                let (value, tap) = parse(content: content)

                var range = NSRange(location: keyRange.range.location + offset, length: keyRange.range.length)
                result.replaceCharacters(in: range, with: value)

                let valueLength = value.length

                if let tap = tap {
                    range.length = valueLength
                    var textlink = LKTextLink(range: range, type: .link)
                    textlink.linkTapBlock = tap

                    textlinks.append(textlink)
                }

                // update offset
                // 更新Offset
                offset += (valueLength - (keyRange.wrapped as NSString).length)
            }
        }

        addDefaultAttriburedTo(result)

        return (result, textlinks)
    }

    func item(with history: RustPB.Basic_V1_ChatJoinLeaveHistory) -> JoinAndLeaveItem {
        let (display, textlinks) = parse(template: history.extra.template, with: history.extra.contentValues)
        return JoinAndLeaveItem(
            id: history.id,
            chatterID: history.chatterID,
            name: history.chatterName,
            avatarKey: history.avatarKey,
            time: history.createTime.lf.cacheFormat("join_and_leave") { $0.lf.formatedTime_v2() },
            content: display,
            textLinks: textlinks
        )
    }
}

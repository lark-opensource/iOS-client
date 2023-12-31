//
//  DetailSourceViewModel.swift
//  Todo
//
//  Created by 张威 on 2021/10/18.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import TodoInterface
import UniverseDesignFont

/// Detail - Source - ViewModel

final class DetailSourceViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    let rxViewData = BehaviorRelay<DetailSourceViewDataType?>(value: nil)

    private let disposeBag = DisposeBag()
    private let store: DetailModuleStore

    init(resolver: UserResolver, store: DetailModuleStore) {
        self.userResolver = resolver
        self.store = store
    }

    func setup() {
        store.rxInitialized()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in
                guard let self = self, let todo = self.store.state.todo, self.store.state.scene.isForEditing else {
                    return
                }
                self.setup(with: todo)
            })
            .disposed(by: disposeBag)
    }

    private struct ViewData: DetailSourceViewDataType {
        var range: NSRange?
        var text: String
        var linkText: String
        var url: URL?
        var attributedText: AttrText {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineBreakMode = .byWordWrapping
            let string = MutAttrText(
                string: text,
                attributes: [
                    .foregroundColor: UIColor.ud.textTitle,
                    .font: UDFont.systemFont(ofSize: 12),
                    .paragraphStyle: paragraphStyle
                ]
            )
            if let range = range, Utils.RichText.checkRangeValid(range, in: string) {
                string.addAttributes([.foregroundColor: UIColor.ud.textLinkNormal], range: range)
            } else {
                Detail.logger.error("range is invalid. \(range). string \(string)")
            }
            return string
        }
    }

    private func setup(with todo: Rust.Todo) {
        let origin = todo.origin
        switch origin.type {
        case .href:
            guard case .href(let href) = origin.element else {
                Detail.logger.error("setup source. href mismatch element.")
                return
            }
            self.makeViewData(linkText: href.title, url: href.url, platform: origin.displayI18NName)
        case .chat:
            guard case .chat(let chat) = origin.element else {
                Detail.logger.error("setup source. chat mismatch element.")
                return
            }
            guard todo.readable(for: .todoOrigin) else {
                Detail.logger.info("setup source. chat type but no auth.")
                return
            }
            self.makeViewData(linkText: chat.chatName, url: chat.link, platform: I18N.Todo_Task_TaskSourceChat)
        case .unknown: return
        @unknown default: return
        }
    }

    /// 构造view Data
    private func makeViewData(linkText: String, url: String, platform: String) {
        var linkText = linkText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: url) else {
            Detail.logger.error("setup source. url is invalid, url: \(url.hashValue)")
            if !linkText.isEmpty {
                Detail.logger.error("setup source. show no link title")
                let text = I18N.Todo_Task_ViewInSomewhere(platform, linkText)
                let viewData = ViewData(range: nil, text: text, linkText: linkText, url: nil)
                rxViewData.accept(viewData)
            }
            return
        }

        linkText = linkText.isEmpty ? I18N.Todo_ClickToRedirect_Button : linkText
        let text = I18N.Todo_Task_ViewInSomewhere(platform, linkText)
        let templateFunc: ((String) -> String) = { I18N.Todo_Task_ViewInSomewhere(platform, $0) }
        guard let range = Utils.RichText.getRange(for: linkText, with: templateFunc) else {
            Detail.logger.error("make source view data failed. range is nil")
            return
        }
        let viewData = ViewData(range: range, text: text, linkText: linkText, url: url)
        rxViewData.accept(viewData)
    }

    func trackLinkTap() {
        guard let url = rxViewData.value?.url else {
            assertionFailure()
            return
        }
        let isFromDoc = (store.state.todo?.source == .doc || store.state.todo?.source == .docx)
        let guid = store.state.scene.todoId ?? ""
        Detail.logger.info("sourceViewDidTap. isFromDoc:\(isFromDoc)")
        if !isFromDoc {
            Detail.tracker(
                .todo_click_back_to_dialog,
                params: [
                    "task_id": guid,
                    "scenario_type": "chat"
                ]
            )
            Detail.tracker(
                .todo_task_detail_click,
                params: [
                    "click": "source_link_from_chat",
                    "target": "im_chat_main_view"
                ]
            )
        } else {
            Detail.tracker(
                .todo_task_detail_click,
                params: [
                    "click": "source_link_from_docs",
                    "target": "ccm_docs_page_view"
                ]
            )
        }

        // 新埋点
        if isFromDoc {
            Detail.Track.clickSourceFromDoc(with: guid)
        } else {
            Detail.Track.clickSourceFromChat(with: guid)
        }
    }

}

//
//  DetailAncestorTaskViewModel.swift
//  Todo
//
//  Created by 迟宇航 on 2022/7/18.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import UniverseDesignFont

/// 更新view
final class DetailAncestorTaskViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    let rxViewData: BehaviorRelay<DetailAncestorTaskViewDataType?> = .init(value: nil)

    private let context: DetailModuleContext
    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy private var richContentService: RichContentService?

    init(resolver: UserResolver, context: DetailModuleContext) {
        self.userResolver = resolver
        self.context = context
        setup()
    }

    private func setup() {
        context.store.rxValue(forKeyPath: \.ancestors)
            .observeOn(MainScheduler.instance)
            .map { [weak self] simpleTodos -> DetailAncestorTaskViewDataType? in
                guard let self = self else {
                    return nil
                }
                self.updateTopNocice(simpleTodos)
                return self.makeViewData(simpleTodos)
            }
            .bind(to: rxViewData)
            .disposed(by: disposeBag)
    }

    private func updateTopNocice(_ ancestors: [Rust.SimpleTodo]?) {
        guard let ancestors = ancestors else { return }
        if ancestors.first(where: { $0.deletedMilliTime > 0 }) != nil {
            let config = DetailModuleEvent.NoticeConfig(type: .error, text: I18N.Todo_ParentTaskDeleted_Text)
            context.bus.post(.showNotice(config: config))
        } else if let last = ancestors.last, last.completedMilliTime > 0 {
            let config = DetailModuleEvent.NoticeConfig(type: .success, text: I18N.Todo_ParentTaskCompleted_Text)
            context.bus.post(.showNotice(config: config))
        }
    }

    private func makeViewData(_ ancestors: [Rust.SimpleTodo]?) -> DetailAncestorTaskViewDataType? {
        guard let ancestors = ancestors, let richContentService = richContentService else {
            return nil
        }
        let titleAttrs: [AttrText.Key: Any] = [
            .font: UDFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.ud.textCaption
        ]

        let items = ancestors.filter({ $0.deletedMilliTime == 0 })
            .map { simpleTodo -> DetailAncestorItemData in
                let attrText: AttrText
                if !simpleTodo.richSummary.richText.isEmpty {
                    let config = RichLabelContentBuildConfig(baseAttrs: titleAttrs, lineSeperator: " ")
                    let content = richContentService.buildLabelContent(with: simpleTodo.richSummary, config: config)
                    attrText = content.attrText
                } else {
                    attrText = MutAttrText(
                        string: I18N.Todo_Task_NoTitlePlaceholder,
                        attributes: titleAttrs)
                }
                let outOfRangeText = AttrText(string: "\u{2026}", attributes: titleAttrs)
                return DetailAncestorItemData(
                    titleInfo: (title: attrText, outOfRangeText: outOfRangeText),
                    guid: simpleTodo.guid
                )
            }
        return AncestorTaskViewData(items: items)
    }
}

extension DetailAncestorTaskViewModel {

   private struct AncestorTaskViewData: DetailAncestorTaskViewDataType {
       var items: [DetailAncestorItemData]?
    }

}

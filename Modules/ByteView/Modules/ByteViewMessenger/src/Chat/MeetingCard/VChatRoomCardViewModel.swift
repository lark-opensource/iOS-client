//
//  VChatRoomCardViewModel.swift
//  LarkByteView
//
//  Created by Prontera on 2020/3/15.
//

import Foundation
import LarkMessageBase
import LarkModel
import RxSwift
import RustPB
import LarkSDKInterface
import ByteViewNetwork

protocol VChatRoomCardViewModelContext: UserViewModelContext {}
extension PageContext: VChatRoomCardViewModelContext {}

class VChatRoomCardViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: VChatRoomCardViewModelContext>: MessageSubViewModel<M, D, C> {
    private let disposeBag = DisposeBag()

    override var identifier: String {
        return "VChatRoom"
    }

    var text: String = I18n.Lark_View_InvitedToVirtualOffice("")

    lazy var chatterAPI: ChatterAPI? = context.chatterAPI
    var content: VChatRoomCardContent {
        return (self.message.content as? VChatRoomCardContent)!
    }

    override init(metaModel: M, metaModelDependency: D, context: C, binder: ComponentBinder<C>) {
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
        let chatterObservable = chatterAPI?.getChatter(id: content.forwarderID) ?? .empty()
        let i18nObservable: Observable<String?>
        if let httpClient = context.httpClient {
            i18nObservable = RxTransform.single {
                httpClient.i18n.get("View_C_InvitedToVirtualOffice", completion: $0)
            }.map { Optional($0) }.catchErrorJustReturn(nil).asObservable()
        } else {
            i18nObservable = .empty()
        }
        Observable.zip(chatterObservable, i18nObservable) { ($0, $1) }
            .subscribe(onNext: { [weak self] (chatter, template) in
                guard let self = self else {
                    return
                }
                let name = chatter?.name ?? ""
                var text: String
                if let template = template {
                    text = template.replacingOccurrences(of: "{{name}}", with: name)
                } else {
                    text = I18n.Lark_View_InvitedToVirtualOffice(name)
                }
                guard self.text != text else {
                    return
                }
                self.text = text
                self.syncToBinder()
                self.update(component: self.binder.component)
            })
            .disposed(by: disposeBag)
    }
}

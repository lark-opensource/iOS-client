//
//  LDLinkComponent.swift
//  NewLarkDynamic
//
//  Created by Jiayun Huang on 2019/6/23.
//

import Foundation
import AsyncComponent
import LarkModel
import LarkInteraction
final class LinkComponentFactory: ComponentFactory {
    override var tag: RichTextElement.Tag {
        return .link
    }

    override var needChildren: Bool {
        return true
    }

    override func create<C: LDContext>(
        richtext: RichText,
        element: RichTextElement,
        elementId: String,
        children: [RichTextElement],
        style: LDStyle,
        context: C?,
        translateLocale: Locale? = nil) -> ComponentWithSubContext<C, C> {
        let props = LinkComponentProps()
        props.iosURL = element.property.link.iosURL.possibleURL()
        props.url = element.property.link.url.possibleURL()
        props.scene = element.property.link.scene.rawValue
        return LinkComponent<C>(props: props, style: style, context: context)
    }
}

final class LinkComponentProps: ASComponentProps {
    var url: URL?
    var iosURL: URL?
    var scene: Int?
}

class LinkComponent<C: LDContext>: LDComponent<LinkComponentProps, LinkView, C>, LinkViewDelegate {
    override func create(_ rect: CGRect) -> LinkView {
        let view = LinkView(frame: rect)
        view.delegate = self
        return view
    }

    override func update(view: LinkView) {
        super.update(view: view)
        view.delegate = self
    }

    func didTouchWithLinkView(_ linkView: LinkView) {
        var isFooterLink = false
        if let linkScene = props.scene {
            isFooterLink = linkScene == LinkScene.footerLink.linkSceneCode()
        }
        let actionTrace =  self.context?.trace.subTrace()
        let start = Date()
        let reportOpenlink: (LDCardError.ActionError?) -> Void = {[weak self] error in
            self?.context?.reportAction(
                start: start,
                trace: actionTrace,
                actionID: nil,
                actionType: .url,
                error: error
            )
        }
        if let iosUrl = props.iosURL {
            if isFooterLink {
                context?.openLink(iosUrl, from: .footerLink(), complete: reportOpenlink)
            } else {
                context?.openLink(iosUrl, from: .cardLink(), complete: reportOpenlink)
            }
            return
        }
        if let url = props.url {
            if isFooterLink {
                context?.openLink(url, from: .footerLink(), complete: reportOpenlink)
            } else {
                context?.openLink(url, from: .cardLink(), complete: reportOpenlink)
            }
        }
        reportOpenlink(nil)
    }
}

protocol LinkViewDelegate: AnyObject {
    func didTouchWithLinkView(_ linkView: LinkView)
}

final class LinkView: UIView {
    weak var delegate: LinkViewDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.delegate?.didTouchWithLinkView(self)
    }
}

enum LinkScene: String {
    case unkown
    case cardLink
    case contentLink
    case footerLink
}

extension LinkScene {
    func linkSceneCode() -> Int {
        switch self {
        case .unkown:
            return 0
        case .cardLink:
            return 1
        case .contentLink:
            return 2
        case .footerLink:
            return 3
        }
    }
}

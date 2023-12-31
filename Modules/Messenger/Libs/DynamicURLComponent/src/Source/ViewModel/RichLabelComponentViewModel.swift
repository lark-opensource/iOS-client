//
//  RichLabelComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/23.
//

import UIKit
import Foundation
import RustPB
import LarkCore
import LarkModel
import LarkRichTextCore
import RichLabel
import LarkUIKit
import LarkMessageBase
import TangramComponent
import TangramUIComponent
import LarkMessengerInterface

public final class RichLabelComponentViewModel: RenderComponentBaseViewModel {
    private lazy var _component: RichLabelComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }

    var attributeElement: ParseRichTextResult?
    let stateID: String
    let componentID: String

    public required init(entity: URLPreviewEntity,
                         stateID: String,
                         componentID: String,
                         component: Basic_V1_URLPreviewComponent,
                         style: Basic_V1_URLPreviewComponent.Style,
                         property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                         children: [ComponentBaseViewModel],
                         ability: ComponentAbility,
                         dependency: URLCardDependency) {
        self.stateID = stateID
        self.componentID = componentID
        super.init(entity: entity,
                   stateID: stateID,
                   componentID: componentID,
                   component: component,
                   style: style,
                   property: property,
                   children: children,
                   ability: ability,
                   dependency: dependency)
    }

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let richText = property?.richText ?? .init()
        let props = buildComponentProps(componentID: componentID, property: richText, style: style)
        _component = RichLabelComponent<EmptyContext>(props: props, style: renderStyle)
    }

    private func buildComponentProps(componentID: String,
                                     property: Basic_V1_URLPreviewComponent.RichTextProperty,
                                     style: Basic_V1_URLPreviewComponent.Style) -> RichLabelProps {
        let props = RichLabelProps()
        let parser = RichTextAbilityParser(userResolver: userResolver,
                                           dependency: self,
                                           richText: property.richtext,
                                           font: style.tcFont ?? UIFont.systemFont(ofSize: UIFont.systemFontSize),
                                           textColor: style.tcTextColor ?? UIColor.ud.N900,
                                           richTextSenderId: self.dependency.senderID)
        self.attributeElement = parser.attributeElement
        props.attributedText.value = parser.attributedString
        props.backgroundColor = UIColor.clear
        props.numberOfLines = 0
        props.autoDetectLinks = true
        props.linkAttributes.value = parser.linkAttributes
        props.activeLinkAttributes.value = parser.activeLinkAttributes
        props.textCheckingDetecotor.value = parser.textCheckingDetecotor
        props.lineSpacing = parser.contentLineSpacing
        props.textLinkList = parser.textLinkList
        props.rangeLinkMap = parser.attributeElement.urlRangeMap
        let tapableRanges = parser.attributeElement.atRangeMap.flatMap({ $0.value })
            + parser.attributeElement.abbreviationRangeMap.compactMap({ $0.key })
            + parser.attributeElement.mentionsRangeMap.compactMap({ $0.key })
        props.tapableRangeList = tapableRanges
        props.font = parser.font
        props.delegate.update(new: self)
        return props
    }
}

extension RichLabelComponentViewModel: RichTextAbilityParserDependency, LKLabelDelegate {
    var currentUserID: String {
        return userResolver.userID
    }

    var maxWidth: CGFloat {
        return dependency.contentMaxWidth
    }

    func getColor(for key: ColorKey, type: Type) -> UIColor {
        return dependency.getColor(for: key, type: type)
    }

    func openURL(url: URL) {
        if let targetVC = dependency.targetVC {
            userResolver.navigator.push(url,
                                        context: [URLPreviewActionBody.dependencyKey: dependency,
                                                  URLPreviewActionBody.stateIDKey: stateID,
                                                  URLPreviewActionBody.entityKey: self.entity],
                                        from: targetVC)
        }
        URLTracker.trackRenderClick(entity: self.entity, extraParams: self.dependency.extraTrackParams, clickType: .pageClick, componentID: componentID)
    }

    public func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        // CCM的Ask Owner弹窗和取消授权的action路由（//client/preview/action）都是通过anchor节点触发的，不能添加http的scheme
        // let url = url.lf.toHttpUrl()
        openURL(url: url)
    }

    public func attributedLabel(_ label: LKLabel, didSelectPhoneNumber phoneNumber: String) {
        if let targetVC = dependency.targetVC {
            userResolver.navigator.open(body: OpenTelBody(number: phoneNumber), from: targetVC)
        }
        URLTracker.trackRenderClick(entity: self.entity, extraParams: self.dependency.extraTrackParams, clickType: .pageClick, componentID: componentID)
    }

    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        guard let targetVC = dependency.targetVC, let attributeElement = self.attributeElement else { return true }
        let atUserIdRangeMap = attributeElement.atRangeMap
        for (userID, ranges) in atUserIdRangeMap where ranges.contains(range) && userID != "all" {
            let body = PersonCardBody(chatterId: userID,
                                      source: .chat)
            if Display.phone {
                userResolver.navigator.push(body: body, from: targetVC)
            } else {
                userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: targetVC, prepare: ({ vc in
                    vc.modalPresentationStyle = .formSheet
                }))
            }
            URLTracker.trackRenderClick(entity: self.entity, extraParams: self.dependency.extraTrackParams, clickType: .pageClick, componentID: componentID)
            return false
        }

        for (ran, mention) in attributeElement.mentionsRangeMap where ran == range {
            switch mention.clickAction.actionType {
            case .none:
                break
            case .redirect:
                if let url = URL(string: mention.clickAction.redirectURL) {
                    userResolver.navigator.open(url, from: targetVC)
                }
            @unknown default: assertionFailure("unknow type")
            }
            URLTracker.trackRenderClick(entity: self.entity, extraParams: self.dependency.extraTrackParams, clickType: .pageClick, componentID: componentID)
            return false
        }
        return true
    }
}

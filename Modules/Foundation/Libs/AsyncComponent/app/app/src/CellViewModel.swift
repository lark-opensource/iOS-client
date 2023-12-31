//
//  CellViewModel.swift
//  AsyncComponentDev
//
//  Created by qihongye on 2019/1/29.
//

import Foundation
import UIKit
import AsyncComponent
import EEFlexiable
import LKRichView

enum Tag: Int8, LKRichElementTag {
    case p

    var typeID: Int8 {
        return self.rawValue
    }
}

class CellContext: Context {
    unowned var renderer: ASComponentRenderer
    unowned var vm: CellViewModel

    func updateCell() {
        vm.update()
    }

    init(_ renderer: ASComponentRenderer, _ vm: CellViewModel) {
        self.renderer = renderer
        self.vm = vm
    }

    func log() {
        print(1)
    }
}

struct Model {
    var name: String
    var avatar: UIColor
    var content: NSAttributedString
}

class CellViewModel {
    var model: Model
    let nameProps = UILabelProps()
    let nameStyle = ASComponentStyle()
    let props: CellProps
    let style: ASComponentStyle

    var renderer: ASComponentRenderer

    weak var tableView: UITableView?

    init(model: Model) {
        self.model = model
        self.props = CellProps(model: model)
        self.style = ASComponentStyle()
        let component = CellComponent(props: props, style: style, context: nil)
        component.preferMaxLayoutWidth = UIScreen.main.bounds.width
        renderer = ASComponentRenderer(component)
        renderer.layout()
        component.context = CellContext(renderer, self)

        nameProps.key = "name_key"
        nameProps.numberOfLines = 0
        nameStyle.flexShrink = 0
        nameStyle.flexGrow = 0
        nameStyle.marginTop = 10
        nameStyle.marginBottom = 10
    }

    deinit {
    }

    func update() {
        DispatchQueue.global().async {
            for _ in 0..<10000 {
                self.props.model.name = String.randomString(length: 10)
                let component = CellComponent(props: self.props, style: self.style, context: nil)
                component.preferMaxLayoutWidth = UIScreen.main.bounds.width
                component.context = CellContext(self.renderer, self)
                print("update root")
                self.renderer.update(rootComponent: component)
            }
        }
//        DispatchQueue.global().async {
//            for _ in 0..<1000 {
//                print("update sub")
//                self.nameProps.text = String.randomString(length: 10)
//                self.nameStyle.backgroundColor = UIColor.random()
//                let component = UILabelComponent(props: self.nameProps, style: self.nameStyle)
//                self.renderer.update(component: component, rendererNeedUpdate: { [weak self] in
//                    self?.tableView?.reloadData()
//                })
//            }
//        }
    }

    func height() -> CGFloat {
        return renderer.size().height
    }
}

class CellProps: ASComponentProps {
    var model: Model

    init(model: Model) {
        self.model = model
    }
}

class CellComponent: ASComponent<CellProps, EmptyState, UIView, CellContext> {
    var contentStyle: ASComponentStyle = {
        var contentStyle = ASComponentStyle()
        contentStyle.flexGrow = 1
        contentStyle.flexShrink = 1
        contentStyle.backgroundColor = UIColor.yellow
        return contentStyle
    }()

//    let contentProps = RichLabelProps()
    let contentProps = RichViewComponentProps()

    override init(props: CellProps, style: ASComponentStyle, context: CellContext? = nil) {
        super.init(props: props, style: style, context: context)
        style.flexDirection = .row
        style.width = CSSValue(cgfloat: UIScreen.main.bounds.width)

        let leftContainerStyle = ASComponentStyle()
        leftContainerStyle.flexDirection = .column
        leftContainerStyle.flexGrow = 0
        leftContainerStyle.flexShrink = 0
        leftContainerStyle.width = 50

        let centerContainerStyle = ASComponentStyle()
        centerContainerStyle.flexDirection = .column
        centerContainerStyle.flexGrow = 1
        centerContainerStyle.flexShrink = 1
        centerContainerStyle.paddingLeft = 30
        centerContainerStyle.paddingRight = 15

        let rightContainerStyle = ASComponentStyle()
        rightContainerStyle.flexDirection = .columnReverse
        rightContainerStyle.flexGrow = 1
        rightContainerStyle.flexShrink = 1
        rightContainerStyle.paddingLeft = 30
        rightContainerStyle.paddingRight = 15

        let avatarStyle = ASComponentStyle()
        avatarStyle.width = 40
        avatarStyle.height = 40
        avatarStyle.flexShrink = 0
        avatarStyle.flexGrow = 0
        avatarStyle.marginTop = 10
        avatarStyle.marginLeft = 10
        avatarStyle.border = Border(BorderEdge(width: 1, color: .red, style: .solid))
        avatarStyle.backgroundColor = props.model.avatar

        let nameProps = UILabelProps()
        nameProps.key = "name_key"
        nameProps.text = props.model.name
        let nameStyle = ASComponentStyle()
        nameStyle.backgroundColor = UIColor.clear
        nameStyle.flexShrink = 0
        nameStyle.flexGrow = 0
        nameStyle.marginTop = 10
        nameStyle.marginBottom = 10
        nameStyle.border = Border(BorderEdge(width: 1))

//        contentProps.attributedText = props.model.content
        contentProps.styleSheets = [CSSStyleSheet(rules: [CSSStyleRule.create(CSSSelector(value: Tag.p), [.color(LKRichStyleValue<UIColor>(.value, UIColor.black))])])]
        contentProps.element = LKBlockElement(tagName: Tag.p).children([LKTextElement(text: props.model.content.string)])

        let buttonProps = UIButtonComponent.Props()
        buttonProps.touchUpInside = { [weak self] _ in
            guard let self = self, let context = self.context else {
                return
            }
            context.updateCell()
        }
        let buttonStyle = ASComponentStyle()
        buttonStyle.flexGrow = 0
        buttonStyle.flexShrink = 0
        buttonStyle.alignSelf = .center

        let avatarProps = ASComponentProps()

        setSubComponents([
            ASLayoutComponent<CellContext>(style: leftContainerStyle, [
                AvatarComponent<CellContext>(props: avatarProps, style: avatarStyle)
            ]),
            ASLayoutComponent<CellContext>(style: centerContainerStyle, [
                EmptyContext.provider(buildSubContext: { (_) -> EmptyContext? in
                    return EmptyContext()
                }, children: [
                    UILabelComponent(props: nameProps, style: nameStyle)
                ]),
                CornerRadiusComponent<CellContext>(props: .empty, style: contentStyle).setSubComponents([
                    RichViewComponent<CellContext>(props: contentProps, style: contentStyle)
//                    RichLabelComponent<CellContext>(props: contentProps, style: contentStyle)
                ])
            ]),
            ASLayoutComponent<CellContext>(style: rightContainerStyle, [
                EmptyContext.provider(buildSubContext: { (_) -> EmptyContext? in
                    return EmptyContext()
                }, children: [
                    UIButtonComponent(props: buttonProps, style: buttonStyle)
                ])
            ])
        ])
    }

    func updateContentColor(color: UIColor) -> ASComponentStyle {
//        contentProps.backgroundColor = color
        return contentStyle
    }
}

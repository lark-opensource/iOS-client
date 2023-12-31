//
//  MomentsInteractionBarComponent.swift
//  Moment
//
//  Created by ByteDance on 2022/7/6.
//

import Foundation
import AsyncComponent
import UIKit

final class MomentsInteractiveBarComponent<C: AsyncComponent.Context>: ASComponent<MomentsInteractiveBarComponent.Props, EmptyState, MomentsInteractiveBar, C> {
    final class Props: ASComponentProps {
        var iconKey: String
        var title: String
        var titleOfNSAttributedString: NSAttributedString {
            // 通过富文本来设置行高
            let paraph = NSMutableParagraphStyle()
            paraph.lineHeightMultiple = 1.25
            let attribute = [NSAttributedString.Key.paragraphStyle: paraph,
                             NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium)]
            return NSAttributedString(string: title, attributes: attribute)
        }

        init(iconKey: String = "",
             title: String = "") {
            self.iconKey = iconKey
            self.title = title
        }
    }

    override var isSelfSizing: Bool {
        return true
    }

    override var isComplex: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        /// icon与label之间的间距为8，icon的宽高为16，计算出label的宽度
        let labelWidth = size.width - 24
        let labelHeight = getLabelHeight(props.titleOfNSAttributedString, width: labelWidth)
        /// icon的宽高为16，icon距离顶部5（方便居中于第一行），组件最低高度为21
        let height = max(labelHeight, 21.0)
        return CGSize(width: size.width, height: height)
    }

    //根据宽度动态计算高度
    func getLabelHeight(_ text: NSAttributedString, width: CGFloat) -> CGFloat {
        return text.boundingRect(with: CGSize(width: width, height: CGFloat(MAXFLOAT)), options: [.usesLineFragmentOrigin], context: nil).height
    }

    public override func create(_ rect: CGRect) -> MomentsInteractiveBar {
        return MomentsInteractiveBar(frame: rect,
                                     momentsInteractionInfo: MomentsInteractiveBar.MomentsInteractionInfo(iconKey: props.iconKey,
                                                                                                          title: props.title))
    }

    override func update(view: MomentsInteractiveBar) {
        super.update(view: view)
        view.update(title: props.title, iconKey: props.iconKey)
    }
}

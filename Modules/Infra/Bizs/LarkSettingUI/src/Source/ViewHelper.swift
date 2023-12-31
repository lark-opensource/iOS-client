//
//  ViewHelper.swift
//  LarkSettingUI
//
//  Created by panbinghua on 2022/6/30.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignFont

public final class ViewHelper {

    public enum StackPlaceholderFixedAspect {
        case width(CGFloat)
        case height(CGFloat)
        case size(CGSize)
    }

    public static func stackPlaceholderFixed(aspect: StackPlaceholderFixedAspect) -> UIView {
        let view = UIView()
        view.snp.makeConstraints {
            switch aspect {
            case .width(let length):
                $0.width.equalTo(length)
            case .height(let length):
                $0.height.equalTo(length)
            case .size(let size):
                $0.width.equalTo(size.width)
                $0.height.equalTo(size.height)
            }
        }
        return view
    }

    public static func stackPlaceholderSpring(axis: NSLayoutConstraint.Axis, corssAxisLength: CGFloat) -> UIView {
        let view = UIView()
        view.snp.makeConstraints {
            if axis == .horizontal {
                $0.width.equalTo(999).priority(.low)
                $0.height.equalTo(corssAxisLength)
            } else {
                $0.height.equalTo(999).priority(.low)
                $0.width.equalTo(corssAxisLength)
            }
        }
        return view
    }
    
    public static func createSizedView(size: CGSize = CGSize(width: 16, height: 16)) -> UIView {
        let view = UIView()
        view.snp.makeConstraints {
            $0.size.equalTo(size)
        }
        return view
    }

    public static func createSizedImageView(size: CGSize = CGSize(width: 16, height: 16), image: UIImage? = nil) -> UIImageView {
        let view = UIImageView()
        view.image = image
        view.snp.makeConstraints {
            $0.size.equalTo(size)
        }
        return view
    }
}

extension UILabel {

    public func setFigmaText(_ text: String?) {
        guard let str = text else { return }
        guard let font = self.font else { return }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = font.figmaHeight
        paragraphStyle.maximumLineHeight = font.figmaHeight
        attributedText = NSAttributedString(
            string: str,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .baselineOffset: (font.figmaHeight - font.lineHeight) / 4
            ]
        )
    }
}

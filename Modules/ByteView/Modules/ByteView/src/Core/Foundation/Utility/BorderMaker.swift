//
//  BorderMaker.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/10/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit

extension UIView {
    func addBorder(edges: UIRectEdge, color: UIColor, insets: UIEdgeInsets = .zero, thickness: CGFloat = 1.0) {
        enum Direction { case left, right, top, bottom }

        func addBorder(direction: Direction) {
            let border = UIView()
            border.backgroundColor = color
            addSubview(border)
            border.snp.makeConstraints { make in
                if direction == .top || direction == .bottom {
                    make.left.equalToSuperview().inset(insets.left)
                    make.right.equalToSuperview().inset(insets.right)
                    make.height.equalTo(thickness)
                } else {
                    make.top.equalToSuperview().inset(insets.top)
                    make.bottom.equalToSuperview().inset(insets.bottom)
                    make.width.equalTo(thickness)
                }

                switch direction {
                case .left:
                    make.left.equalToSuperview()
                case .right:
                    make.right.equalToSuperview()
                case .top:
                    make.top.equalToSuperview()
                case .bottom:
                    make.bottom.equalToSuperview()
                }
            }
        }

        if edges.contains(.top) || edges.contains(.all) {
            addBorder(direction: .top)
        }
        if edges.contains(.left) || edges.contains(.all) {
            addBorder(direction: .left)
        }
        if edges.contains(.bottom) || edges.contains(.all) {
            addBorder(direction: .bottom)
        }
        if edges.contains(.right) || edges.contains(.all) {
            addBorder(direction: .right)
        }
    }
}

//
//  SearchPopupInterface.swift
//  LarkSearch
//
//  Created by wangjingcan on 2023/6/26.
//

import Foundation

public protocol ISearchPopupView: UIView {
    func show()
    func dismiss(completion: @escaping () -> Void)
}

public protocol ISearchPopupContentView: UIView {

    func updateContainerSize(size: CGSize)

}

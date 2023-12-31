//
//  LynxIconView.swift
//  SKCommon
//
//  Created by peilongfei on 2023/8/29.
//  


import Foundation
import Lynx
import UIKit
import SnapKit
import UniverseDesignSwitch
import LarkContainer

class LynxIconView: LynxUI<UIView> {
    private var iconToken = ""
    private var url = ""

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.clipsToBounds = true
        return imageView
    }()


    static let name = "ccm-icon-view"
    override var name: String { Self.name }

    override func createView() -> UIView {
        let view = UIView()
        view.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return view
    }

    @objc
    public static func propSetterLookUp() -> [[String]] {
        return [
            ["icon-token", NSStringFromSelector(#selector(setIconToken))],
            ["url", NSStringFromSelector(#selector(setUrl))]
        ]
    }

    @objc
    func setIconToken(_ value: String, requestReset: Bool) {
        iconToken = value
        iconView.di.setDocsImage(iconInfo: iconToken, url: url, userResolver: Container.shared.getCurrentUserResolver())
    }

    @objc
    func setUrl(_ value: String, requestReset: Bool) {
        url = value
        iconView.di.setDocsImage(iconInfo: iconToken, url: url, userResolver: Container.shared.getCurrentUserResolver())
    }
}

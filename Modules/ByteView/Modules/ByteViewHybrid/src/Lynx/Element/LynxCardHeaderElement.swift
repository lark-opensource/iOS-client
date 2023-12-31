//
//  LynxCardHeaderElement.swift
//  ByteViewHybrid
//
//  Created by maozhixiang.lip on 2023/2/21.
//

import Foundation
import UniverseDesignCardHeader
import UniverseDesignColor
import UIKit
import Lynx
import SnapKit

class LynxCardHeaderElement: LynxUI<UIView> {
    private var color: UIColor = .clear
    private var maskColor: UIColor = .ud.udtokenMessageCardBgMaskGeneral
    private var textColor: UIColor = .clear

    private lazy var headerView: UDCardHeader = {
        let udCardHeader = UDCardHeader(colorHue: .blue)
        return udCardHeader
    }()

    private lazy var headerContainer: UIView = {
        let container = UIView()
        container.addSubview(self.headerView)
        self.headerView.snp.remakeConstraints { $0.edges.equalToSuperview() }
        return container
    }()

    static let name: String = "ud-card-header"
    override var name: String { Self.name }

    override func createView() -> UIView? { self.headerContainer }

    @objc
    public static func propSetterLookUp() -> [[String]] {
        [
            ["color", NSStringFromSelector(#selector(setColor(value:requestReset:)))],
            ["mask-color", NSStringFromSelector(#selector(setMaskColor(value:requestReset:)))],
            ["text-color", NSStringFromSelector(#selector(setTextColor(value:requestReset:)))]
        ]
    }

    @objc
    func setColor(value: String, requestReset: Bool) {
        guard let color = UDColor.current.getValueByBizToken(token: value) else { return }
        self.color = color
        self.updateColorHue()
    }

    @objc
    func setMaskColor(value: String, requestReset: Bool) {
        guard let maskColor = UDColor.current.getValueByBizToken(token: value) else { return }
        self.maskColor = maskColor
        self.updateColorHue()
    }

    @objc
    func setTextColor(value: String, requestReset: Bool) {
        guard let textColor = UDColor.current.getValueByBizToken(token: value) else { return }
        self.textColor = textColor
        self.updateColorHue()
    }

    private func updateColorHue() {
        let colorHue = UDCardHeaderHue(color: color, textColor: textColor, maskColor: maskColor)
        self.headerView.colorHue = colorHue
    }
}

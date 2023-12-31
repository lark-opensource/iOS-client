//
//  MineAboutLarkHeaderView.swift
//  LarkMine
//
//  Created by 李勇 on 2020/1/15.
//

import Foundation
import RxSwift
import LarkFoundation
import LarkAppResources
import UIKit
import UniverseDesignToast
import LarkEMM
import LarkSensitivityControl

final class MineAboutLarkHeaderView: UIView {
    /// 图标
    private lazy var larkIcon = UIImageView()
    /// app名称+版本 容器
    private lazy var nameAndVersionView = UIView()
    /// app名称
    private lazy var larkName = UILabel.lu.labelWith(fontSize: 20, textColor: UIColor.ud.textTitle, text: BundleI18n.bundleDisplayName)
    /// 版本信息
    private lazy var versionStringLabel = UILabel.lu.labelWith(fontSize: 18, textColor: UIColor.ud.textTitle)
    /// 版本信息点击热区
    private lazy var versionLongTapArea = UIView()
    /// KA - DebugView
    private lazy var kaDebugView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()

    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubViews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubViews() {
        self.addSubview(larkIcon)
        self.addSubview(nameAndVersionView)
        nameAndVersionView.addSubview(larkName)
        nameAndVersionView.addSubview(versionStringLabel)
        self.addSubview(versionLongTapArea)
        self.addSubview(kaDebugView)
    }

    private func setupConstraints() {
        larkIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(72)
        }

        nameAndVersionView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(94)
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }

        larkName.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        versionStringLabel.snp.makeConstraints { make in
            make.centerY.trailing.equalToSuperview()
            make.leading.equalTo(larkName.snp.trailing).offset(8)
        }

        versionLongTapArea.snp.makeConstraints { make in
            make.top.equalTo(versionStringLabel.snp.top).offset(-8)
            make.bottom.equalTo(versionStringLabel.snp.bottom).offset(8)
            make.left.equalTo(larkName.snp.left).offset(-8)
            make.right.equalTo(versionStringLabel.snp.right).offset(8)
        }

        kaDebugView.snp.makeConstraints { make in
            make.right.top.equalToSuperview()
            make.width.equalTo(50)
            make.height.equalTo(30)
        }
    }

    private func setupAppearance() {
        larkIcon.image = AppResources.ios_icon

        larkName.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        larkName.setContentCompressionResistancePriority(.required, for: .horizontal)

        versionStringLabel.textAlignment = .center
        var version = "V\(Utils.appVersion)"
        if !Utils.omegaVersion.isEmpty {
            version.append("-omega\(LarkFoundation.Utils.omegaVersion)")
        }
        version.append("-\(Utils.buildVersion)")
        versionStringLabel.text = version
        versionStringLabel.lineBreakMode = .byTruncatingTail
        versionStringLabel.isUserInteractionEnabled = true

        /// 版本信息 长按复制版本号
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(self.didLongTapVersionInfo(_:)))
        versionLongTapArea.addGestureRecognizer(longTap)

        /// kaDebugView 点击事件
        let tap = UITapGestureRecognizer(target: self, action: #selector(postKADebugNotification(_:)))
        tap.numberOfTapsRequired = 3
        kaDebugView.addGestureRecognizer(tap)
    }

    @objc
    private func postKADebugNotification(_ gesture: UITapGestureRecognizer) {
        NotificationCenter.default.post(name: .init(rawValue: "__ka_debug_notification"), object: nil)
    }

    @objc
    private func didLongTapVersionInfo(_ gesture: UILongPressGestureRecognizer) {
        if gesture.view != nil {
            do {
                let config = PasteboardConfig(token: Token("LARK-PSDA-app_about_lark_page_copy_version_info"))
                try SCPasteboard.generalUnsafe(config).string = versionStringLabel.text ?? ""
                if let parentView = self.parentViewController?.view {
                    UDToast.showTips(with: BundleI18n.LarkMine.Lark_Legacy_CopiedToast, on: parentView)
                }
            } catch {
                // 复制失败兜底逻辑
            }
        }
    }

}

extension UIView {

    var parentViewController: UIViewController? {
        weak var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

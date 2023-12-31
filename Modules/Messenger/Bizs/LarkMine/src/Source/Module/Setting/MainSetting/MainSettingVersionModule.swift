//
//  MainSettingVersionModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/19.
//

import Foundation
import UIKit
import LarkAccountInterface
import UniverseDesignToast
import LarkSetting
import LarkContainer
import LarkFoundation
import LarkOpenSetting
import LarkSettingUI
import LarkEMM
import LarkSensitivityControl

final class MainSettingVersionModule: BaseModule {
    private var passportUserService: PassportUserService?
    private var deviceService: DeviceService?

    override func createFooterProp(_ key: String) -> HeaderFooterType? {
        return .custom({ self.versionFooter })
    }

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        self.passportUserService = try? self.userResolver.resolve(assert: PassportUserService.self)
        self.deviceService = try? self.userResolver.resolve(assert: DeviceService.self)
    }

    lazy var versionFooter: UITableViewHeaderFooterView = { [weak self] in
        let view = UITableViewHeaderFooterView()
        guard let self = self else { return view }
        let versionTextView: UITextView = UITextView()

        var version = "\(BundleI18n.LarkMine.Lark_NewSettings_AboutFeishuCurrentVersionMobile) V\(Utils.appVersion)"
        if !Utils.omegaVersion.isEmpty {
            version.append("-omega\(LarkFoundation.Utils.omegaVersion)")
        }
        version.append("-\(Utils.buildVersion)")
        versionTextView.backgroundColor = UIColor.clear
        versionTextView.text = version
        versionTextView.isSelectable = false
        versionTextView.isEditable = false
        versionTextView.isScrollEnabled = false
        versionTextView.textAlignment = .center
        versionTextView.font = UIFont.systemFont(ofSize: 12)
        versionTextView.textColor = UIColor.ud.textPlaceholder
        versionTextView.tag = 1000
        view.contentView.addSubview(versionTextView)
        versionTextView.snp.makeConstraints { (make) in
            make.top.equalTo(7)
            make.height.equalTo(92)
            make.leading.trailing.equalToSuperview()
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        // 字节用户且FG打开，才可以连续点击三次
        let featureGatingService = try? self.userResolver.resolve(assert: FeatureGatingService.self)
        if featureGatingService?.dynamicFeatureGatingValue(with: .versionDisplayBugfix) ?? false {
            // 添加连续点击3次手势
            let threeTap = UITapGestureRecognizer(target: self, action: #selector(self.didThreeTapVersionInfo(_:)))
            threeTap.numberOfTapsRequired = 3
            view.addGestureRecognizer(threeTap)
        }

        // 长按点击
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(self.didLongTapVersionInfo(_:)))
        view.addGestureRecognizer(longTap)

        return view
    }()

    @objc
    private func didThreeTapVersionInfo(_ gesture: UITapGestureRecognizer) {
        if let textView: UITextView = gesture.view?.viewWithTag(1000) as? UITextView {
            let device = UIDevice.current
            var text = textView.text ?? ""
            text.append("\n")
            text.append("UID: \(self.passportUserService?.user.userID ?? "")")
            text.append("\n")
            text.append("DID: \(self.deviceService?.deviceId ?? "")")
            text.append("\n")
            text.append("OS: \(device.systemName) \(device.systemVersion)")
            textView.text = text
            // 需要保证行间距，所以改用attributedText展示
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 3
            style.alignment = .center
            let attributedString = NSMutableAttributedString(string: text)
            let range = NSRange(location: 0, length: text.utf16.count)
            attributedString.addAttribute(.paragraphStyle, value: style, range: range)
            attributedString.addAttribute(.foregroundColor, value: UIColor.ud.textPlaceholder, range: range)
            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 12), range: range)
            textView.attributedText = attributedString
            if saveVersionInfoToClipboard(text) {
                if let vc = self.context?.vc, let window = vc.view.window {
                    UDToast.showTips(with: BundleI18n.LarkMine.Lark_Legacy_CopiedToast, on: window)
                }
            }
        }
        gesture.view?.removeGestureRecognizer(gesture)
    }

    @objc
    private func didLongTapVersionInfo(_ gesture: UILongPressGestureRecognizer) {
        if let textView: UITextView = gesture.view?.viewWithTag(1000) as? UITextView {
            if saveVersionInfoToClipboard(textView.text ?? "") {
                if let vc = self.context?.vc, let window = vc.view.window {
                    UDToast.showTips(with: BundleI18n.LarkMine.Lark_Legacy_CopiedToast, on: window)
                }
            }
        }
    }

    private func saveVersionInfoToClipboard(_ info: String) -> Bool {
        do {
            let config = PasteboardConfig(token: Token("LARK-PSDA-app_setting_page_copy_version_info"))
            try SCPasteboard.generalUnsafe(config).string = info
            return true
        } catch {
            // 业务兜底逻辑
            return false
        }
    }
}

//
//  OPNoticeView+UDNotice.swift
//  TTMicroApp
//
//  Created by ChenMengqi on 2021/8/5.
//

import Foundation
import UniverseDesignNotice
import UniverseDesignIcon
import UniverseDesignColor
import EENavigator
import OPFoundation
import SnapKit

@objc public extension OPNoticeView {
    func createNoticeView(tipInfo: String , url:String?) -> UIView {
        let adminNotif:String  = BDPI18n.suiteAdminFrontend_Workplace_AdminNotif2 ?? ""
        var totalTipInfo: String
        var attributedText: NSMutableAttributedString
        if let url = url {
            let viewDetailBtn :String = BDPI18n.suiteAdminFrontend_Workplace_ViewNotifDetailsBtn ?? ""
            totalTipInfo = "\(adminNotif): \(tipInfo) \(viewDetailBtn)"
            attributedText = NSMutableAttributedString(string: totalTipInfo, attributes: [.foregroundColor: UIColor.ud.textTitle])
            //泰语不能直接用adminNotif.count，跟addAttribute的length会有差异，英语和中文没问题。 所以统一切换为 utf编码/4来计算
            //bug meego:  https://meego.feishu.cn/larksuite/issue/detail/12424717
            let adminNotifLength = adminNotif.lengthOfBytes(using: .utf32)/4
            attributedText.addAttribute(.link, value: "", range: NSRange(location: 0, length: adminNotifLength))
            let viewButtonLength = viewDetailBtn.lengthOfBytes(using: .utf32)/4
            attributedText.addAttribute(.link, value: url, range: NSRange(location: attributedText.length-viewButtonLength, length: viewButtonLength))
        } else {
            totalTipInfo = "\(adminNotif): \(tipInfo)"
            attributedText = NSMutableAttributedString(string: totalTipInfo, attributes: [.foregroundColor: UIColor.ud.textTitle])
            let adminNotifLength = adminNotif.lengthOfBytes(using: .utf32)/4
            attributedText.addAttribute(.link, value: "", range: NSRange(location: 0, length: adminNotifLength))
        }
        var config = UDNoticeUIConfig(type: .info, attributedText: attributedText)
        config.trailingButtonIcon = UDIcon.getIconByKey(.closeOutlined, renderingMode: .automatic, iconColor: UDColor.iconN2, size: CGSize(width: 24, height: 24))
        config.leadingIcon = UDIcon.getIconByKey(.boardsFilled, renderingMode: .automatic, iconColor: UDColor.functionInfoContentDefault, size: CGSize(width: 24, height: 24))
        let noticeView = UDNotice(config: config)
        noticeView.delegate = self
        addSubview(noticeView)
        if isAutoLayout {
            noticeView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
        let noticeViewSize = noticeView.sizeThatFits(self.bounds.size)
        noticeView.frame = CGRect(x: 0, y: 0, width: noticeViewSize.width, height: noticeViewSize.height)
        }
        return noticeView
    }
}

extension OPNoticeView: UDNoticeDelegate{
    public func handleLeadingButtonEvent(_ button: UIButton) {
        
    }
    
    public func handleTrailingButtonEvent(_ button: UIButton) {
        self.didClose()
        self.removeFromSuperview()
    }
    
    public func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
        print(URL.absoluteString)
        if URL.absoluteString == "" {
            self.showMask()
        } else {
            let navigation =  OPNavigatorHelper.topmostNav(window: window)
            if let topVC = navigation {
                Navigator.shared.push(URL, from: topVC)
            }
        }
    }
}

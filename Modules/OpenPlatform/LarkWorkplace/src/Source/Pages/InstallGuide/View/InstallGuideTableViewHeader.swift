//
//  InstallGuideTableViewHeader.swift
//  LarkWorkplace
//
//  Created by tujinqiu on 2020/3/18.
//

import UIKit
import LarkLocalizations

// 工作台onboarding上方的文字需要跟随一起滚动，因此作为tableview的header
final class InstallGuideTableViewHeader: UIView {
    /// 单行标题时的Header高度
    static let singleLineHeight: CGFloat = 64
    /// 多行标题时的Header高度
    static let multiLinesHeight: CGFloat = 92

    private static let commonSizeForCN: CGFloat = 20    // 正常中文字体大小
    private static let commonSizeForNonCN: CGFloat = 18 // 正常非中文字体大小
    private static let largeSizeForCN: CGFloat = 22     // 大号中文字体大小
    private static let largeSizeForNonCN: CGFloat = 20  // 大号非中文字体大小
    private let tipLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    var attributedText: NSAttributedString {
        didSet {
            tipLabel.attributedText = attributedText
        }
    }

    init() {
        self.attributedText = NSAttributedString()

        super.init(frame: .zero)

        backgroundColor = UIColor.ud.bgBody

        addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(5)
        }
        let backgroundView = getBackgroundView()
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        sendSubviewToBack(backgroundView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func getAttributedText(_ str: String, _ range: NSRange) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 8
        let commonSize = LanguageManager.currentLanguage == .zh_CN ? 20 : 18
        let largeSize = LanguageManager.currentLanguage == .zh_CN ? 22 : 18
        let attrs1 = [
            // font 使用 ud token 初始化
            // swiftlint:disable init_font_with_token
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: CGFloat(commonSize)),
            // swiftlint:enable init_font_with_token
            NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle,
            NSAttributedString.Key.paragraphStyle: style
        ]
        let attrs2 = [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: CGFloat(largeSize)),
            NSAttributedString.Key.foregroundColor: UIColor.ud.primaryContentDefault,
            NSAttributedString.Key.paragraphStyle: style
        ]
        let muteAttributedText = NSMutableAttributedString(string: str, attributes: attrs1)
        muteAttributedText.setAttributes(attrs2, range: range)

        return muteAttributedText
    }

    /// 设计稿：https://www.figma.com/file/EnlAeTFHgEVSBfXgcx0EuP/%E5%B7%A5%E4%BD%9C%E5%8F%B0-%E5%BA%94%E7%94%A8%E6%9B%9D%E5%85%89?node-id=394%3A0
    /// 获取带水印的背景
    private func getBackgroundView() -> UIView {
        let bgView = UIView()

        let littleCycle = UIImageView()
        littleCycle.backgroundColor = .clear
        littleCycle.image = Resources.onboarding_background_dot
        littleCycle.contentMode = .scaleAspectFit
        bgView.addSubview(littleCycle)
        littleCycle.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.width.height.equalTo(34)
            make.right.equalToSuperview().offset(-113)
        }

        /// 打包📦资源有问题🤨，暂不使用
        let bigCycle = UIImageView()
        bigCycle.backgroundColor = .clear
        bigCycle.image = Resources.onboarding_background_circle
        bigCycle.contentMode = .scaleAspectFit
        bgView.addSubview(bigCycle)
        bigCycle.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.right.equalToSuperview().offset(7)
            make.height.width.equalTo(98)
        }
        return bgView
    }
}

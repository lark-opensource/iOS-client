//
//  LogConsoleController.swift
//  LarkWorkplace
//
//  Created by chenziyi on 2021/7/21.
//

import Foundation
import UIKit
import LarkUIKit
import ECOProbe
import LKCommonsLogging
import UniverseDesignTabs
import UniverseDesignFont

/// 调试面板对应的VC
final class LogConsoleController: UIViewController {
    static let logger = Logger.log(LogConsoleController.self)

    /// 清理日志回调
    var onLogClear: (() -> Void)?

    /// 面板的label
    private let logLabel = UILabel()

    /// 面板内的button
    private let clearButton = UIButton()
    private let hideButton = UIButton()
    private let buttonContainerView = UIView()

    /// ud的tabs组件
    private var logTabsView = UDTabsTitleView()
    private let indicator = UDTabsIndicatorLineView()

    /// 显示log的view
    private let logMsgView = LogTextView()

    /// log 数据
    private var logItems: [WPBlockLogMessage] = []

    /// log清空后展示的image
    private let emptyStatusView: WPPageStateView = {
        WPPageStateView()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)

        /// 刷新UI
        autoRefreshUI(currentSelectedIndex: logTabsView.selectedIndex)
        scrollToBottom()
    }
/**
     private func setup*()配置UI控件
     */
    private func setupView() {
        self.view.addSubview(logLabel)
        self.view.addSubview(logTabsView)
        self.view.addSubview(emptyStatusView)
        self.view.addSubview(logMsgView)

        buttonContainerView.addSubview(clearButton)
        buttonContainerView.addSubview(hideButton)
        self.view.addSubview(buttonContainerView)

        self.view.backgroundColor = UIColor.ud.bgBody
        self.view.layer.cornerRadius = 10

        setupLogLabel()
        setupTabsView()
        setupLogMsgView()
        setupButton()
    }

    private func setupConstraints() {
        logLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(50)
        }
        logTabsView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(logLabel.snp.bottom)
            make.height.equalTo(44)
        }
        buttonContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(44)
        }
        clearButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        hideButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(clearButton.snp.right).offset(16)
            make.right.equalToSuperview().inset(16)
            make.width.equalTo(clearButton.snp.width)
        }
        emptyStatusView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(logTabsView.snp.bottom)
            make.bottom.equalTo(buttonContainerView.snp.top).offset(-10)
        }
        logMsgView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(logTabsView.snp.bottom)
            make.bottom.equalTo(buttonContainerView.snp.top).offset(-10)
        }
    }

    private func setupLogLabel() {
        logLabel.text = "Log"
        logLabel.textColor = UIColor.ud.textTitle
        logLabel.textAlignment = .left
        logLabel.font = UDFont.title1
    }

    private func setupTabsView() {
        logTabsView.titles = ["All", "Info", "Warn", "Error"]

        let tabsViewConfig = logTabsView.getConfig()

        /// UDFont暂时无法满足要求，自定义Font
        // swiftlint:disable init_font_with_token
        tabsViewConfig.titleNormalFont = UIFont.systemFont(ofSize: 20, weight: .regular)
        tabsViewConfig.titleSelectedFont = UIFont.systemFont(ofSize: 22, weight: .medium)
        // swiftlint:enable init_font_with_token

        /// UDTabsView基本配置
        tabsViewConfig.layoutStyle = .average
        tabsViewConfig.itemSpacing = 0
        tabsViewConfig.contentEdgeInsetLeft = 0
        logTabsView.setConfig(config: tabsViewConfig)

        logTabsView.layer.borderWidth = 0.8
        logTabsView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        logTabsView.delegate = self

        /// 配置指示器
        indicator.indicatorHeight = 2
        indicator.indicatorCornerRadius = 0
        logTabsView.indicators = [indicator]
    }

    private func setupLogMsgView() {
        logMsgView.isSelectable = true
        logMsgView.isEditable = false
    }

    private func setupButton() {
        clearButton.setTitle("Clear Log", for: .normal)
        clearButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        clearButton.layer.borderWidth = 1.5
        clearButton.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)

        hideButton.setTitle("Hide", for: .normal)
        hideButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        hideButton.layer.borderWidth = 1.5
        hideButton.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)

        clearButton.layer.cornerRadius = 5
        clearButton.addTarget(self, action: #selector(clearLog), for: .touchUpInside)

        hideButton.layer.cornerRadius = 5
        hideButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
    }

    /// 清空数据源数据
    @objc private func clearLog() {
        logItems.removeAll()
        autoRefreshUI(currentSelectedIndex: logTabsView.selectedIndex)

        onLogClear?()
    }

    @objc private func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }

    func appendLog(logItem: WPBlockLogMessage) {
        logItems.append(logItem)
        autoRefreshUI(currentSelectedIndex: logTabsView.selectedIndex)
    }

    /// 自动划到最底
    private func scrollToBottom() {
        // swiftlint:disable empty_count
        guard logMsgView.text.count > 0 else {
            // swiftlint:enable empty_count
            return
        }

        let loc = logMsgView.text.count - 1
        logMsgView.scrollRangeToVisible(NSRange(location: loc, length: 1))
    }

/**
     private func autoRefreshUI(currentSelectedIndex: Int)：
        处理无tab切换的情景下，log的自动刷新问题。会在三种情况下触发：1. logconsoleview重新appear 2. 数据源更新 3. log清空后再次生成新log

     func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int)：（L358）
     仅处理切换tab时的UI刷新，更新场景和autoRefreshUI的三种情况均无冲突

     private func refreshUI(level: OPBlockDebugLogLevel?)：
        刷新UI的功能函数

*/

    private func refreshUI(level: WPBlockLogMessage.Level?) {
        let logs: [WPBlockLogMessage]
        if let lv = level {
            logs = logItems.filter({ $0.level == lv })
            logMsgView.updateLogs(logs, showLevel: false)
        } else {
            logs = logItems
            logMsgView.updateLogs(logs, showLevel: true)
        }
        emptyStatusView.state = (logs.isEmpty ? .noContent : .hidden)
        scrollToBottom()
    }

    private func autoRefreshUI(currentSelectedIndex: Int) {

        switch currentSelectedIndex {
        case 0:
            // nil代表要展示all
            refreshUI(level: nil)
            break
        case 1:
            refreshUI(level: .info)
            break
        case 2:
            refreshUI(level: .warn)
            break
        case 3:
            refreshUI(level: .error)
            break
        default:
            Self.logger.info("Unsupported level type")
        }
    }
}

extension LogConsoleController: UDTabsViewDelegate {
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        switch index {
        case 0:
            Self.logger.info("select all message")
            // nil代表要展示all
            refreshUI(level: nil)
            break
        case 1:
            Self.logger.info("select info message")
            refreshUI(level: .info)
            break
        case 2:
            Self.logger.info("select warn message")
            refreshUI(level: .warn)
            break
        case 3:
            Self.logger.info("select error message")
            refreshUI(level: .error)
            break
        default:
            Self.logger.info("Unsupported debug info type")
            break
        }
    }
}

private final class LogTextView: UITextView {
    /// 展示 Log 时是否要带上 Level 作为 Prefix
    private var showLevel = false

    /// Log 数据源
    private var logs: [WPBlockLogMessage] = [] {
        didSet {
            if let lines = lineLayer.sublayers {
                for line in lines {
                    line.removeFromSuperlayer()
                }
            }

            var displayText: String = ""
            var baseH: CGFloat = 0
            for log in logs {
                let str = log.formatString(withLevel: showLevel)

                // 这里需要补个 "\n"，划线的位置才对（Why?）
                displayText += (str + "\n")

                var textWidth = bounds.width
                textWidth -= textContainerInset.left
                textWidth -= textContainerInset.right
                textWidth -= contentInset.left
                textWidth -= contentInset.right
                // 注意：要减去这个，不然计算的值不对（iPhone11 Pro Max = 5.0）
                textWidth -= textContainer.lineFragmentPadding * 2.0

                let boxSize = CGSize(width: textWidth, height: .greatestFiniteMagnitude)

                let textSize = str.boundingRect(
                    with: boxSize,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: textAttrs,
                    context: nil
                )

                let textH = textSize.height

                let line = CALayer()
                lineLayer.addSublayer(line)
                line.ud.setBackgroundColor(UIColor.ud.lineDividerDefault)
                line.frame = CGRect(
                    x: 0,
                    y: baseH + textH,
                    width: contentSize.width,
                    height: 1.0
                )
                baseH += textH
            }
            attributedText = NSAttributedString(string: displayText, attributes: textAttrs)

            setNeedsLayout()
        }
    }

    // 专门用来添加分割线的 Layer
    private lazy var lineLayer: CALayer = {
        let ins = CALayer()
        ins.backgroundColor = UIColor.clear.cgColor
        return ins
    }()

    /// 段落格式
    private var textParagraphStyle: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        return style
    }()

    /// 字体格式
    private var textFont: UIFont = {
        UIFont.systemFont(ofSize: 14)
    }()

    /// 属性字符串格式
    private var textAttrs: [NSAttributedString.Key: Any] {[
        NSAttributedString.Key.font: textFont,
        NSAttributedString.Key.foregroundColor: UIColor.ud.textCaption,
        NSAttributedString.Key.paragraphStyle: textParagraphStyle
    ]}

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        layer.addSublayer(lineLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 更新 Log 内容
    /// - Parameters:
    ///   - logs: log 数据
    ///   - showLevel: 展示 Log 时是否要带上 Level 作为 Prefix
    func updateLogs(_ logs: [WPBlockLogMessage], showLevel: Bool = false) {
        self.showLevel = showLevel
        self.logs = logs
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        lineLayer.frame = CGRect(origin: .zero, size: bounds.size)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // 主题变更，需要刷新下 attributedText 的 foregroundColor
        setNeedsLayout()
    }
}

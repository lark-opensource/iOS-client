//
//  LoggerConsole.swift
//  Lark
//
//  Created by Sylar on 2017/11/1.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

final class LoggerTagListView: UIView {
    var isActive = false
}

open class LoggerConsole: UIViewController {

    public static let shared = LoggerConsole()

    enum LogLevel: String {
        case severe, error, debug, warning, info, verbose, fatal
    }

    struct LogItem {
        var level: LogLevel = .info
        var tags: Set<String> = []
        var logText: NSAttributedString
    }

    private var animating = false
    public var consoleView: UITableView = .init(frame: .zero)
    private var inputField: UITextField?

    private var tagView: LoggerTagListView?
    fileprivate let cellID = NSStringFromClass(UITableViewCell.self)

    private let welcomeText = "ꉂ ೭(˵¯̴͒ꇴ¯̴͒˵)౨”, Octopus!"
    private var logItems: [LogItem] = []
    private lazy var rwlock: pthread_rwlock_t = {
        var l = pthread_rwlock_t()
        pthread_rwlock_init(&l, nil)
        return l
    }()

    private var logTags: [String]  = ["Close", "Server", "Error", "Debug", "Warning", "Info", "Verbose", "Fatal"]
    private var filterWords: String = ""
    private var selectedLogTags: Set<String>  = []
    private var selectedLevels: Set<LogLevel> = []

    private var displayItems: [LogItem] = []

    public static func show() {
        LoggerConsole.shared.showConsole()
    }

    static func hide() {
        LoggerConsole.shared.hideConsole()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.clipsToBounds = true
        self.view.backgroundColor = .black
        self.view.autoresizesSubviews = true

        // Console View
        consoleView = UITableView(frame: CGRect(x: 0, y: 20, width: self.view.frame.size.width, height: self.view.frame.size.height - 64), style: .plain)
        consoleView.delegate = self
        consoleView.dataSource = self
        consoleView.backgroundColor = .black
        consoleView.separatorColor = .clear
        consoleView.separatorStyle = .none
        consoleView.showsVerticalScrollIndicator = true
        self.view.addSubview(consoleView)

        // Action Button
        let textColor = UIColor.white
        let actionButton = UIButton(type: .custom)
        actionButton.setTitle("⛄️", for: .normal)
        actionButton.setTitleColor(textColor, for: .normal)
        actionButton.setTitleColor(textColor.withAlphaComponent(0.5), for: .highlighted)
        actionButton.frame = CGRect(x: self.view.frame.size.width - 36, y: self.view.frame.size.height - 36, width: 36, height: 36)
        actionButton.addTarget(self, action: #selector(hideConsole), for: .touchUpInside)
        actionButton.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin]
        self.view.addSubview(actionButton)

        // Filter Button
        let filterButton = UIButton(type: .custom)
        filterButton.setTitle("🍀", for: .normal)
        filterButton.setTitleColor(textColor, for: .normal)
        filterButton.setTitleColor(textColor.withAlphaComponent(0.5), for: .highlighted)
        filterButton.frame = CGRect(x: self.view.frame.size.width - 36 * 2, y: self.view.frame.size.height - 36, width: 36, height: 36)
        filterButton.addTarget(self, action: #selector(showTagView), for: .touchUpInside)
        filterButton.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin]
        self.view.addSubview(filterButton)

        let inputField = UITextField(frame: CGRect(x: 4, y: self.view.frame.size.height - 36, width: self.view.frame.size.width - 36 * 2 - 4, height: 32))
        inputField.delegate = self
        inputField.borderStyle = .roundedRect
        inputField.font = UIFont(name: "Courier", size: 15)
        inputField.autocapitalizationType = .none
        inputField.autocorrectionType = .no
        inputField.returnKeyType = .done
        inputField.enablesReturnKeyAutomatically = false
        inputField.clearButtonMode = .whileEditing
        inputField.contentVerticalAlignment = .center
//        inputField.isEnabled = false
        inputField.placeholder = "Filter"//"Enter command..."
        inputField.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        self.view.addSubview(inputField)
        self.inputField = inputField

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        self.updateConsoleText()
    }

    fileprivate func closeKeyboard() {
        guard let inputField else {
            return
        }
        if inputField.isFirstResponder {
            inputField.resignFirstResponder()
        }
    }

    fileprivate func setConsoleText(logItems: [LogItem]) {
        displayItems.removeAll()
        displayItems.append(contentsOf: logItems)
        consoleView.reloadData()

        if !logItems.isEmpty {
            let indexPath = IndexPath(row: logItems.count - 1, section: 0)
            consoleView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    public func severe(_ log: String, tags: Set<String> = []) {
        self.appendLogs("[Severe].\(log)", logLevel: .severe, color: .magenta, tags: tags)
    }

    public func error(_ log: String, tags: Set<String> = []) {
        self.appendLogs("[Error].\(log)", logLevel: .error, color: .red, tags: tags)
    }

    public func debug(_ log: String, tags: Set<String> = []) {
        self.appendLogs("[Debug].\(log)", logLevel: .debug, tags: tags)
    }

    public func info(_ log: String, tags: Set<String> = []) {
        self.appendLogs("[Info].\(log)", logLevel: .info, color: .blue, tags: tags)
    }

    public func verbose(_ log: String, tags: Set<String> = []) {
        self.appendLogs("[Verbose].\(log)", logLevel: .verbose, color: .purple, tags: tags)
    }

    public func warning(_ log: String, tags: Set<String> = []) {
        self.appendLogs("[Warn].\(log)", logLevel: .warning, color: .orange, tags: tags)
    }

    public func fatal(_ log: String, tags: Set<String> = []) {
        self.appendLogs("[Fatal].\(log)", logLevel: .fatal, color: .red, tags: tags)
    }

    func appendLogs(_ log: String, logLevel: LogLevel, color: UIColor = .white, tags: Set<String>) {
        let contentText = "🐙.\(log) - [Tag:\(tags.joined(separator: ", "))]"     //🍀👾👩🏻‍🎓💂🏻
        let contentFont = UIFont(name: "Courier", size: 14) ?? .systemFont(ofSize: 14)
        let paragraphStyle = NSMutableParagraphStyle()
//        paragraphStyle.paragraphSpacingBefore = 5;
//        paragraphStyle.lineSpacing = 3
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        paragraphStyle.lineBreakMode = .byWordWrapping
        let attri: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: color,
            .font: contentFont
        ]
        let logText = NSAttributedString(string: contentText, attributes: attri)
        let item = LogItem(level: logLevel, tags: tags, logText: logText)
        pthread_rwlock_wrlock(&rwlock)
        self.logItems.append(item)
        pthread_rwlock_unlock(&rwlock)

        if !tags.isEmpty {
            for tag in tags where !tag.isEmpty {
                if self.logTags.contains(tag) == false {
                    self.logTags.append(tag)
                }
            }
        }

//        self.updateConsoleText()
    }

    func transform(levle: String) -> LogLevel {
        var logLevel: LogLevel = .info
        if levle == "severe" {
            logLevel = .severe
        } else if levle == "error" {
            logLevel = .error
        } else if levle == "debug" {
            logLevel = .debug
        } else if levle == "warning" {
            logLevel = .warning
        } else if levle == "info" {
            logLevel = .info
        } else if levle == "verbose" {
            logLevel = .verbose
        } else if levle == "fatal" {
            logLevel = .fatal
        }
        return logLevel
    }

    func description(level: LogLevel) -> String {
        switch level {
        case .severe: return "Severe"
        case .error: return "Error"
        case .debug: return "Debug"
        case .warning: return "Warning"
        case .info: return "Info"
        case .verbose: return "Verbose"
        case .fatal: return "Fatal"
        }
    }

    func updateConsoleText() {
        var newLogItems: [LogItem]
        if self.selectedLogTags.isEmpty {
            pthread_rwlock_rdlock(&rwlock)
            newLogItems = self.logItems
            pthread_rwlock_unlock(&rwlock)
//            self.setConsoleText(logItems: self.logItems)
        } else {
            pthread_rwlock_rdlock(&rwlock)
            newLogItems = self.logItems.filter { (logItem) -> Bool in
                return !logItem.tags.isDisjoint(with: self.selectedLogTags) ||
                    self.selectedLogTags.contains(self.description(level: logItem.level))
            }
            pthread_rwlock_unlock(&rwlock)
        }
        if !self.filterWords.isEmpty {
            newLogItems = newLogItems.filter({ (logItem) -> Bool in
                return logItem.logText.string.lowercased().contains(self.filterWords.lowercased())
            })
        }
        self.setConsoleText(logItems: newLogItems)
    }

    @objc
    fileprivate func showActions() {
        self.findAndResignFirstResponder(view: self.mainWindow())

        let alertController = UIAlertController(title: "Octopus", message: nil, preferredStyle: .actionSheet)
//        let sendEmailAction = UIAlertAction(title: "Send by Email", style: UIAlertActionStyle.default, handler: nil)
        let clearAction = UIAlertAction(title: "Category Filter", style: .default) { (_) in
            self.showTagView()
        }
        let closeAction = UIAlertAction(title: "Close Console", style: .destructive) { (_) in
            self.hideConsole()
        }
//        alertController.addAction(sendEmailAction)
        alertController.addAction(clearAction)
        alertController.addAction(closeAction)
        self.present(alertController, animated: true)
    }

    fileprivate func resetConsole() {
        pthread_rwlock_wrlock(&rwlock)
        self.logItems.removeAll()
        self.info(welcomeText)
        self.setConsoleText(logItems: self.logItems)
        pthread_rwlock_unlock(&rwlock)
    }

    fileprivate func showConsole() {
        if !animating, self.view.superview == nil {
          pthread_rwlock_rdlock(&rwlock)
          self.setConsoleText(logItems: self.logItems)
          pthread_rwlock_unlock(&rwlock)
          self.findAndResignFirstResponder(view: self.mainWindow())

          LoggerConsole.shared.view.frame = self.offScreenFrame()
          self.mainWindow()?.addSubview(LoggerConsole.shared.view)

          animating = true
          UIView.beginAnimations(nil, context: nil)
          UIView.setAnimationDuration(0.25)
          UIView.setAnimationDelegate(self)
          UIView.setAnimationDidStop(#selector(consoleShown))
          LoggerConsole.shared.view.frame = self.onScreenFrame()
          LoggerConsole.shared.view.transform = self.viewTransForm()
          UIView.commitAnimations()
        }
    }

    @objc
    fileprivate func hideConsole() {
        if !animating, self.view.superview != nil {

            self.findAndResignFirstResponder(view: self.mainWindow())

            animating = true
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(0.25)
            UIView.setAnimationDelegate(self)
            UIView.setAnimationDidStop(#selector(consoleHidden))
            LoggerConsole.shared.view.frame = self.offScreenFrame()
            UIView.commitAnimations()
        }
    }

    fileprivate func mainWindow() -> UIWindow? {
        if let window = UIApplication.shared.delegate?.window {
            return window
        } else {
            return UIApplication.shared.keyWindow
        }
    }

    fileprivate func onScreenFrame() -> CGRect {
        return UIScreen.main.bounds
    }

    fileprivate func offScreenFrame() -> CGRect {
        var frame = self.onScreenFrame()
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            frame.origin.y = frame.size.height
        case .portraitUpsideDown:
            frame.origin.y = -frame.size.height
        case .landscapeLeft:
            frame.origin.x = frame.size.width
        case .landscapeRight:
            frame.origin.x = -frame.size.width
        default:
            break
        }
        return frame
    }

    fileprivate func viewTransForm() -> CGAffineTransform {
        var angle: CGFloat = 0.0
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            angle = 0
        case .portraitUpsideDown:
            angle = .pi
        case .landscapeLeft:
            angle = -.pi / 2
        case .landscapeRight:
            angle = .pi / 2
        default:
            break
        }
        return CGAffineTransform(rotationAngle: angle)
    }

    @discardableResult
    fileprivate func findAndResignFirstResponder(view: UIView?) -> Bool {
        guard let view else { return false }
        if view.isFirstResponder {
            view.resignFirstResponder()
            return true
        }
        for subview in view.subviews {
            if self.findAndResignFirstResponder(view: subview) {
                return true
            }
        }
        return false
    }

    @objc
    fileprivate func consoleShown() {
        animating = false
        self.findAndResignFirstResponder(view: self.mainWindow())
    }

    @objc
    fileprivate func consoleHidden() {
        animating = false
        LoggerConsole.shared.view.removeFromSuperview()
    }

    @objc
    fileprivate func keyboardWillShow(notification: Notification) {
        if let userInfo = notification.userInfo {
            guard let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0
            //      let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! Int

            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationBeginsFromCurrentState(true)
            UIView.setAnimationDuration(duration)
            UIView.setAnimationCurve(.easeInOut)

            var bounds = self.onScreenFrame()
            switch UIApplication.shared.statusBarOrientation {
            case .portrait:
                bounds.size.height -= frame.size.height
            case .portraitUpsideDown:
                bounds.origin.y += frame.size.height
                bounds.size.height -= frame.size.height
            case .landscapeLeft:
                bounds.size.width -= frame.size.width
            case .landscapeRight:
                bounds.origin.x += frame.size.width
                bounds.size.width -= frame.size.width
            default:
                break
            }
            self.view.frame = bounds
            UIView.commitAnimations()
        }
    }

    @objc
    fileprivate func keyboardWillHide(notification: Notification) {
        if let userInfo = notification.userInfo {
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationBeginsFromCurrentState(true)
            UIView.setAnimationDuration(duration)
            UIView.setAnimationCurve(.easeInOut)
            self.view.frame = self.onScreenFrame()
            UIView.commitAnimations()
        }
    }

    // MARK: - Tag View
    @objc
    func showTagView() {
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height / 2

        let font = UIFont(name: "Courier", size: 16) ?? .systemFont(ofSize: 16)
        let borderWidth: CGFloat = 1
        let cornerRadius: CGFloat = 12

        // background view
        let tagView = LoggerTagListView(frame: CGRect(x: 0, y: height * 2, width: width, height: height))
        tagView.backgroundColor = .clear
        self.view.addSubview(tagView)
        // blur view
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame.size = CGSize(width: width, height: height)
        tagView.addSubview(blurView)
        // scroll view
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: height * 0, width: width, height: height))
        scrollView.backgroundColor = .clear
        tagView.addSubview(scrollView)
        self.tagView = tagView

        /// Tag Filter Label
//        let filterLabel = UILabel(frame: CGRect(x: 0, y: 0, width: width / 2, height: 36))
//        filterLabel.text = "Tag Filter"
//        filterLabel.font = font
//        filterLabel.backgroundColor = .clear
//        filterLabel.textColor = .white
//        self.tagView.addSubview(filterLabel)
//
//        /// Reset and Done button
//        let resetBtn = UIButton(frame: CGRect(x: Int(width) - 70 * 2, y: 6, width: 60, height: 28))
//        resetBtn.setTitle("Reset", for: .normal)
//        resetBtn.titleLabel?.font = font
//        resetBtn.backgroundColor = .white
//        resetBtn.setTitleColor(.black, for: .normal)
//        resetBtn.titleLabel?.textAlignment = .center
////        resetBtn.addTarget(self, action: #selector(tagSelected(sender:)), for: .touchUpInside)
//        resetBtn.layer.borderWidth = borderWidth
//        resetBtn.layer.cornerRadius = cornerRadius
//        resetBtn.layer.borderColor = UIColor.white.cgColor
//        self.tagView.addSubview(resetBtn)
//
//        let doneBtn = UIButton(frame: CGRect(x: Int(width) - 70, y: 6, width: 60, height: 28))
//        doneBtn.setTitle("Done", for: .normal)
//        doneBtn.titleLabel?.font = font
//        doneBtn.backgroundColor = .white
//        doneBtn.setTitleColor(.black, for: .normal)
//        doneBtn.titleLabel?.textAlignment = .center
////        resetBtn.addTarget(self, action: #selector(tagSelected(sender:)), for: .touchUpInside)
//        doneBtn.layer.borderWidth = borderWidth
//        doneBtn.layer.cornerRadius = cornerRadius
//        doneBtn.layer.borderColor = UIColor.white.cgColor
//        self.tagView.addSubview(doneBtn)

        var line: CGFloat = 0
        var yOffset: CGFloat = 0
        let space: CGFloat = 12
        let tagHeight: CGFloat = 28
        let borderSpace: CGFloat = 10
        let verticalSpace: CGFloat = 6

        for value in self.logTags {
            let tagWidth = self.getTexWidth(textStr: value, font: font, height: tagHeight)

            let origin: CGPoint
            let size = CGSize(width: tagWidth, height: tagHeight)

            let border = width - borderSpace
            let targetOffset = yOffset + tagWidth + space

            if targetOffset > border {
                line += 1
                let tagY: CGFloat = line * (tagHeight + verticalSpace) + borderSpace
                origin = CGPoint(x: borderSpace, y: tagY)
                yOffset = borderSpace + tagWidth
            } else {
                let tagY: CGFloat = line * (tagHeight + verticalSpace) + borderSpace
                origin = CGPoint(x: yOffset + space, y: tagY)
                yOffset = (yOffset + tagWidth + space)
            }

            let btn = UIButton(frame: CGRect(origin: origin, size: size))
            btn.setTitle(value, for: .normal)
            btn.titleLabel?.font = font
            btn.titleLabel?.textAlignment = .center
            btn.addTarget(self, action: #selector(tagSelected(sender:)), for: .touchUpInside)
            btn.layer.borderWidth = borderWidth
            btn.layer.cornerRadius = cornerRadius

            if self.selectedLogTags.contains(value) {
                btn.backgroundColor = .black
                btn.setTitleColor(.white, for: .normal)
                btn.layer.borderColor = UIColor.black.cgColor
            } else {
                btn.backgroundColor = .white
                btn.setTitleColor(.black, for: .normal)
                btn.layer.borderColor = UIColor.white.cgColor
            }

            if value == "Close" {
                btn.backgroundColor = .black
                btn.setTitleColor(.white, for: .normal)
                btn.layer.borderColor = UIColor.black.cgColor
            }

            scrollView.addSubview(btn)
        }

        scrollView.contentSize = CGSize(width: width, height: (line + 1.0) * (tagHeight + verticalSpace) + borderSpace)

        tagView.isActive = true
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.3)
        tagView.center = CGPoint(x: tagView.center.x, y: tagView.center.y - height)
        UIView.commitAnimations()
    }

    func hideTagView() {
        if let tagView = self.tagView, tagView.isActive {
            tagView.isActive = false
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(0.3)
            let screenHeight = UIScreen.main.bounds.size.height
            tagView.center = CGPoint(x: tagView.center.x, y: screenHeight + tagView.frame.size.height / 2)
            UIView.commitAnimations()
        }
    }

    func getTexWidth(textStr: String, font: UIFont, height: CGFloat) -> CGFloat {
        let size = CGSize(width: CGFloat(MAXFLOAT), height: height)
        let attributes = [NSAttributedString.Key.font: font]
        let stringSize = textStr.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil).size
        return stringSize.width + CGFloat(16)
    }

    func getTextHeight(text: NSAttributedString, width: CGFloat) -> CGFloat {
        let size = CGSize(width: width, height: CGFloat(MAXFLOAT))
        return text.boundingRect(with: size, options: [.usesLineFragmentOrigin], context: nil).size.height + 5
    }

    @objc
    func tagSelected(sender: UIButton) {

        guard let tag = sender.titleLabel?.text else {
            return
        }

        if tag == "Close" {
            self.hideTagView()
            return
        }

        if self.selectedLogTags.contains(tag) {
            sender.backgroundColor = .white
            sender.setTitleColor(.black, for: .normal)
            sender.layer.borderColor = UIColor.white.cgColor
            self.selectedLogTags.remove(tag)
        } else {
            sender.backgroundColor = .black
            sender.setTitleColor(.white, for: .normal)
            sender.layer.borderColor = UIColor.black.cgColor
            self.selectedLogTags.insert(tag)
        }

        self.updateConsoleText()
    }
}

// MARK: - UITextViewDelegate

extension LoggerConsole: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text as NSString? {
            self.filterWords = text.replacingCharacters(in: range, with: string)
        } else {
            self.filterWords = ""
        }
        self.updateConsoleText()
        return true
    }
}

// MARK: - UITableViewDelegate

extension LoggerConsole: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = displayItems[indexPath.row]
        return self.getTextHeight(text: item.logText, width: UIScreen.main.bounds.size.width - 10)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.closeKeyboard()
    }

//    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let pas = UIPasteboard.general
//        let item = displayItems[indexPath.row]
//        pas.string = item.logText.string
//    }
}

// MARK: - UITableViewDataSource

extension LoggerConsole: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = displayItems[indexPath.row]
        let identifier = String(describing: LoggerTableViewCell.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? LoggerTableViewCell {
            cell.textLabel?.attributedText = item.logText
            cell.textLabel?.numberOfLines = 0
            cell.selectionStyle = .none
            cell.contentView.backgroundColor = .black //(indexPath.row % 2) == 0 ? .black : .orange
            return cell
        } else {
            let cell = LoggerTableViewCell(style: .value1, reuseIdentifier: cellID)
            cell.textLabel?.attributedText = item.logText
            cell.textLabel?.numberOfLines = 0
            cell.selectionStyle = .none
            cell.contentView.backgroundColor = .black //(indexPath.row % 2) == 0 ? .black : .orange
            return cell
        }
    }
}

final class LoggerTableViewCell: UITableViewCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.textLabel?.frame = CGRect(x: 5, y: 0, width: UIScreen.main.bounds.size.width - 10, height: self.frame.size.height)
    }
}

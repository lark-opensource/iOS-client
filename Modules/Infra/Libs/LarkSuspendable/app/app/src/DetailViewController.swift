//
//  DetailViewController.swift
//  LarkSuspendableDev
//
//  Created by bytedance on 2021/1/5.
//

import Foundation
import UIKit
import SnapKit
import LarkSuspendable

class DetailViewController: UIViewController {

    var tag: Int
    var color: UIColor

    var uuid: String

    var colors: [UIColor] = [
        .systemRed,
        .systemOrange,
        .systemYellow,
        .systemGreen,
        .systemBlue,
        .systemTeal,
        .systemPurple
    ]

    private lazy var button: UIButton = {
        let button = UIButton()
        button.setTitle("修改 StatusBar 样式", for: .normal)
        button.addTarget(self, action: #selector(changeStatusBarStyle), for: .touchUpInside)
        return button
    }()

    private lazy var jumpLabel: UILabel = {
        let label = UILabel()
        label.text = "模拟页面内容改变，但不切换 VC 的情况"
        return label
    }()

    private lazy var vcStackView1: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        return stack
    }()

    private func makeButton(tag: Int) -> UIButton {
        let button = UIButton()
        button.tag = tag
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.black, for: .normal)
        button.setTitle("\(tag)", for: .normal)
        button.backgroundColor = colors[tag % colors.count]
        button.addTarget(self, action: #selector(switchToDetailController(_:)), for: .touchUpInside)
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        return button
    }

    private lazy var switcher: UISwitch = {
        let mSwitch = UISwitch()
        mSwitch.isOn = false
        // For on state
        mSwitch.onTintColor = .systemGreen
        // For off state*/
        mSwitch.tintColor = .systemGray
        mSwitch.layer.cornerRadius = mSwitch.frame.height / 2.0
        mSwitch.backgroundColor = .systemGray
        mSwitch.clipsToBounds = true
        return mSwitch
    }()

    private lazy var switcherLabel: UILabel = {
        let label = UILabel()
        label.text = "页面内跳转后，视为新页面"
        return label
    }()

    init(tag: Int, color: UIColor, uuid: String? = nil) {
        self.tag = tag
        self.color = color
        self.uuid = uuid ?? UUID().uuidString
        super.init(nibName: nil, bundle: nil)
        print("\(self) init")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("\(self) deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        title = "VC\(tag)"
        title = uuid
        view.backgroundColor = color
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(100)
            make.centerX.equalToSuperview()
        }
        view.addSubview(jumpLabel)
        view.addSubview(vcStackView1)
        view.addSubview(switcher)
        view.addSubview(switcherLabel)
        vcStackView1.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.height.equalTo(40)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
        }
        switcher.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(-100)
            make.bottom.equalTo(vcStackView1.snp.top).offset(-10)
        }
        switcherLabel.snp.makeConstraints { make in
            make.centerY.equalTo(switcher)
            make.leading.equalTo(switcher.snp.trailing).offset(10)
        }
        jumpLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(switcher.snp.top).offset(-10)
        }
        for i in 0..<colors.count {
            vcStackView1.addArrangedSubview(makeButton(tag: i))
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }

    private var statusBarStyle: UIStatusBarStyle = .lightContent

    @objc
    private func changeStatusBarStyle() {
        if statusBarStyle == .lightContent {
            statusBarStyle = .default
        } else {
            statusBarStyle = .lightContent
        }
        setNeedsStatusBarAppearanceUpdate()
    }

    @objc
    private func switchToDetailController(_ sender: UIButton) {
        let prevID = suspendID
        self.tag = sender.tag
        self.color = colors[tag % colors.count]
        view.backgroundColor = color
        title = "VC\(tag)"
        if !switcher.isOn {
            suspendIdentifierDidChange(from: prevID)
        }
    }
}

extension DetailViewController: ViewControllerSuspendable {

    var suspendID: String {
        return String(tag)
    }

    var suspendSourceID: String {
        return uuid
    }

    var suspendURL: String {
        return "//demo/suspend/detailvc"
    }

    var suspendParams: [String: AnyCodable] {
        return [
            "tag": AnyCodable(self.tag),
            "color": AnyCodable(ColorHelper.hexStringFromColor(color: self.color))
        ]
    }

    var suspendIcon: UIImage? {
        return UIImage.from(color: color)
    }

    var suspendTitle: String {
        return title ?? "No title"
    }

    var suspendGroup: SuspendGroup {
        return .chat
    }

    var isWarmStartEnabled: Bool { false }

    var analyticsTypeName: String {
        "detail"
    }
}

extension UIImage {
    static func from(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}

enum ColorHelper {

    static func hexStringFromColor(color: UIColor) -> String {
        let components = color.cgColor.components
        let rvalue: CGFloat = components?[0] ?? 0.0
        let gvalue: CGFloat = components?[1] ?? 0.0
        let bvalue: CGFloat = components?[2] ?? 0.0
        let hexString = String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(rvalue * 255)),
            lroundf(Float(gvalue * 255)),
            lroundf(Float(bvalue * 255))
        )
        return hexString
     }

    static func colorWithHexString(hexString: String) -> UIColor {
        var colorString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        colorString = colorString.replacingOccurrences(of: "#", with: "").uppercased()
        let alpha: CGFloat = 1.0
        let red: CGFloat = colorComponentFrom(colorString: colorString, start: 0, length: 2)
        let green: CGFloat = colorComponentFrom(colorString: colorString, start: 2, length: 2)
        let blue: CGFloat = colorComponentFrom(colorString: colorString, start: 4, length: 2)
        let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        return color
    }

    private static func colorComponentFrom(colorString: String, start: Int, length: Int) -> CGFloat {
        let startIndex = colorString.index(colorString.startIndex, offsetBy: start)
        let endIndex = colorString.index(startIndex, offsetBy: length)
        let subString = colorString[startIndex..<endIndex]
        let fullHexString = length == 2 ? subString : "\(subString)\(subString)"
        var hexComponent: UInt32 = 0
        guard Scanner(string: String(fullHexString)).scanHexInt32(&hexComponent) else {
            return 0
        }
        let hexFloat: CGFloat = CGFloat(hexComponent)
        let floatValue: CGFloat = CGFloat(hexFloat / 255.0)
        return floatValue
    }
}

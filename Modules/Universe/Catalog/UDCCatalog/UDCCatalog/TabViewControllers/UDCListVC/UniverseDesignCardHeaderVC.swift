////
////  UniverseDesignCardHeaderVC.swift
////  UDCCatalog
////
////  Created by Siegfried on 2021/8/23.
////  Copyright © 2021 姚启灏. All rights reserved.
////
//
import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignAvatar
import UniverseDesignFont
import UniverseDesignCardHeader
import SnapKit

class UniverseDesignCardHeaderVC: UIViewController {
    // 调整颜色部分
    /// 消息卡片宽度
    private(set) lazy var width: CGFloat = 300 {
        didSet {
            chatviewChange.header.snp.updateConstraints { make in
                make.width.equalTo(width)
            }
        }
    }
    /// 消息卡片文本
    private(set) lazy var text: String = "测试测试文字测试测试文字测试测试文字测试测试文字测试测试文字测试测试文字测试测试文字测试测试文字测试测试文字测试测试文字测试测试文字测试测试文字测试测试文字测试测试文字测试测试文字测试测试文字测试测试文字" {
        didSet {
            chatviewChange.text = text
        }
    }
    /// 消息卡片颜色
    private(set) lazy var colorHue: UDCardHeaderHue = .blue {
        didSet {
            chatviewChange.header.colorHue = colorHue
        }
    }
    /// 消息卡片内字体颜色
    private(set) lazy var fontColor: UIColor = Font.blueFont {
        didSet {
            chatviewChange.textLabel.textColor = fontColor
        }
    }
    /// 消息卡片字段
    private lazy var chatviewChange = chatView(color: colorHue, fontColor: Font.blueFont, userName: "调整选项，改变消息卡片外形", text: text)
    /// 确认按钮
    private lazy var button: UIButton = {
        let button = UIButton()
        button.setTitle("确认", for: .normal)
        button.titleLabel?.font = UDFont.body2
        button.setTitleColor(UIColor.ud.N00 & UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.backgroundColor = UIColor.ud.primaryContentLoading
        button.addTarget(self, action: #selector(onBtnClicked), for: .touchUpInside)
        return button
    }()
    /// 宽度输入框
    private lazy var widthTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "宽度"
        textField.font = UDFont.body2
        textField.borderStyle = .line
        textField.textAlignment = .center
        return textField
    }()
    /// 文本输入框
    private lazy var labelTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "文本内容"
        textField.font = UDFont.body2
        textField.borderStyle = .line
        textField.textAlignment = .center
        return textField
    }()
    /// 顶部视图
    private lazy var topView = UIView()
    /// 底部视图
    private lazy var bottomView = UIView()
    /// 顶部颜色选择区域
    private lazy var colorsView = UIView()
    /// 表格视图
    private var tableView: UITableView = UITableView(frame: .zero, style: .plain)
    /// 表格展示部分数据源
    private lazy var datasource: [chatView] = []
    /// 颜色选择区域数据源
    private lazy var colorSelections: [UIButton] = []
    // MARK: DataSource
    /// 颜色列表
    private lazy var colorHueList: [UDCardHeaderHue] =
        [.blue, .wathet, .turquoise, .green, .lime, .yellow, .orange, .red, .carmine, .violet, .purple, .indigo, .neural]
    /// 字体颜色列表
    private lazy var fontColorList: [UIColor] =
        [Font.blueFont, Font.wathetFont, Font.TurquoiseFont, Font.greenFont, Font.limeFont, Font.yellowFont,
         Font.orangeFont, Font.redFont, Font.carmineFont, Font.violetFont, Font.purpleFont, Font.indigoFont, Font.deepNeuralFont]
    /// 色相说明列表
    private lazy var userNameList: [String] =
        ["色相 blue", "色相 wathet", "色相 turquoise", "色相 green", "色相 lime", "色相 yellow", "色相 orange", "色相 red", "色相 carmine", "色相 violet", "色相 purple", "色相 indigo", "色相 deep Neural"]
    /// 填充文字列表
    private lazy var textList: [String] =
        ["ESUX海外项目调研-2021第一季度方案", "配置优化专项群", "评审常规会议","设计评审周会","群优化项目的产品评审常规会议",
         "唯实大厦菜单提醒","Oncall P1 工单已经创建[跟进中]","登录操作通知", "中秋礼盒派发通知", "需求角色分配提醒", "你最喜欢下面哪一个风格？请投出宝贵一票", "需求估分到期提醒", "Oncall P1 工单已经创建 [已取消]"]

    // MARK: 初始化
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "UniverseDesignCardHeader"
        self.view.backgroundColor = UIColor.ud.bgBase
        createDataSource()
        self.tableView.separatorStyle = .none
        self.tableView.register(UDHeaderCell.self, forCellReuseIdentifier: "headerCell")
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.backgroundColor = UIColor.ud.bgBase
        setup()
    }

    private func setup() {
        addComponents()
        makeConstraints()
        setAppearance()
    }

    // MARK: 添加组件
    private func addComponents() {
        self.view.addSubview(topView)
        self.view.addSubview(bottomView)
        topView.addSubview(chatviewChange)
        topView.addSubview(widthTextField)
        topView.addSubview(labelTextField)
        topView.addSubview(button)
        topView.addSubview(colorsView)
        colorsViewAddColor()
        bottomView.addSubview(tableView)
    }

    private func colorsViewAddColor() {
        for i in 0...6 {
            colorsView.addSubview(colorSelections[i])
            colorSelections[i].backgroundColor = colorHueList[i].color
            if i != 0 {
                colorSelections[i].snp.makeConstraints { make in
                    make.width.height.equalTo(35)
                    make.top.equalToSuperview().offset(16)
                    make.left.equalTo(colorSelections[i-1].snp.right).offset(12)
//                    make.bottom.equalToSuperview().offset(-47)
                }
            } else {
                colorSelections[i].snp.makeConstraints { make in
                    make.width.height.equalTo(35)
                    make.top.equalToSuperview().offset(16)
                    make.left.equalToSuperview().offset(24)
//                    make.bottom.equalToSuperview().offset(-47)
                }
            }
        }

        for i in 7..<colorSelections.count {
            colorsView.addSubview(colorSelections[i])
            colorSelections[i].backgroundColor = colorHueList[i].color
            if i != 7 {
                colorSelections[i].snp.makeConstraints { make in
                    make.width.height.equalTo(35)
                    make.top.equalToSuperview().offset(67)
                    make.left.equalTo(colorSelections[i-1].snp.right).offset(12)
                    make.bottom.equalToSuperview().offset(-12)
                }
            } else {
                colorSelections[i].snp.makeConstraints { make in
                    make.width.height.equalTo(35)
                    make.top.equalToSuperview().offset(67)
                    make.left.equalToSuperview().offset(24)
                    make.bottom.equalToSuperview().offset(-12)
                }
            }
        }
    }

    // MARK: 约束
    private func makeConstraints() {
        topView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.equalToSuperview().offset(88)
        }

        chatviewChange.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
        }

        widthTextField.snp.makeConstraints { make in
            make.width.equalTo(80)
            make.height.equalTo(32)
            make.top.equalTo(chatviewChange.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(32)
        }

        labelTextField.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(32)
            make.top.equalTo(chatviewChange.snp.bottom).offset(12)
            make.left.equalTo(widthTextField.snp.right).offset(16)
        }

        button.snp.makeConstraints { make in
            make.width.equalTo(96)
            make.height.equalTo(32)
            make.top.equalTo(chatviewChange.snp.bottom).offset(12)
            make.left.equalTo(labelTextField.snp.right).offset(16)
        }

        colorsView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.equalTo(button.snp.bottom).offset(6)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-6)
        }

        bottomView.snp.makeConstraints { make in
            make.top.equalTo(topView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    private func setAppearance() {
        topView.backgroundColor = UIColor.ud.bgBase
        colorsView.backgroundColor = UIColor.ud.bgBase
    }

    /// 创建数据源
    private func createDataSource() {
        for i in 0..<colorHueList.count {
            datasource.append(chatView(color: colorHueList[i], fontColor: fontColorList[i], userName: userNameList[i], text: textList[i]))
            colorSelections.append(createButton(color: colorHueList[i], index: i))
        }
    }

    /// 确认按钮点击事件
    @objc private func onBtnClicked() {
        if let w = widthTextField.text {
            let doubleW = Double(w)
            self.width = CGFloat(doubleW ?? 300)
        }
        if labelTextField.text == "" {
            self.text = "默认文本内容文本标题测试凑字数"
        } else {
            self.text = labelTextField.text!
        }
    }

    // 颜色点击事件
    @objc private func onColorclicked(sender: UIButton) {
        self.colorHue = colorHueList[sender.tag]
        self.fontColor = fontColorList[sender.tag]
    }

    /// 颜色按钮创建
    private func createButton(color: UDCardHeaderHue, index: Int) -> UIButton {
        let btn = UIButton()
        btn.tag = index
        btn.backgroundColor = color.color
        btn.addTarget(self, action: #selector(onColorclicked(sender:)), for: .touchUpInside)
        return btn
    }
}

// MARK: 自定义单个消息视图
class chatView: UIView {

    // MARK: Components
    public var width: CGFloat = 300
    public var color: UDCardHeaderHue
    public var fontColor: UIColor
    public var userName: String
    public var text: String {
        didSet {
            textLabel.text = text
        }
    }

    private lazy var avatar: UDAvatar = {
        let avatar = UDAvatar()
        avatar.image = UIImage(imageLiteralResourceName: "ttmoment.jpeg")
        avatar.configuration.style = .circle
        return avatar
    }()

    public lazy var userLabel: UILabel = {
        let label = UILabel()
        label.text = userName
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UDFont.body2
        return label
    }()

    public lazy var textLabel: UILabel = {
        let label = UILabel()
        label.text = text
        label.textColor = fontColor
        label.font = UDFont.body1
        label.numberOfLines = 0
        return label
    }()

    // MARK: 消息卡片Header初始化 CardHeader
    public lazy var header = UDCardHeader(colorHue: color)

    init(color: UDCardHeaderHue, fontColor: UIColor, userName: String, text: String) {
        self.color = color
        self.fontColor = fontColor
        self.userName = userName
        self.text = text
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addComponents()
        makeConstraints()
        setAppearance()
    }
    private func addComponents() {
        addSubview(avatar)
        addSubview(header)
        addSubview(userLabel)
        header.addSubview(textLabel)

    }
    private func makeConstraints() {
        avatar.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.top.equalToSuperview().offset(24)
            make.left.equalToSuperview().offset(12)
        }

        userLabel.snp.makeConstraints { make in
            make.left.equalTo(avatar.snp.right).offset(12)
            make.top.equalTo(avatar.snp.top).offset(2)
        }

        header.snp.makeConstraints { make in
            make.width.equalTo(width)
            make.left.equalTo(avatar.snp.right).offset(12)
            make.top.equalTo(avatar.snp.centerY).offset(10)
            make.bottom.equalToSuperview().offset(-24)
        }

        textLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.left.equalTo(16)
            make.right.equalTo(-16)
        }

    }

    private func setAppearance() {
        header.layer.cornerRadius = 8
    }
}



extension UniverseDesignCardHeaderVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell", for: indexPath) as! UDHeaderCell
        let item = self.datasource[indexPath.row]
        cell.configure(chat: item)
        return cell
    }
}


// MARK: 自定义单元格
class UDHeaderCell: UITableViewCell {
    private var chat: chatView = chatView(color: .blue, fontColor: UIColor.blue, userName: "", text: "")

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = UITableViewCell.SelectionStyle.none
        self.contentView.addSubview(chat)
        self.contentView.clipsToBounds = true
        self.contentView.backgroundColor = UIColor.ud.bgBase
        self.backgroundColor = UIColor.ud.bgBase
        chat.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.chat.textLabel.textColor = nil
        self.chat.textLabel.text = nil
        self.chat.userLabel.text = nil
    }

    func configure(chat: chatView){
        self.chat.textLabel.textColor = chat.fontColor
        self.chat.textLabel.text = chat.text
        self.chat.userLabel.text = chat.userName
        self.chat.header.colorHue = chat.color
    }
}



// MARK: 字体颜色
extension UniverseDesignCardHeaderVC {
    enum Font {
        static var blueFont: UIColor { UDColor.B600 & UDColor.B600 }
        static var wathetFont: UIColor { UDColor.W700 & UDColor.W600 }
        static var TurquoiseFont: UIColor { UDColor.T700 & UDColor.T600 }
        static var greenFont: UIColor { UDColor.G700 & UDColor.G600 }
        static var limeFont: UIColor { UDColor.L700 & UDColor.L600 }
        static var yellowFont: UIColor { UDColor.Y700 & UDColor.Y600 }
        static var orangeFont: UIColor { UDColor.O600 & UDColor.O600 }
        static var redFont: UIColor { UDColor.R600 & UDColor.R600 }
        static var carmineFont: UIColor { UDColor.C600 & UDColor.C600 }
        static var violetFont: UIColor { UDColor.V600 & UDColor.V600 }
        static var purpleFont: UIColor { UDColor.P600 & UDColor.P600 }
        static var indigoFont: UIColor { UDColor.I600 & UDColor.I600 }
        static var deepNeuralFont: UIColor { UDColor.N00 & UDColor.N600 }
    }
}



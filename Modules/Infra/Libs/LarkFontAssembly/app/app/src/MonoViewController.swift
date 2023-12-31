//
//  FontListViewController.swift
//  LarkFontDev
//
//  Created by 白镜吾 on 2023/3/9.
//

import UIKit
import UniverseDesignColor
import LarkFontAssembly
import UniverseDesignFont
import SnapKit

class MonoViewController: UIViewController {

    var timer: Timer?
    var counter: CGFloat = 0.0

    var isMono: Bool = false

    lazy var sysLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 36)
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        label.backgroundColor = UIColor.ud.udtokenTagBgLimeHover
        label.text = "3°"
        label.sizeToFit()
        return label
    }()

    lazy var sysSpaceLabel: UILabel = {
        let label = UILabel()
        if #available(iOS 13.0, *) {
            label.font = UIFont.monospacedSystemFont(ofSize: 36, weight: .regular)
        }
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        label.backgroundColor = UIColor.ud.udtokenTagBgLimeHover
        label.text = "3°"
        return label
    }()

    lazy var systemMonoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 36, weight: .regular)
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        label.backgroundColor = UIColor.ud.udtokenTagBgLimeHover
        label.text = "3°"
        return label
    }()

    lazy var monoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.monospacedDigitSystemFont(ofSize: 36, weight: .regular)
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        label.backgroundColor = UIColor.ud.udtokenTagBgLimeHover
        label.text = "3°"
        return label
    }()

    lazy var dataSource: [(String, UILabel)] = [
        ("System - systemFont", sysLabel),
        ("System - monospacedSystemFont", sysSpaceLabel),
        ("System - monospacedDigitSystemFont", systemMonoLabel),
        ("Circular - monospacedDigitCustomFont", monoLabel)
    ]

    private lazy var startButton: UIButton = {
        let button = UIButton()
        button.setTitle("start", for: .normal)
        button.backgroundColor = .gray
        button.addTarget(self, action: #selector(clickStartButton), for: .touchUpInside)
        return button
    }()

    private lazy var stopButton: UIButton = {
        let button = UIButton()
        button.setTitle("stop", for: .normal)
        button.backgroundColor = .gray
        button.addTarget(self, action: #selector(clickStopButton), for: .touchUpInside)
        return button
    }()

    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.setTitle("reset", for: .normal)
        button.backgroundColor = .gray
        button.addTarget(self, action: #selector(clickResetButton), for: .touchUpInside)
        return button
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(CircularFontCell.self, forCellReuseIdentifier: CircularFontCell.cellIdentifier)
        tableView.backgroundColor = UIColor.ud.bgBody
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setComponents()
        setConstraints()
        setAppearance()
    }

    private func setComponents() {
        self.view.addSubview(tableView)
        self.view.addSubview(startButton)
        self.view.addSubview(stopButton)
        self.view.addSubview(resetButton)
    }
}

extension MonoViewController {

    private func setConstraints() {
        tableView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(self.view.safeAreaLayoutGuide)
            make.top.equalTo(startButton.snp.bottom).offset(16)
        }

        startButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        stopButton.snp.makeConstraints { (make) in
            make.leading.equalTo(startButton.snp.trailing).offset(20)
            make.centerY.width.equalTo(startButton)
        }

        resetButton.snp.makeConstraints { (make) in
            make.leading.equalTo(stopButton.snp.trailing).offset(20)
            make.centerY.width.equalTo(startButton)
        }
    }

    private func setAppearance() {
        self.view.backgroundColor = UIColor.ud.bgBody
    }

    @objc
    private func clickStartButton() {
        var font = sysLabel.font!
        if font.isItalic {
            let font = font.withoutTraits(.traitItalic)
            sysLabel.font = font
        } else {
            let font = font.withTraits(.traitItalic)
            sysLabel.font = font
        }
//        if timer == nil {
//            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] (_) in
//                guard let self = self else { return }
//                self.counter += 1
//                self.updateProgressView(value: self.counter)
//                if self.counter >= 999 {
//                    self.invalidateTimer()
//                }
//            }
//        }
    }

    @objc
    private func clickStopButton() {
        var font = sysLabel.font!
        if font.isBold {
            sysLabel.font = font.withoutTraits(.traitBold)
        } else {
            sysLabel.font = font.withTraits(.traitBold)
        }

        invalidateTimer()
    }

    @objc
    private func clickResetButton() {
        invalidateTimer()
        counter = 0.0
        updateProgressView(value: 0.0)
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateProgressView(value: CGFloat) {
//        if UDFontAppearance.isCustomFont {
//            FontSwizzleKit.hadSwizzled = false
//            FontSwizzleKit.swizzleIfNeeded()
//            FontSwizzleKit.hadSwizzled = false
//            LarkFont.removeFontAppearance()
//        } else {
//            guard !UDFontAppearance.isCustomFont else { return }
//            LarkFont.setupFontAppearance()
//            FontSwizzleKit.swizzleIfNeeded()
//        }
//
//        self.dismiss(animated: true)
//        self.presentingViewController?.present(MonoViewController(), animated: true)

        self.counter = value
        dataSource.forEach { (_, label) in
            label.text = "\(Int(value))°"
        }
    }
}

extension MonoViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CircularFontCell.cellIdentifier) as? CircularFontCell else { return UITableViewCell() }
        cell.config(title: dataSource[indexPath.row].0, countingLabel: dataSource[indexPath.row].1)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }

    }
}

class CircularFontCell: UITableViewCell {
    static var cellIdentifier: String = "CircularFontCell"

    lazy var titleLabel: UILabel = UILabel()

    var countingLabel: UILabel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.ud.bgBody
        self.contentView.addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(32)
            make.height.equalTo(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func config(title: String, countingLabel: UILabel) {
        self.titleLabel.text = title
        self.countingLabel = countingLabel
        self.contentView.addSubview(countingLabel)
        countingLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    func removeLabelView() {
        countingLabel?.removeFromSuperview()
    }
}

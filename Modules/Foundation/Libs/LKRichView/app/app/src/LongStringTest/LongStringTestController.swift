//
//  LongStringTestController.swift
//  LKRichViewDev
//
//  Created by 李勇 on 2019/9/5.
//

import Foundation
import UIKit
import SnapKit

// swiftlint:disable all

class StringTool {
    /// 得到一个指定长度的属性字符串
    static func getLengthAttributedString(length: Int) -> NSMutableAttributedString {
        let resultAttributedString = NSMutableAttributedString(string: "")
        while resultAttributedString.length < length {
            resultAttributedString.append(NSAttributedString(string: "😢あ你y"))
            if resultAttributedString.length % 10 == 0 {
                ///随机添加属性：字体、颜色、下划线、间距
                let random = arc4random() % 4
                if random == 0 {
                    self.addColor(attributedString: resultAttributedString)
                } else if random == 1 {
                    self.addFont(attributedString: resultAttributedString)
                } else if random == 2 {
                    self.addLine(attributedString: resultAttributedString)
                } else {
                    self.addKern(attributedString: resultAttributedString)
                }
            }
        }
        return resultAttributedString
    }

    static func randomColor() -> UIColor {
        let red = CGFloat(arc4random() % 256) / 255.0
        let green = CGFloat(arc4random() % 256) / 255.0
        let blue = CGFloat(arc4random() % 256) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    static func addKern(attributedString: NSMutableAttributedString) {
        attributedString.addAttributes([NSAttributedString.Key.kern: 3], range: NSRange(location: attributedString.length - 3, length: 3))
    }
    static func addColor(attributedString: NSMutableAttributedString) {
        attributedString.addAttributes([NSAttributedString.Key.foregroundColor: self.randomColor()], range: NSRange(location: attributedString.length - 3, length: 3))
    }
    static func addFont(attributedString: NSMutableAttributedString) {
        attributedString.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: CGFloat(arc4random() % 25))], range: NSRange(location: attributedString.length - 3, length: 3))
    }
    static func addLine(attributedString: NSMutableAttributedString) {
        attributedString.addAttributes([NSAttributedString.Key.strokeWidth: CGFloat(arc4random() % 5)], range: NSRange(location: attributedString.length - 3, length: 3))
    }
}

/// 测试一份超长字符串按指定份数创建CTFrame的总耗时
class LongStringTestController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    /// 测试结果
    struct TestResult {
        /// 份数
        let number: Int
        /// 总时间，单位s
        let allDate: TimeInterval
        /// allDate相对于上一个份数的比例
        let scale: Double
    }

    /// 待测试的字符串
    private var attributedString = NSMutableAttributedString(string: "")
    /// 待测试字符串的长度
    private var testStringLength: Int = 0
    /// 测试结果
    private var testResults: [TestResult] = []
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "测试长度：\(self.testStringLength)"
        self.view.backgroundColor = UIColor.white
        self.navigationController?.navigationBar.isTranslucent = false
        /// 添加顶部测试按钮
        let leftButton = UIButton(type: .system)
        leftButton.setTitle("重设测试长度", for: .normal)
        leftButton.addTarget(self, action: #selector(reselectStringLength), for: .touchUpInside)
        self.view.addSubview(leftButton)
        let rightButton = UIButton(type: .system)
        rightButton.setTitle("重设分割份数", for: .normal)
        rightButton.addTarget(self, action: #selector(reselectCountNumber), for: .touchUpInside)
        self.view.addSubview(rightButton)
        leftButton.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview()
            make.height.equalTo(50)
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        rightButton.snp.makeConstraints { (make) in
            make.right.top.equalToSuperview()
            make.height.equalTo(50)
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        /// 添加表格视图
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(ResultTableViewCell.self, forCellReuseIdentifier: "ResultTableViewCell")
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.top.equalTo(leftButton.snp.bottom)
            make.bottom.left.right.equalToSuperview()
        }
    }

    @objc
    private func reselectStringLength() {
        let alertVC = UIAlertController(title: "测试长度", message: nil, preferredStyle: .alert)
        alertVC.addTextField(configurationHandler: nil)
        alertVC.addAction(UIAlertAction(title: "确认", style: .default, handler: { (_) in
            let textFieldString = alertVC.textFields?.first!.text!
            self.testStringLength = Int(textFieldString ?? "") ?? 0
            self.attributedString = StringTool.getLengthAttributedString(length: self.testStringLength)
            self.title = "测试长度：\(self.testStringLength)"
            self.testResults.removeAll()
            self.tableView.reloadData()
        }))
        self.present(alertVC, animated: true, completion: nil)
    }

    @objc
    private func reselectCountNumber() {
        let alertVC = UIAlertController(title: "分割份数", message: nil, preferredStyle: .alert)
        alertVC.addTextField(configurationHandler: nil)
        alertVC.addAction(UIAlertAction(title: "确认", style: .default, handler: { (_) in
            let textFieldString = alertVC.textFields?.first!.text!
            self.countAttributedString(count: Int(textFieldString ?? "") ?? 0)
        }))
        self.present(alertVC, animated: true, completion: nil)
    }

    private func countAttributedString(count: Int) {
        let array = self.getArray(count: count)
        let beginDate = NSDate()
        /// 计算5次，取平均值
        var index = 0
        while index < 5 {
            for attributedString in array {
                let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
                let path = CGPath(rect: CGRect(x: 0, y: 0, width: 300, height: 100_000), transform: nil)
                let ctframe = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
                let lines = CTFrameGetLines(ctframe)
                _ = CFArrayGetCount(lines)
            }
            index += 1
        }
        let currDate = (NSDate().timeIntervalSince1970 - beginDate.timeIntervalSince1970) / 5
        let scale = self.testResults.isEmpty ? 1 : (currDate / self.testResults.last!.allDate)
        self.testResults.append(TestResult(number: count, allDate: currDate, scale: scale))
        self.tableView.reloadData()
    }

    private func getArray(count: Int) -> [NSAttributedString] {
        var result: [NSAttributedString] = []
        /// 得到每一份的大小
        let spaceValue = self.testStringLength / count
        for index in 0..<count {
            result.append(self.attributedString.attributedSubstring(from: NSRange(location: index * spaceValue, length: spaceValue)))
        }
        if (self.testStringLength % count) != 0 {
            let lastCount = self.testStringLength % count
            result.append(self.attributedString.attributedSubstring(from: NSRange(location: self.testStringLength - lastCount, length: lastCount)))
        }
        return result
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.testResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let attributedTableCell = tableView.dequeueReusableCell(withIdentifier: "ResultTableViewCell", for: indexPath) as! ResultTableViewCell
        let attributedValue = self.testResults[indexPath.row]
        attributedTableCell.leftLabel.text = "\(attributedValue.number)"
        attributedTableCell.centerLabel.text = String(format: "%.4f", attributedValue.allDate)
        attributedTableCell.rightLabel.text = String(format: "%.4f", attributedValue.scale)
        return attributedTableCell
    }
}

//
//  ViewController.swift
//  LarkEmotionDev
//
//  Created by 李晨 on 2019/6/2.
//

import Foundation
import UIKit
import LarkEmotion
import SnapKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    /// 展示所有的key
    private var dataSource: [String] = []
    private let dependency = MockEmotionResouceDependency()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "资源列表"

        self.view.backgroundColor = UIColor.white

        // 加载本地数据
        EmotionResouce.shared.reloadResouces(isOversea: true)
        EmotionResouce.shared.dependency = self.dependency
        self.dataSource = EmotionResouce.shared.getAllResouces().map({ $0.key })

        // 添加表格视图
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 44
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.register(CustemTableViewCell.self, forCellReuseIdentifier: "CustemTableViewCell")

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "单测", style: .plain, target: self, action: #selector(refresh))
    }

    /// 测试线程安全
    @objc
    private func refresh() {
        let queue = DispatchQueue(label: "", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        for _ in 0..<100 {
            queue.async {
                let begin = NSDate().timeIntervalSince1970
                EmotionResouce.shared.reloadResouces(isOversea: true)
                print("1 reloadResouces:\(EmotionResouce.shared.getAllResouces().count) \(Thread.current) \(NSDate().timeIntervalSince1970 - begin)")

                // 取出几个已有的resouce，然后进行merge
                var resouces: [String: Resouce] = [:]
                EmotionResouce.shared.getAllResouces().suffix(5).forEach { (resouce) in
                    resouces[resouce.key] = Resouce(
                        i18n: resouce.value.i18n + "_",
                        imageKey: resouce.value.imageKey + "_",
                        image: resouce.value.image
                    )
                }
                EmotionResouce.shared.mergeResouces(resouces: resouces)
                print("2 mergeResouces:\(EmotionResouce.shared.getAllResouces().count) \(Thread.current)")

                resouces = EmotionResouce.shared.getAllResouces()
                print("3 resouces.count:\(resouces.count) \(Thread.current)")

                let emotionKey = EmotionResouce.shared.emotionKeyBy(reactionKey: "\(self.dependency.number.value + 1)")
                print("4 emotionKey:\(emotionKey) \(Thread.current)")

                let reactionKey = EmotionResouce.shared.reactionKeyBy(emotionKey: "\(self.dependency.number.value + 1)")
                print("5 reactionKey:\(reactionKey) \(Thread.current)")

                let image = EmotionResouce.shared.imageBy(key: "\(self.dependency.number.value + 1)")
                print("6 image:\(image != nil) \(Thread.current)")

                let i18n = EmotionResouce.shared.i18nBy(key: "\(self.dependency.number.value - 1)")
                print("7 i18n:\(i18n) \(Thread.current)")
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let tableViewCell = tableView.dequeueReusableCell(withIdentifier: "CustemTableViewCell", for: indexPath) as? CustemTableViewCell {
            let key = self.dataSource[indexPath.row]
            tableViewCell.setImage(EmotionResouce.shared.imageBy(key: key))
            tableViewCell.setInfo("\(EmotionResouce.shared.i18nBy(key: key)) \(key) \(EmotionResouce.shared.emotionKeyBy(reactionKey: key))")
            return tableViewCell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

class CustemTableViewCell: UITableViewCell {
    private let myImage = UIImageView()
    private let myInfo = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(self.myImage)
        self.myImage.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }

        self.contentView.addSubview(self.myInfo)
        self.myInfo.snp.makeConstraints { (make) in
            make.left.equalTo(self.myImage.snp.right).offset(10)
            make.centerY.equalToSuperview()
            make.right.equalTo(-10)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setImage(_ image: UIImage?) {
        self.myImage.image = image
    }

    public func setInfo(_ info: String) {
        self.myInfo.text = info
    }
}

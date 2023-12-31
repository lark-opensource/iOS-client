//
//  ListTableViewController.swift
//  Minutes_Example
//
//  Created by lvdaqian on 2018/6/28.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import EENavigator
import LarkLive

class ListTableViewController: UITableViewController {

    static var urlMap: [String: String] = [
        "": "",
        "  ": "",
        "超长回放": "https://meetings.feishu-pre.cn/s/1hu0uli58elfl?src_type=3",
        "yy_boe": "https://meetings.feishu-boe.cn/s/1hu6cnsadtdsj?src_type=1#",
        "test_live": "https://meetings.feishu-pre.cn/s/1hrcskjuy57oc?src_type=1#",
        "yy_test": "https://meetings.feishu-pre.cn/s/1hs29yo3qzfnl?src_type=1#",
        "tttest": "https://meetings.feishu-pre.cn/s/1hqkilb6o8lr0?src_type=1#",
        "obs": "https://meetings.feishu-pre.cn/s/1htaacptgh9tt?src_type=1#",
        "杨耀的视频会议": "https://meetings.feishu-pre.cn/s/1gypt4ljt60as?src_type=3#",
        "共建": "https://meetings.feishu-pre.cn/s/1hllcm6j8u39d?src_type=1#",
        "alwaysRun": "https://meetings.feishu-pre.cn/s/1h8l0s3tmae4h?src_type=2",
        "alwaysRun_release": "https://meetings.feishu.cn/s/1h8l0s3tmae4h?src_type=2",
        "alwaysRun-boe": "https://meetings.feishu-boe.cn/s/1hllcm6j8u39d?src_type=3",
        "alwaysRun_共建": "https://meetings.feishu-pre.cn/s/1hfwme864rxuk?src_type=3",
        "GREENLAND": "https://meetings.feishu-pre.cn/s/1hiiyyc2z92is?src_type=3",
        "playback": "https://meetings.feishu.cn/s/1ha0q1j7wgfsy?src_type=3",
        "boepriva": "https://meetings.feishu-boe.cn/s/1hu74xw1mdq8k?src_type=1#",
        "url": "https://meetings.feishu-pre.cn/s/1hft35cto39qc?src_type=1#",
        "emoji": "https://meetings.feishu-pre.cn/s/1hkywojs6no64?src_type=1#",
        ",,,": "https://meetings.feishu-pre.cn/s/1hrh3xq3i4r2a?src_type=1#",
        "boe-tab": "https://meetings.feishu-boe.cn/s/1hp8b0we1snpv?src_type=3&x-tt-env=boe_decorate",
        "周会回放": "https://meetings.feishu-pre.cn/s/1hf5w5s2s17gh?src_type=1#",
        "test playback": "https://meetings.feishu-pre.cn/s/1hqkilb6o8lr0?src_type=3",
        "shh的会议": "https://meetings.feishu-pre.cn/s/1h78ocrbis0lg?src_type=3",
        "live.bytedance.com": "https://live.bytedance.com/s/1hiow1runb2fw?src_type=1#",
        "live.byteplus.com": "https://live.byteplus.com/s/1hiow1runb2fw?src_type=1#",
        "live.byteoc.com": "https://live.byteoc.com/s/1hiow1runb2fw?src_type=1#",
        "live.bytedan.com": "https://live.bytedan.com/s/1hiow1runb2fw?src_type=1#",
        "字节直播": "https://live.byteoc.com/9944/6282557",
        "HHH-boe": "https://meetings.feishu-boe.cn/s/1hobvn4hg2vis?src_type=1#",
        "潘灶烽的会议": "https://meetings.feishu.cn/s/1h1kzx2dcre2p?src_type=1#"
    ]

    let disposeBag = DisposeBag()

    var data = BehaviorRelay(value: [String]())

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    @objc func onBtnAddLink() {
        let alertController = UIAlertController(
            title: "添加链接",
            message: nil,
            preferredStyle: UIAlertController.Style.alert
        )
        alertController.addTextField { (textField) in

        }
        alertController.addAction(UIAlertAction(
            title: "确定",
            style: .default,
            handler: { [weak alertController] (_) in
                let urlString = alertController?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if urlString.isEmpty == false, let url = URL(string: urlString) {
                    Navigator.shared.push(url, from: self)

                    ListTableViewController.urlMap[urlString] = urlString
                    self.data.accept(Array(ListTableViewController.urlMap.keys).sorted())
                }
            }
        ))
        alertController.addAction(UIAlertAction(
            title: "取消",
            style: .cancel,
            handler: { (_) in

            }
        ))
        present(alertController, animated: true, completion: nil)
    }

    var button: UIButton?
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if button == nil {
            button = UIButton(type: .roundedRect)
            button?.frame = CGRect(x: 300, y: 200, width: 100, height: 60)
            button?.setTitle("add link", for: .normal)
            button?.addTarget(self, action: #selector(onBtnAddLink), for: .touchUpInside)
            view.addSubview(button!)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        data.accept(Array(ListTableViewController.urlMap.keys).sorted())
        tableView.delegate = nil
        tableView.dataSource = nil

        data.asDriver().drive(tableView.rx.items ) { (tableView, _, chatter) in

            let cell = tableView.dequeueReusableCell(withIdentifier: "chatter") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "chatter")
            cell.textLabel?.text = chatter
            return cell
        }
        .disposed(by: disposeBag)

        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)

        tableView.rx.modelSelected(String.self).subscribe(onNext: { [weak self] c in
            guard let self = self else { return }
            if let navVC = self.tabBarController {
                let urlString = ListTableViewController.urlMap[c]!.trimmingCharacters(in: .whitespacesAndNewlines)
                if urlString.isEmpty == false {
                    Navigator.shared.push(URL(string: urlString)!, from: navVC)
                }
            }
        }).disposed(by: disposeBag)
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }
}

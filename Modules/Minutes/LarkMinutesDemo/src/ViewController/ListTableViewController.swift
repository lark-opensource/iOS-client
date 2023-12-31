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
import Kingfisher
import MinutesInterface
import EENavigator
import MinutesNavigator
import Minutes
import LarkAppConfig
import LarkUIKit
import AnimatedTabBar
import LarkTab
import LarkSceneManager
import LKCommonsLogging

class ListTableViewController: UITableViewController {

    static let logger = Logger.log(ListTableViewController.self)

    static var urlMap: [String: String] = [
        "同传": "https://ming.feishu-pre.cn/minutes/obcnawar7f681bwae6c3s528",
        "metion_comments_long":
            "https://meetings.feishu.cn/minutes/obcn1477418p344i85d1krz3?c=6966123913672015875&cci=6968386995512950785&from_source=mention_from_comments",
        "mention_delete": "https://meetings.feishu.cn/minutes/obcn1477418p344i85d1krz3?c=6967250007338598401&cci=6968385559345741825&from_source=mention_from_comments",
        "mention_jump":
        "https://meetings.feishu.cn/minutes/obcn3ge79m44n4x63akfuoug?c=6967214026803675140&cci=6967267598757019649&from_source=mention_from_comments",
        "Mention_To_Summary": "https://meetings.feishu.cn/minutes/obcn3gifah413db9511f16w5?from_source=mention_from_minutes&su=1622103346074",
        "飞书妙计列表页 - 我的内容": "https://bytedance.feishu.cn/minutes/me",
        "飞书妙计列表页 - 共享内容": "https://bytedance.feishu.cn/minutes/shared",
        "飞书妙计列表页 - 首页": "https://bytedance.feishu.cn/minutes/home",
        "飞书妙计列表页 - 回收站": "https://bytedance.feishu.cn/minutes/trash",
        "飞书妙计列表页Body - 我的内容": MinutesHomeMeBody.pattern,
        "飞书妙计列表页Body - 共享内容": MinutesHomeSharedBody.pattern,
        "飞书妙计列表页Body - 首页": MinutesHomePageBody.pattern,
        "飞书妙计列表页Body - 回收站": MinutesHomeTrashBody.pattern,
        "妙记移动端测试用例初评": "https://bytedance.feishu.cn/minutes/obcnl5m8qpuj111wro1rt33e",
        "妙记移动端需求初评": "https://bytedance.feishu.cn/minutes/obcnc71mf314zswzzqm68j3n",
        "讯飞录音转写比较": "https://bytedance.feishu.cn/minutes/obcng8hym81r61w5xb532o67",
        "Pre-妙记移动端需求初评": "https://bytedance.feishu-pre.cn/minutes/obcnc71mf314zswzzqm68j3n",
        "Pre-讯飞录音转写比较": "https://bytedance.feishu-pre.cn/minutes/obcng8hym81r61w5xb532o67",
        "空字幕": "https://bytedance.feishu.cn/minutes/obcnlhzelfnbxf65zcf73182",
        "一行字幕": "https://bytedance.feishu.cn/minutes/obcne5jv83qh2bxptmx98oy2",
        "B站测试": "https://bytedance.feishu.cn/minutes/obcn7gc1q6o5l3l1p4o996lb",
        "Minutes支持录音生成需求评审": "https://meetings.feishu.cn/minutes/obcnomf68186z3y69998qrt8",
        "移动端3.44需求评审": "https://bytedance.feishu.cn/minutes/obcnpe8d96vn269a3fiae2ki",
        "董红焱的视频会议": "https://meetings.feishu-pre.cn/minutes/obcnp49v55bar5578p2op949",
        "example": "https://bytedance.feishu.cn/minutes/obcng3j91e2ocdg8tido8865",
        "list_me": "https://bytedance.feishu.cn/minutes/me",
        "list_share": "https://bytedance.feishu.cn/minutes/shared",
        "Video Error": "https://meetings.feishu.cn/minutes_feishu/obcnqv7w68s79dzbvabekly1",
        "audio error": "https://bytedance.feishu.cn/minutes/obcnqwh4c4a3ul4c52a4166d",
        "a": "https://bytedance.feishu.cn/minutes/obcnmq5536rbudx4ti761h15",
        "李可": "https://bytedance.feishu-pre.cn/minutes/obcnyo263fn1fyrqd4mof5o5",
        "潘灶烽": "https://bytedance.feishu-pre.cn/minutes/obcnkf3agw9uq3ackx67a2c5",
        "keywords超长": "https://bytedance.feishu.cn/minutes/obcng3j91e2ocdg8tido8865",
        "staging": "https://byte.feishu-staging.cn/minutes/obcnzryb5rznw3jf1ijsv2v5",
        "Pre-ldq": "https://bytedance.feishu-pre.cn/minutes/obcnp7u19t537jirl1id4fr2?from=auth_notice",
        "TwoLineKayWords": "https://bytedance.feishu-pre.cn/minutes/obcn9nhbch5zu352jzyc8q3v",
        "kerong":"https://ming.feishu-pre.cn/minutes/obcnmr426943ww6nws8b9i62",
        "可蓉's video meeting": "https://ming.feishu.cn/minutes/obcnmr426943ww6nws8b9i62",
        "播放跳动": "https://ming.feishu.cn/minutes/obcnmr426943ww6nws8b9i62",
        "ttt": "https://bytedance.feishu.cn/minutes/obcnxqnww5puyg92hojb2ex5",
        "yangyao's 视频会议": "https://bytedance.feishu.cn/minutes/obcnzkxgcf3f9zcbj8vh11t8",
        "boeTest": "https://meetings.feishu-boe.cn/minutes/obcnrz5112hqjvbdr1qjy15b",
        "boeTest1": "https://bytedance.feishu-boe.cn/minutes/obcnr3w85q896e87vp675ly4",
        "Lark Minutes 项目周会": "https://bytedance.feishu-pre.cn/minutes/obcnnzfyq85g54i6g3b2kn61",
        "无权限": "https://bytedance.feishu-pre.cn/minutes/obcn7m49nn2qo3851r687y19",
        "recording": "recording",
        "A性能测试-短时间妙记链接(14min) ": "https://bytedance.feishu-pre.cn/minutes/obcn8ub59k79o733328e2sk4",
        "A性能测试-中时长妙记链接(58min)": "https://bytedance.feishu-pre.cn/minutes/obcn4s187121lkhmry2dw9ag",
        "A性能测试-长时长妙记链接 （1h45min）": "https://bytedance.feishu-pre.cn/minutes/obcnr49oo9u5esf8h682yf2g",
        "TestURL":"https://bytedance.feishu.cn/minutes/obcncb8myndh6oc661e6ohu4?from=auth_notice",
        "片段分享":"https://bytedance.feishu-boe.cn/minutes/obbc6h32u13im3n3hw536e89",
        "lark片段":"https://bytedance.feishu-pre.cn/minutes/obcnawc9xp92cmk25m7c6q86"
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
            print("\(c)")

            if let navVC = self?.tabBarController {
                let urlString = ListTableViewController.urlMap[c]!
                if urlString == MinutesHomeMeBody.pattern {
                    let body = MinutesHomeMeBody(fromSource: .meetingTab)
                    Navigator.shared.push(body: body, from: navVC)
                } else if urlString == MinutesHomeSharedBody.pattern {
                    let body = MinutesHomeSharedBody(fromSource: .meetingTab)
                    Navigator.shared.push(body: body, from: navVC)
                } else if urlString == MinutesHomeTrashBody.pattern {
                    let body = MinutesHomeTrashBody(fromSource: .meetingTab)
                    Navigator.shared.push(body: body, from: navVC)
                } else if urlString == MinutesHomePageBody.pattern {
                    let body = MinutesHomePageBody(fromSource: .meetingTab)
                    Navigator.shared.push(body: body, from: navVC)
                } else if urlString == "recording", let url = MinutesAudioRecorder.shared.minutes?.baseURL {
                    Navigator.shared.push(url, from: navVC)
                } else if urlString == "scene" {
                    let scene = Scene(key: "Minutes", id: "me")

                    SceneManager.shared.active(scene: scene, from: self) { window, error in
                        Self.logger.info("active scene window: \(String(describing: window)), error: \(String(describing: error))")
                    }
                }else {
                    Navigator.shared.showDetailOrPush(URL(string: urlString)!, from: self!)
                }
            }

        }).disposed(by: disposeBag)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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

extension ListTableViewController: TabRootViewController, LarkNaviBarDataSource, LarkNaviBarDelegate {
    var tab: Tab { Tab.feed }
    var controller: UIViewController { self }
    var titleText: BehaviorRelay<String> { BehaviorRelay(value: "Fake View Controller") }
    var isNaviBarEnabled: Bool { true }
    var isDrawerEnabled: Bool { true }

    func changeNaviBarPresentation(show: Bool?, animated: Bool) {
        larkNaviBar?.setPresentation(show: show, animated: animated)
    }

    private var larkNaviBar: NaviBarProtocol? {
        let rootVC = UIApplication.shared.windows.compactMap({ $0.rootViewController as? UINavigationController })
        let tab = rootVC.compactMap({ $0.viewControllers.first as? MainTabbarProtocol }).first
        return tab?.naviBar
    }
}

struct DemoTab: TabRepresentable {
  var tab: Tab { Tab.feed }
}

extension Navigatable {
    public func showDetailOrPush(
        _ url: URL,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: UIViewController,
        animated: Bool = true,
        completion: Handler? = nil) {
        if Display.pad {
            let lksplit = from.larkSplitViewController?.secondaryViewController
            let split = (from as? UISplitViewController) ?? from.splitViewController
            let detail = lksplit ?? split?.viewControllers.last
            autoDissmisModals(detail)
            self.showDetail(url,
                                        context: context,
                                        wrap: wrap,
                                        from: from,
                                        completion: completion)
        } else {
            self.push(url,
                                  context: context,
                                  from: from,
                                  animated: animated,
                                  completion: completion)
        }
    }

    private func autoDissmisModals(_ from: UIViewController?) {
        from?.presentedViewController?.dismiss(animated: false, completion: nil)
        from?.navigationController?.presentedViewController?.dismiss(animated: false, completion: nil)
        from?.larkSplitViewController?.presentedViewController?.dismiss(animated: false, completion: nil)
        from?.splitViewController?.presentedViewController?.dismiss(animated: false, completion: nil)
        from?.tabBarController?.presentedViewController?.dismiss(animated: false, completion: nil)
    }
}

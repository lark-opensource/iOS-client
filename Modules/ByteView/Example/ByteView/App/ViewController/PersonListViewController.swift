//
//  PersonListViewController.swift
//  ByteViewDemo
//
//  Created by kiri on 2021/3/10.
//

import UIKit
import LarkRustClient
import RxSwift
import ByteViewInterface
import LarkAccountInterface
import ByteWebImage
import ByteViewUI
import LarkModel
import LarkUIKit
import RustPB
import EENavigator
import LarkContainer
import UniverseDesignIcon
#if canImport(MessengerMod)
import LarkMessengerInterface
import LarkAIInfra
#endif

typealias MGetChattersRequest = Contact_V1_MGetChattersRequest
typealias MGetChattersResponse = Contact_V1_MGetChattersResponse

class PersonListViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    private let disposeBag = DisposeBag()
    private let tableView = BaseTableView()
    private var chatters: [Chatter] = DemoCache.shared.chatters
    private var rustService: RustService? { try? resolver.resolve(assert: RustService.self) }
    let resolver: UserResolver
    init(resolver: UserResolver) {
        self.resolver = resolver
        super.init(nibName: nil, bundle: nil)
        self.title = "联系人"
        self.tabBarItem = UITabBarItem(title: self.title, image: UDIcon.getIconByKey(.tabContactsFilled), tag: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hidesBottomBarWhenPushed = false
        view.backgroundColor = .white
        view.addSubview(tableView)
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 0))
        tableView.rowHeight = 68
        tableView.separatorInset = .init(top: 0, left: 76, bottom: 0, right: 0)
        tableView.separatorColor = UIColor.ud.N300
        tableView.register(DemoUserCell.self, forCellReuseIdentifier: "Cell")
        tableView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 13, *) {
            self.navigationController?.navigationBar.standardAppearance.configureWithDefaultBackground()
            self.navigationController?.navigationBar.scrollEdgeAppearance?.configureWithDefaultBackground()
        }
    }

    override func viewDidFirstAppear(_ animated: Bool) {
        super.viewDidFirstAppear(animated)
        loadChatters()
    }

    private func reloadChatters(_ chatters: [Chatter]) {
        var items = chatters.sorted(by: { lhs, rhs in
            let lhsIdx = DemoEnv.people.firstIndex(of: lhs.id) ?? -1
            let rhsIdx = DemoEnv.people.firstIndex(of: rhs.id) ?? -1
            return lhsIdx < rhsIdx
        })
        #if canImport(MessengerMod)
        if let info = try? resolver.resolve(assert: MyAIService.self).info.value {
            var chatter = Chatter()
            chatter.id = info.id
            chatter.type = .ai
            chatter.name = info.name
            chatter.localizedName = info.name
            chatter.avatarKey = info.avatarKey
            items.insert(chatter, at: 0)
        }
        #endif
        DemoCache.shared.chatters = items
        self.chatters = items
        self.tableView.reloadData()
    }

    private func loadChatters() {
        let people = DemoEnv.people
        var req = MGetChattersRequest()
        req.chatterIds = people
        let resp: Observable<MGetChattersResponse> = rustService?.sendAsyncRequest(req) ?? .empty()
        resp.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
            self?.reloadChatters($0.entity.chatters.map { $1 })
        }).disposed(by: disposeBag)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        chatters.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chatter = chatters[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if let cell = cell as? DemoUserCell {
            cell.avatarView.setAvatarInfo(.remote(key: chatter.avatarKey, entityId: chatter.id))
            cell.titleLabel.text = chatter.localizedName
            cell.subtitleLabel.text = chatter.id
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let c = chatters[indexPath.row]
        if c.type == .ai {
            #if canImport(MessengerMod)
            try? self.resolver.resolve(assert: MyAIService.self).openMyAIChat(from: self)
            #endif
        } else if c.id == resolver.userID {
            self.push("//client/byteview/startmeeting?isCall=0&entrySource=\(VCMeetingEntry.groupPlus)")
        } else {
            let alert = UIAlertController(title: "给 \(c.name) 拨打1v1视频通话?", message: nil, preferredStyle: .actionSheet)
            alert.addAction(.init(title: "企业电话", style: .default, handler: { [weak self] (_) in
                let context: [String: Any] = [
                    "calleeUserId": c.id,
                    "calleeName": c.name,
                    "calleeAvatarKey": c.avatarKey,
                    "idType": "enterprisePhone"
                ]
                self?.push("//client/byteview/phonecall", context: context)
            }))
            alert.addAction(.init(title: "视频通话", style: .default, handler: { [weak self] (_) in
                let context: [String: Any] = [
                    "userId": c.id,
                    "entrySource": VCMeetingEntry.addressBookCard,
                    "isCall": true,
                    "isVoiceCall": false
                ]
                self?.push("//client/byteview/startmeeting", context: context)
            }))
            alert.addAction(.init(title: "语音通话", style: .default, handler: { [weak self] (_) in
                let context: [String: Any] = [
                    "userId": c.id,
                    "entrySource": VCMeetingEntry.addressBookCard,
                    "isCall": true,
                    "isVoiceCall": true
                ]
                self?.push("//client/byteview/startmeeting", context: context)
            }))
            #if canImport(MessengerMod)
            alert.addAction(.init(title: "聊天", style: .default, handler: { [weak self] _ in
                self?.push(body: ChatControllerByChatterIdBody(chatterId: c.id, isCrypto: false))
            }))
            #endif
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            if let popover = alert.popoverPresentationController, let cell = tableView.cellForRow(at: indexPath) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            }
            present(alert, animated: true)
        }
    }

    private func push(_ urlString: String, context: [String: Any] = [:]) {
        guard let url = URL(string: urlString) else { return }
        self.resolver.navigator.push(url, context: context, from: self)
    }

    private func push<T: EENavigator.Body>(body: T) {
        self.resolver.navigator.push(body: body, from: self)
    }
}

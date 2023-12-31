//
//  MeetingTestViewController.swift
//  ByteViewDemo
//
//  Created by kiri on 2021/3/11.
//

import UIKit
import ByteViewInterface
import LarkTab
import EENavigator
import LarkSceneManager
import ByteViewUI
import ByteViewCommon
import ByteView
import LarkMedia
import LKLoadable
import ByteViewSetting
import ByteViewDebug
import LarkContainer
import UniverseDesignIcon
import LarkAccountInterface

class MeetingTestViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = BaseTableView()
    private let resolver: UserResolver
    private var items: [DemoCellRow] = []

    private var vcSettingId: String?

    private weak var cameraVC: UIViewController?

    private var setting: UserSettingManager? { try? resolver.resolve(assert: UserSettingManager.self) }
    private var navigator: Navigatable { resolver.navigator }
    init(resolver: UserResolver) {
        self.resolver = resolver
        super.init(nibName: nil, bundle: nil)
        self.title = "VC测试"
        self.tabBarItem = UITabBarItem(title: self.title, image: UDIcon.getIconByKey(.tabChatFilled), tag: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hidesBottomBarWhenPushed = false
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 0))
        tableView.rowHeight = 48
        tableView.separatorColor = .ud.commonTableSeparatorColor
        tableView.register(DemoTableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        if let user = try? resolver.resolve(assert: PassportUserService.self).user {
            let avatar = AvatarView(style: .circle)
            avatar.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
            avatar.setTinyAvatar(.remote(key: user.avatarKey, entityId: user.userID))
            avatar.snp.makeConstraints { make in
                make.width.height.equalTo(36)
            }
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: avatar)
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UDIcon.getIconByKey(.settingOutlined), style: .plain, target: self, action: #selector(didClickSetting(_:)))
        tableView.delegate = self
        tableView.dataSource = self

        reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 13, *) {
            self.navigationController?.navigationBar.standardAppearance.configureWithDefaultBackground()
            self.navigationController?.navigationBar.scrollEdgeAppearance?.configureWithDefaultBackground()
        }
    }

    @objc private func didClickSetting(_ sender: Any?) {
        self.demoPresent(body: ByteViewSettingsBody(source: "vctab"), navigator: self.navigator)
    }

    private func reloadData() {
        self.items = []
        appendItem("视频会议调试选项") { [weak self] in
            let vc = createByteViewDebugVC()
            self?.demoPushOrPresent(vc)
        }
        #if canImport(MessengerMod)
        appendItem("测试AI") { [weak self] in
            guard let self = self else { return }
            let vc = TestAIViewController(resolver: self.resolver)
            self.demoPushOrPresent(vc)
        }
        #endif
        if DemoEnv.isKA {
            appendItem("ka视频会议") { [weak self] in
                self?.push("//client/byteview/joinmeeting?id=6797599117070565476&idType=group&entrySource=\(VCMeetingEntry.chatWindowBanner)")
            }
        }
        appendItem("开启/加入日程群会议(多人日程会议测试群)") { [weak self] in
            guard let self = self else { return }
            let context: [String: Any] = [
                "uniqueId": DemoEnv.uniqueID,
                "uid": "",
                "originalTime": 0,
                "instanceStartTime": 0,
                "instanceEndTime": 0,
                "title": "多人日程会议测试群",
                "entrySource": VCMeetingEntry.calendarDetails,
                "linkScene": false,
                "isStartMeeting": false
            ]
            self.push("//client/byteview/joinbycalendar", context: context)
        }
        if DemoEnv.isBoe {
            appendItem("BOE-Webinar-MeetingNumber入会") { [weak self] in
                self?.push("//client/byteview/joinmeeting?id=958259259&idType=number&entrySource=\(VCMeetingEntry.joinRoom)")
            }
        }
        appendItem("Webinar-MeetingNumber入会") { [weak self] in
            self?.push("//client/byteview/joinmeeting?id=124966914&idType=number&entrySource=\(VCMeetingEntry.joinRoom)")
        }
        appendItem("MeetingNumber入会") { [weak self] in
            self?.push("//client/byteview/joinmeeting?idType=number&entrySource=\(VCMeetingEntry.joinRoom)")
        }
        appendItem("发起视频会议(即时会议)") { [weak self] in
            self?.push("//client/byteview/startmeeting?isCall=0&entrySource=\(VCMeetingEntry.groupPlus)")
        }
        appendItem("开启/加入普通群会议(多人会议测试群)") { [weak self] in
            self?.push("//client/byteview/joinmeeting?id=\(DemoEnv.groupId)&idType=group&entrySource=\(VCMeetingEntry.chatWindowBanner)")
        }
        appendItem("超声波") { [weak self] in
            let vc = UltrasonicWaveViewController()
            self?.demoPushOrPresent(vc)
        }
        appendItem("日程会议初次设置") { [weak self] in
            guard let self = self, let service = self.setting else { return }
            var context: CalendarSettingContext = .init(type: .start)
            context.createSubmitHandler = { r in
                if case .success(let resp) = r {
                    self.vcSettingId = resp.vcSettingID
                }
            }
            let vc = service.ui.createCalendarSettingViewController(context: context)
            self.demoPresent(vc)
        }
        appendItem("日程会议pre编辑设置") { [weak self] in
            guard let self = self, let service = self.setting, let vcSettingId = self.vcSettingId else { return }
            let context: CalendarSettingContext = .init(type: .preEdit(vcSettingId))
            let vc = service.ui.createCalendarSettingViewController(context: context)
            self.demoPresent(vc)
        }
        appendItem("Webinar会议初次设置") { [weak self] in
            guard let self = self, let service = self.setting?.ui else { return }
            let context = WebinarSettingContext(jsonString: nil,
                                                speakerCanInviteOthers: true,
                                                speakerCanSeeOtherSpeakers: true,
                                                audienceCanInviteOthers: true,
                                                audienceCanSeeOtherSpeakers: true)
            let vc = service.createWebinarSettingViewController(context: context)
            self.demoPresent(vc)
        }
        appendItem("候选人入会") { [weak self] in
            let urlString = "https://applink.feishu.cn/client/videochat/open?source=interview&action=join&id=6799520314695876610&role=6wk88xnu&min_lk_ver=3.17.99&num=129630376&applink_ru=https%3A%2F%2Fmeeting.feishu.cn%2Fclient%2Fvideochat%2Fopen%2Fhomepage%3Fsource%3Dinterview%26action%3Djoin%26id%3D6799520314695876610%26role%3D6wk88xnu%26num%3D129630376"
            self?.joinMeetingByLink(urlString)
        }
        appendItem("面试官入会") { [weak self] in
            let urlString = "https://applink.feishu.cn/client/videochat/open?source=interview&action=join&id=6799520314695876610&role=tndfsgb5&min_lk_ver=3.17.99&num=129630376&applink_ru=https%3A%2F%2Fmeeting.feishu.cn%2Fclient%2Fvideochat%2Fopen%2Fhomepage%3Fsource%3Dinterview%26action%3Djoin%26id%3D6799520314695876610%26role%3Dtndfsgb5%26num%3D129630376"
            self?.joinMeetingByLink(urlString)
        }
        appendItem("链接入会") { [weak self] in
            self?.push("https://vc.feishu.cn/j/i?id=6941193719999709212&no=685572235")
        }
        appendItem("本地投屏") { [weak self] in
            self?.push("//client/byteview/sharecontent?source=\(ShareContentEntry.groupPlus.rawValue)")
        }
        appendItem("视频会议铃声") { [weak self] in
            guard let self = self, let setting = self.setting else { return }
            let vc = DemoRingtoneViewController(setting: setting)
            self.demoPushOrPresent(vc)
        }
        appendItem("模拟扫一扫") { [weak self] in
            guard let self = self else { return }
            LarkMediaManager.shared.tryLock(scene: .imCamera, observer: self) {
                switch $0 {
                case .success:
                    DispatchQueue.main.async {
                        let vc = DemoCameraViewController()
                        self.demoPushOrPresent(vc)
                        self.cameraVC = vc
                    }
                case .failure(let error):
                    if case MediaMutexError.occupiedByOther(_, let msg) = error {
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil))
                            self.present(alert, animated: true)
                        }
                    }
                    Logger.ui.info("scan failed for error: \(error)")
                }
            }
        }
        if #available(iOS 13.0, *), UIApplication.shared.supportsMultipleScenes {
            appendItem("Create Scene") { [weak self] in
                guard let ws = self?.view.window?.windowScene else { return }
                let scene = Scene(key: DemoAssembly.DemoScene.key, id: UUID().uuidString)
                SceneManager.shared.active(strategy: .createOrActive(scene), from: ws) { (_, _, _) in
                    Logger.ui.info("create scene \(scene) finished.")
                }
            }
        }
        appendItem("sd风格化") { [weak self] in
            let alert = UIAlertController(title: nil, message: "Stable Diffusion布在VC Mac上，确保在内网环境下，Mac启动并sd服务开启", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "已知晓", style: .cancel, handler: { [weak self] _ in
                let vc = VCPersonasBasicViewController()
                self?.demoPushOrPresent(vc)
            }))
            self?.present(alert, animated: true)
        }


        self.tableView.reloadData()
    }

    private func appendItem(_ title: String, action: @escaping () -> Void) {
        self.items.append(.init(title: title, action: action))
    }

    private func push(_ urlString: String, context: [String: Any] = [:]) {
        if let url = URL(string: urlString) {
            self.navigator.push(url, context: context, from: self)
        }
    }

    private func joinMeetingByLink(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let queryParameters = url.queryParameters
        logger.info("handle applink queryParameters = \(queryParameters)")
        guard let source = queryParameters["source"], let action = queryParameters["action"], let id = queryParameters["id"] else {
            logger.error("handle applink error by unsupported param")
            return
        }
        let idType = queryParameters["idtype"] ?? "unknown"
        var preview: Bool
        if let previewString = queryParameters["preview"], let previewInt = Int(previewString) {
            preview = previewInt == 1 ? true : false
        } else {
            preview = true
        }
        var mic: Bool?
        if let micString = queryParameters["mic"], let micInt = Int(micString) {
            mic = micInt == 1 ? true : false
        }
        var speaker: Bool?
        if let speakerString = queryParameters["speaker"], let speakerInt = Int(speakerString) {
            speaker = speakerInt == 1 ? true : false
        }
        var camera: Bool?
        if let cameraString = queryParameters["camera"], let cameraInt = Int(cameraString) {
            camera = cameraInt == 1 ? true : false
        }
        var context: [String: Any] = [
            "source": source,
            "action": action,
            "id": id,
            "idType": idType,
            "preview": preview
        ]
        if let role = queryParameters["role"] {
            context["role"] = role
        }
        if let no = queryParameters["no"] {
            context["no"] = no
        }
        if let mic = mic {
            context["mic"] = mic
        }
        if let speaker = speaker {
            context["speaker"] = speaker
        }
        if let camera = camera {
            context["camera"] = camera
        }
        self.push("//client/videochat/open", context: context)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if let cell = cell as? DemoTableViewCell {
            cell.updateItem(item)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        items[indexPath.row].action()
    }
}

extension MeetingTestViewController: MediaResourceInterruptionObserver {

    var observerIdentifier: String { "\(hashValue)" }

    func mediaResourceWasInterrupted(by scene: MediaMutexScene, type: MediaMutexType, msg: String?) {
        logger.info("mediaResourceWasInterrupted by scene: \(scene) type: \(type) msg: \(msg ?? "")")
        DispatchQueue.main.async {
            let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好", style: .cancel, handler: { [weak self] _ in
                self?.cameraVC?.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true)
        }
    }

    func mediaResourceInterruptionEnd(from scene: MediaMutexScene, type: MediaMutexType) {
        logger.info("mediaResourceInterruptionEnd by scene: \(scene) type: \(type)")
    }
}

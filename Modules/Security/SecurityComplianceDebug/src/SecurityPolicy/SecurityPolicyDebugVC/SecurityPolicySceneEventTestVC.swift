//
//  SecurityPolicySceneEventTestVC.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/8/14.
//

import Foundation
import LarkContainer
import LarkSecurityCompliance
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import LarkCache
import LarkAccountInterface
import EENavigator

class SecurityPolicyOperateVC<T: Equatable>: UITableViewController {
    let dataSource: [T]
    var selectList: [T] = []
    let complete: ([T])->Void
    
    init(dataSource: [T], complete: @escaping ([T])->Void) {
        self.dataSource = dataSource
        self.complete = complete
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SecurityPolicyOperateCell") ?? UITableViewCell(style: .default, reuseIdentifier: "SecurityPolicyOperateCell")
        cell.textLabel?.text = (dataSource[indexPath.row] as? String) ?? ""
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < dataSource.count else {
            return
        }
        let operate = dataSource[indexPath.row]
        selectList.append(operate)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard indexPath.row < dataSource.count else {
            return
        }
        let select = dataSource[indexPath.row]
        selectList.removeAll { data in
            data == select
        }
    }
    
    func goBack() {
        complete(selectList)
    }
}

final class SecurityPolicySceneRegisterDebugController: UIAlertController {
    
    var userResolver: UserResolver?
    
    var selectOperates: [EntityOperate]?
    var selectPointKeys: [PointKey]?
    var entityTypes: [Entity]?
    
    let operateMap: [EntityOperate: PointKey] = [
        .ccmCopy: .ccmCopy,
        .ccmExport: .ccmExport,
        .ccmFileDownload: .ccmFileDownload,
        .ccmAttachmentDownload: .ccmAttachmentDownload,
        .openExternalAccess: .ccmOpenExternalAccess,
        .ccmCreateCopy: .ccmCreateCopy
    ]
    
    var complete: ((SecurityPolicy.SceneContext?) -> Void)?
    let entityDomianVC: PickViewController = {
        let list = EntityDomain.allCases.map { return $0.rawValue }
        return PickViewController(model: list)
    }()
    let entityTypeVC: PickViewController = {
        let list = EntityType.allCases.map { return $0.rawValue }
        return PickViewController(model: list)
    }()
    let fileBizVC: PickViewController = {
        let list = FileBizDomain.allCases.map { return $0.rawValue }
        return PickViewController(model: list)
    }()
    
    let sceneVC: PickViewController = {
        let list = SecurityPolicy.Scene.allCases.map { return $0 }
        return PickViewController(model: list)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addTextField { [weak self] textField in
            guard let `self` = self else { return }
            textField.placeholder = "entityDomain 0"
            let picker = UIPickerView()
            textField.inputView = picker
            picker.dataSource = self.entityDomianVC
            picker.delegate = self.entityDomianVC
            self.entityDomianVC.getSelected = {
                textField.text = $0
            }
        }
        addTextField { [weak self] textField in
            guard let `self` = self else { return }
            textField.placeholder = "entityType 1"
            let picker = UIPickerView()
            textField.inputView = picker
            picker.dataSource = self.entityTypeVC
            picker.delegate = self.entityTypeVC
            self.entityTypeVC.getSelected = {
                textField.text = $0
            }
        }
        
        addTextField { [weak self] textField in
            guard let `self` = self else { return }
            textField.placeholder = "fileBiz 2"
            let picker = UIPickerView()
            textField.inputView = picker
            picker.dataSource = self.fileBizVC
            picker.delegate = self.fileBizVC
            self.fileBizVC.getSelected = {
                textField.text = $0
            }
        }
        addTextField { $0.placeholder = "token 3" }
        addTextField { $0.placeholder = "ownerTenantID 默认为空 4" }
        addTextField { $0.placeholder = "ownerUserID 默认为空 5" }
        addTextField { [weak self] textField in
            guard let `self` = self else { return }
            textField.placeholder = "scene 6"
            let picker = UIPickerView()
            textField.inputView = picker
            picker.dataSource = self.sceneVC
            picker.delegate = self.sceneVC
            self.sceneVC.getSelected = {
                textField.text = $0
            }
        }
        
        addAction(UIAlertAction(title: "确定", style: .default, handler: { [weak self] _ in
            guard let `self` = self else { return }
            guard let textFields = self.textFields,
                  let entityDomain = EntityDomain(rawValue: textFields[0].text ?? ""),
                  let entityType = EntityType(rawValue: textFields[1].text ?? ""),
                  let fileBiz = FileBizDomain(rawValue: textFields[2].text ?? "") else { return }
            let userService = try? self.userResolver?.resolve(assert: PassportUserService.self)
            guard let tenantID = Int64(userService?.userTenant.tenantID ?? ""),
                  let userID = Int64(userService?.user.userID ?? "") else { return }
            
            var policyModels: [PolicyModel] = []
            self.operateMap.keys.forEach({ operate in
                guard let pointKey = self.operateMap[operate] else {
                    return
                }
                var temp: PolicyModel?
                switch fileBiz {
                case .ccm:
                    let entity = CCMEntity(entityType: entityType, entityDomain: entityDomain, entityOperate: operate, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: fileBiz, token: textFields[3].text, ownerTenantId: Int64(textFields[4].text ?? "") ?? nil, ownerUserId: Int64(textFields[5].text ?? "") ?? nil)
                    temp = PolicyModel(pointKey, entity)
                case .calendar:
                    let entity = CalendarEntity(entityType: entityType, entityDomain: entityDomain, entityOperate: operate, operatorTenantId: tenantID, operatorUid: userID, fileBizDomain: fileBiz, token: textFields[3].text, ownerTenantId: Int64(textFields[4].text ?? "") ?? nil, ownerUserId: Int64(textFields[5].text ?? "") ?? nil)
                    temp = PolicyModel(pointKey, entity)
                default:
                    return
                }
                                       
                guard let temp = temp else {
                    return
                }
                policyModels.append(temp)
            })
            switch textFields[6].text {
            case "ccmFile":
                let sceneContext = SecurityPolicy.SceneContext(userResolver: self.userResolver ?? Container.shared.getCurrentUserResolver(), scene: .ccmFile(policyModels))
                self.complete?(sceneContext)
            default:
                self.complete?(nil)
            }
        }))
        

    }
}

extension SecurityPolicy.Scene: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .ccmFile(let value):
            try container.encode(value, forKey: .ccmFile)
        @unknown default:
            return
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let policyModels = try container.decode([PolicyModel].self, forKey: .ccmFile)
        self = .ccmFile(policyModels)
    }

    enum CodingKeys: String, CodingKey {
        case ccmFile
    }
}

class SecurityPolicySceneEventTestVC: UITableViewController {
    
    let userResplver: UserResolver
    var dataSource: [SecurityPolicy.SceneContext] = []
    let cache: CryptoCache
    let cacheKey: String = "DebugSceneContextItems"
    init(resolver: UserResolver) {
        let userService: PassportUserService? = try? resolver.resolve(assert: PassportUserService.self)
        cache = securityComplianceCache(userService?.user.userID ?? "", .securityPolicy())
        if let data: Data = cache.object(forKey: cacheKey) {
            let decoder = JSONDecoder()
            do {
                let scenes = try decoder.decode([String :SecurityPolicy.Scene].self, from: data)
                dataSource = scenes.compactMap({ (identifier, scene) in
                    #if DEBUG || ALPHA
                    return SecurityPolicy.SceneContext(userResolver: Container.shared.getCurrentUserResolver(), scene: scene, identifier: identifier)
                    #endif
                    //swiftlint:disable all
                    return SecurityPolicy.SceneContext(userResolver: Container.shared.getCurrentUserResolver(), scene: scene)
                    //swiftlint:enable all
                })
            } catch {
                
            }
        }
        userResplver = resolver
        super.init(nibName: nil, bundle: nil)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SecurityPolicySceneEventTestCell")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "场景事件"
        self.view.backgroundColor = .white
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(removeSceneContext)),
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addSceneContext))
        ]
        
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SecurityPolicySceneEventTestCell")
        cell?.textLabel?.text = dataSource[indexPath.row].identifier
        return cell ?? UITableViewCell(style: .default, reuseIdentifier: "SecurityPolicySceneEventTestCell")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let context = dataSource[indexPath.row]
        let vc = sceneContextVC(context: context)
        guard let from = Navigator.shared.mainSceneWindow?.fromViewController else {
            return
        }
        Navigator.shared.push(vc, from: from)
    }
    
    
    @objc func addSceneContext() {
        DispatchQueue.main.async {
            let vc = SecurityPolicySceneRegisterDebugController(title: "Add SceneContext", message: nil, preferredStyle: .alert)
            vc.userResolver = self.userResplver
            vc.complete = { [weak self] context in
                guard let self, let context = context else { return }
                self.dataSource.append(context)
                let dictionary: [String: SecurityPolicy.Scene] = self.dataSource.reduce([:]) { partialResult, context in
                    var partialResult = partialResult
                    partialResult[context.identifier] = context.scene
                    return partialResult
                }
                let encoder = JSONEncoder()
                do {
                    let data = try encoder.encode(dictionary)
                    self.cache.set(object: data, forKey: self.cacheKey)
                } catch {
                    SCLogger.info("encode fail")
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
            Navigator.shared.present(vc, from: fromVC)
        }
    }
    @objc func removeSceneContext() {
        DispatchQueue.main.async {
            self.dataSource.forEach { context in
                context.endTrigger()
            }
            self.dataSource.removeAll()
            self.cache.removeAllObjects()
            self.tableView.reloadData()
        }
    }
}

class sceneContextVC: UIViewController {
    let sceneContext: SecurityPolicy.SceneContext
    
    lazy var beginButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 10, y: 80, width: (UIWindow.ud.windowBounds.size.width - 40) / 2, height: 100))
        button.setTitleColor(UIColor.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.backgroundColor = UIColor.gray
        button.setTitle("begin", for: .normal)
        button.addTarget(self, action: #selector(beginButtonTapped), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    lazy var endButton: UIButton = {
        let width = (UIWindow.ud.windowBounds.size.width - 40) / 2
        let button = UIButton(frame: CGRect(x: width + 20, y: 80, width: width, height: 100))
        button.setTitleColor(UIColor.black, for: .normal)
        button.backgroundColor = UIColor.gray
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitle("end", for: .normal)
        button.addTarget(self, action: #selector(endButtonTapped), for: UIControl.Event.touchUpInside)
        return button
    }()
    
    lazy var textLable: UILabel = {
        let textField = UILabel(frame: CGRect(x: 10, y: 220, width: UIWindow.ud.windowBounds.size.width - 20, height: 700))
        var text = "identifier: \(sceneContext.identifier) \n"
        if case .ccmFile(let policyModels) = self.sceneContext.scene {
            policyModels.forEach { policyModel in
                text = text + "\(policyModel.taskID) \n"
            }
        }
        textField.text = text
        textField.lineBreakMode = .byWordWrapping
        textField.numberOfLines = 0
        textField.textColor = UIColor.black
        textField.backgroundColor = UIColor.white
        return textField
    }()
    
    lazy var statusLable: UILabel = {
        let textField = UILabel(frame: CGRect(x: 10, y: 200, width: UIWindow.ud.windowBounds.size.width - 20, height: 20))
        var text = "\(sceneContext.identifier) \n"
        if case .ccmFile(let policyModels) = self.sceneContext.scene {
            policyModels.forEach { policyModel in
                text = text + "\(policyModel.taskID) \n"
            }
        }
        let debugservice = Container.shared.getCurrentUserResolver().resolve(SecurityPolicyDebugService.self)
        let contains = debugservice?.getSceneContexts().contains(where: { context in
            context.identifier == self.sceneContext.identifier
        })

        textField.text = "当前状态：" + (contains.isTrue ? "已启动" : "已关闭")
        textField.lineBreakMode = .byWordWrapping
        textField.numberOfLines = 0
        textField.textColor = UIColor.black
        textField.backgroundColor = UIColor.white
        return textField
    }()
    
    init(context: SecurityPolicy.SceneContext) {
        sceneContext = context
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(beginButton)
        self.view.addSubview(endButton)
        self.view.addSubview(statusLable)
        self.view.addSubview(textLable)
        
    }
    
    @objc func beginButtonTapped() {
        self.sceneContext.beginTrigger()
        updateStatus()
    }
    
    @objc func endButtonTapped() {
        self.sceneContext.endTrigger()
        updateStatus()
    }
    
    func updateStatus() {
        let debugservice = Container.shared.getCurrentUserResolver().resolve(SecurityPolicyDebugService.self)
        let contains = debugservice?.getSceneContexts().contains(where: { context in
            context.identifier == self.sceneContext.identifier
        })

        statusLable.text = "当前状态：" + (contains.isTrue ? "已启动" : "已关闭")
    }
    
    @objc func updateButtonTapped() {
//        self.sceneContext.updateTrigger(<#T##SecurityPolicy.Scene#>)
    }
}

class SecurityPolicyCacheViewController: UIViewController {
    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    let label: UILabel = {
        let textField = UILabel(frame: UIWindow.ud.windowBounds)
        textField.lineBreakMode = .byWordWrapping
        textField.numberOfLines = 0
        textField.textColor = UIColor.black
        textField.textAlignment = .center
        textField.backgroundColor = UIColor.white
        return textField
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(label)
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(constructPointModel))
        ]
    }

    @objc
    func constructPointModel() {
        DispatchQueue.main.async {
            guard let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
            let vc = FileOperateControlAlertDebugController(title: "构造model", message: nil, preferredStyle: .alert)
            vc.userResolver = self.userResolver
            vc.complete = { [weak self] (policyModel, _) in
                guard let self else { return }
                if SecurityPolicyAssembly.enableSecurityPolicyV2 {
                    let cache = try? self.userResolver.resolve(assert: SecurityPolicyCacheService.self)
                    let dynamicResult = cache?.value(policyModel:policyModel.associateDynamicPolicyModel ?? policyModel)
                    let staticResult = cache?.value(policyModel:policyModel.associateStaticPolicyModel ?? policyModel)
                    var text = dynamicResult != nil ? "动态缓存结果(DLP)：\(String(describing: dynamicResult)) \n" : ""
                    text = text + (staticResult != nil ? "静态缓存结果(文件策略管理)：\(String(describing: staticResult))" : "")
                    self.label.text = !text.isEmpty ? text : "null"
                } else {
                    let cache = try? self.userResolver.resolve(assert: SecurityPolicyCacheProtocol.self)
                    let dynamicResult = cache?.read(policyModel:policyModel.associateDynamicPolicyModel ?? policyModel)
                    let staticResult = cache?.read(policyModel:policyModel.associateStaticPolicyModel ?? policyModel)
                    var text = dynamicResult != nil ? "动态缓存结果(DLP)：\(String(describing: dynamicResult)) \n" : ""
                    text = text + (staticResult != nil ? "静态缓存结果(文件策略管理)：\(String(describing: staticResult))" : "")
                    self.label.text = !text.isEmpty ? text : "null"
                }
            }
            Navigator.shared.present(vc, from: fromVC)
        }
    }
}

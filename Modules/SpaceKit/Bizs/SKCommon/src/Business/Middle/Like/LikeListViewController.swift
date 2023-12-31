//
//  LikeListViewController.swift
//  SpaceKit
//
//  Created by Webster on 2018/12/4.
//

import Foundation
import SnapKit
import SwiftyJSON
import EENavigator
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignToast
import UniverseDesignColor
import SpaceInterface
import SKInfra

typealias LikesRequestFinish = (_ code: Int, _ success: Bool) -> Void

public protocol LikeListDelegate: AnyObject {
     func requestDisplayUserProfile(userId: String, fileName: String?, listController: LikeListViewController)
     func requestCreateBrowserView(url: String, config: FileConfig) -> UIViewController?
}

public final class LikeListViewController: BaseViewController {

    public enum OpenListFrom {
        case fromBotMessage //从机器人推送链接进入点赞列表
        case fromDocDetails //从文档详情进入点赞列表
        func eventName() -> String {
            switch self {
            case .fromBotMessage:
                return "from_lark_info"
            default:
                return "from_click"
            }
        }
    }

    public weak var listDelegate: LikeListDelegate?
    private var token: String //file token
    private var type: DocLikesType
    private var datas: [LikeUserInfo] = [LikeUserInfo]() //collection view data source
    private var likesUserData: [LikeUserDetails] = [LikeUserDetails]()
    private var openFrom: OpenListFrom = .fromDocDetails
    private var docTitle: String?

    private var likeNumberRequest: DocsRequest<JSON>?
    private var likeListRequest: DocsRequest<JSON>?
    private var wikiNodeRequest: DocsRequest<JSON>?
    private var lastLikeId: String = "0"
    private var hasMore: Bool = false
    private let likeOnePage: Int = 20

    private var tableView: UITableView = BaseTableView()
    private var botUrl: String = ""
    private var originToken: String = ""

    /// 打开原文的按钮（只有从机器人推送过来的链接才有这个按钮）
    private lazy var barItem: SKBarButtonItem = {
        let titleTxt = BundleI18n.SKResource.Doc_Like_ViewDocument
        let button = SKBarButtonItem(title: titleTxt, style: .plain, target: self, action: #selector(didClickRightBarItem))
        button.id = .viewDocument
        button.foregroundColorMapping = SKBarButton.defaultIconColorMapping
        button.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 16, weight: .regular)], for: .normal)
        return button
    }()

    ///打开原文所需的config
    public var fileConfig: FileConfig?

    private var currentLikesNumber: Int = 0
    private var everRequest: Bool = false
    private var numberCode: Int = 999
    private var listCode: Int = 999

    private let queue = DispatchQueue.global()
    private let group = DispatchGroup()

    public init?(botUrl: String) {
        guard let url = URL(string: botUrl),
            let token = url.pathComponents.last,
            let likeType = DocLikesType.likeTypeBy(url: url) else {
            return nil
        }
        self.originToken = token
        self.botUrl = botUrl
        self.token = token
        self.type = likeType
        self.openFrom = .fromBotMessage
        super.init(nibName: nil, bundle: nil)
    }

    public init(fileToken: String, likeType: DocLikesType) {
        token = fileToken
        type = likeType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        if isWikiUrl(urlStr: self.botUrl) {
            getNodeMeta(wikiToken: token) { [weak self] _ in
                guard let self = self else { return }
                self.startLikesRequest()
            }
        } else {
            startLikesRequest()
        }
        uploadAnalyst()
    }
    
    private func isWikiUrl(urlStr: String) -> Bool {
        if let url = URL(string: urlStr) {
            let pathComponents = url.pathComponents
            if pathComponents.count >= 2 {
                let type = pathComponents[pathComponents.count - 2]
                if type == "wiki" {
                    return true
                }
            }
        }
        return false
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //从机器人推送过来的显示跳转到原文的链接
        if fileConfig != nil, openFrom == .fromBotMessage {
            setRightBarItem()
        }
    }

    func updateViewTitle() {
        let num = currentLikesNumber.description
        self.title = BundleI18n.SKResource.Doc_Like_LikeDetailsWithCount(num)
    }

    private func setRightBarItem() {
//        defer {
//            self.navigationBar.titleLabel.center.x = self.navigationBar.bounds.width / 2
//        }
        self.navigationBar.trailingBarButtonItem = barItem
    }

    func setupTableView() {
        view.addSubview(tableView)

        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.navigationBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        tableView.register(LikeUserCell.self, forCellReuseIdentifier: "LikeUserCell")
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 72
        tableView.rowHeight = UITableView.automaticDimension
        tableView.scrollsToTop = true
        tableView.contentInsetAdjustmentBehavior = .never

        tableView.backgroundColor = UDColor.bgBody
        tableView.alwaysBounceVertical = true

        tableView.es.addInfiniteScrollingOfDoc(animator: DocsThreeDotRefreshAnimator()) { [weak self] in
            guard let `self` = self else { return }
            if self.lastLikeId.elementsEqual("0") {
                self.showNoMoreDataIfNeed()
                return
            }
            self.showNoMoreDataIfNeed()
            self.requestLikesList(lastId: self.lastLikeId, finish: { [weak self] (code, _) in
                self?.tableView.es.stopLoadingMore()
                if code == 0 {
                    self?.tableView.reloadData()
                    self?.showNoMoreDataIfNeed()
                }
                self?.toastNoNet()
            })
        }
    }

    func showNoMoreDataIfNeed() {
        if !self.hasMore {
            currentLikesNumber = datas.count
            self.updateViewTitle()
            self.tableView.es.noticeNoMoreData()
        }
    }

    func toastNoNet() {
        if !DocsNetStateMonitor.shared.isReachable {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_NetworkInterrutedRetry, on: self.view.window ?? self.view)
        }
    }

    func uploadAnalyst() {
        let params = ["praise_page_source": self.openFrom.eventName()]
        DocsTracker.log(enumEvent: .showPraisePage, parameters: params)
    }

    @objc
    private func didClickRightBarItem() {
        guard let config = fileConfig else { return }
        var url = DocsUrlUtil.url(type: self.type.docType(), token: token)
        if isWikiUrl(urlStr: self.botUrl) {
            url = DocsUrlUtil.url(type: .wiki, token: originToken)
        }
        if let vc = listDelegate?.requestCreateBrowserView(url: url.absoluteString, config: config) {
            if let navigator = navigationController {
                navigator.pushViewController(vc, animated: true)
            } else {
                present(vc, animated: true, completion: nil)
            }
        }
    }
    
    public override var canShowFullscreenItem: Bool { true }
}

extension LikeListViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LikeUserCell") as? LikeUserCell else {
            return UITableViewCell()
        }

        cell.clickDelegate = self
        cell.configBy(info: datas[indexPath.row])
        cell.selectionStyle = .none

        return cell
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72.0
    }
}

//network request manager
extension LikeListViewController {
    private func getNodeMeta(wikiToken: String, completion: ((Bool) -> Void)? = nil) {
        var params: [String: Any] = [String: Any]()
        params["wiki_token"] = wikiToken
        wikiNodeRequest?.cancel()
        wikiNodeRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.wikiNodeTypeV2, params: params)
            .set(method: .GET)
            .start(result: { [weak self] (response, _) in
                guard let self = self else { return }
                guard let code = response?["code"].int, code == 0 else {
                    DocsLogger.info("Request wikiNodeTypeV2 error: code is not equal 0")
                    completion?(false)
                    return
                }
                guard let data = response?["data"].dictionaryObject else {
                    DocsLogger.info("Request wikiNodeTypeV2 data is nil")
                    completion?(false)
                    return
                }
                
                if let token = data["obj_token"] as? String {
                    DocsLogger.info("Request wikiNodeTypeV2 success")
                    self.token = token
                }
                if let objType = data["obj_type"] as? Int {
                    let docsType = DocsType(rawValue: objType)
                    DocsLogger.info("Request wikiNodeTypeV2 get type:\(docsType)")
                    self.type = DocLikesType.transformToLikeType(use: docsType)
                } else {
                    DocsLogger.info("Request wikiNodeTypeV2 type is nil: \(String(describing: data["obj_type"]))")
                }
                completion?(true)
            })
    }

    func startLikesRequest() {
        showLoading()
        queue.async(group: group, execute: DispatchWorkItem(block: { [weak self] in
            guard let self = self else { return }
            self.group.enter()
            self.queue.async {
                self.requestLikesNumbers(finish: { (code, _) in
                    self.numberCode = code
                    self.group.leave()
                })
            }

            self.group.enter()
            self.queue.async {
                self.requestLikesList(lastId: "0", finish: { (code, _) in
                    self.listCode = code
                    self.group.leave()
                })
            }

            self.group.enter()
            self.queue.async {
                self._requestDocsInfo(finish: { (_) in
                    self.group.leave()
                })
            }

            self.group.notify(queue: DispatchQueue.main, execute: {
                if self.numberCode == 0 && self.listCode == 0 {
                    self.updateViewTitle()
                    self.tableView.reloadData()
                    self.hideLoading()
                    self.showNoMoreDataIfNeed()
                } else {
                    self.currentLikesNumber = 0
                    self.updateViewTitle()
                    self.tableView.reloadData()
                    self.hideLoading()
                    self.tableView.es.resetNoMoreData()
                }
            })

        }))
    }

    private func _requestDocsInfo(finish: @escaping (Bool) -> Void) {
        let params: [String: Any] = ["type": type.docType().rawValue,
                                     "token": token]
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.findMeta, params: params)
            .set(method: .GET)
            .start { [weak self] (info, err) in
                guard let self = self else {
                    DocsLogger.info("Request DocsInfo error: self is dealloc")
                    finish(false)
                    return
                }
                if let err = err {
                    DocsLogger.info("Request DocsInfo error \(err)")
                    finish(false)
                    return
                }
                self.docTitle = info?["data"]["title"].string
                finish(self.docTitle != nil)
            }
        request.makeSelfReferenced()
    }

    func requestLikesNumbers(finish: @escaping LikesRequestFinish) {
        var params: [String: Any] = [String: Any]()
        params["token"] = token
        params["refer_type"] = type.rawValue

        likeNumberRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.likesCount, params: params)
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .start(result: { [weak self] (likesInfo, _) in
                let code = likesInfo?["code"].int ?? 999
                if code == 0 {
                    let dstNumber = likesInfo?["data"]["count"].rawValue as? Int
                    self?.currentLikesNumber = dstNumber ?? 0
                }

                finish(code, code == 0)

            })
    }

    func requestLikesList(lastId: String, finish: @escaping LikesRequestFinish) {
        var params: [String: Any] = [String: Any]()
        params["token"] = token
        params["refer_type"] = type.rawValue
        params["last_like_id"] = lastId
        params["page_size"] = likeOnePage
        likeListRequest?.cancel()
        likeListRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.likesList, params: params)
            .set(method: .GET)
            .set(encodeType: .urlEncodeDefault)
            .start(result: { [weak self] (likesInfo, _) in
                let code = likesInfo?["code"].int ?? 999
                self?.listCode = code
                if code == 0 {
                    let data = likesInfo?["data"].dictionary
                    self?.handlerLikeListData(data)
                }
                finish(code, code == 0)
            })
    }

    func handlerLikeListData(_ data: [String: JSON]?) {
        if let more = data?["has_more"]?.rawValue as? Bool {
            hasMore = more
        }

        if let users = data?["users"]?.dictionary {
            likesUserData.removeAll()
            for (_, json) in users {
                let user = LikeUserDetails.objByJson(json: json)
                likesUserData.append(user)
            }
        }

        var infos: [LikeUserInfo] = []
        if let ids = data?["ids"]?.array, let likes = data?["likes"]?.dictionary {
            if hasMore {
                lastLikeId = ids.last?.rawString() ?? "0"
            } else {
                lastLikeId = "0"
            }
            for idString in ids {
                if let likeId = idString.rawString(), let info = likes[likeId] {
                    let likeInfo = jointLikeInfo(json: info)
                    
                    //从likesUserData里面取出displayTag数据赋值给 likeInfo
                    let matchUser = likesUserData.first(where: { $0.userId.elementsEqual(likeInfo.likeThisUserId) })
                    if let user = matchUser {
                        likeInfo.displayTag = user.displayTag
                    }
                    
                    infos.append(likeInfo)
                }
            }
        }

        if let currentUserID = User.current.info?.userID,
            let currentLikeUserInfo = infos.first(where: { $0.likeThisUserId == currentUserID }) {
            let tempDatas = infos.filter { $0 != currentLikeUserInfo }
            datas.insert(currentLikeUserInfo, at: 0)
            datas.append(contentsOf: tempDatas)
        } else {
            datas.append(contentsOf: infos)
        }

    }

    private func jointLikeInfo(json: JSON) -> LikeUserInfo {
        let info = LikeUserInfo.objByJson(json: json)
        let matchUser = likesUserData.first(where: { $0.userId.elementsEqual(info.likeThisUserId) })
        if let user = matchUser {
            info.avatarURL = user.avatarUrl
            info.name = user.name
            info.displayName = user.displayName
            info.tenantId = user.tenantId
            info.allowEnterProfile = user.allowEnterProfile
        }
        return info
    }
}

extension LikeListViewController: EmptyTableViewDataSource {
    public func itemsCount() -> Int {
        return datas.count
    }

    public func emptyView() -> EmptyListPlaceholderView? {
        if !everRequest {
            everRequest = true
            return nil
        }

        let view = EmptyListPlaceholderView(frame: CGRect.zero)

        if DocsNetStateMonitor.shared.isReachable {
            if hasPermission() {
                //不是所有的都是严格的错误页，只是复用了错误页面的UI，请注意不要误判
                view.config(error: ErrorInfoStruct(type: .cancelLike, title: BundleI18n.SKResource.Doc_Like_LikeNoData, domainAndCode: nil))
            } else {
                view.config(error: ErrorInfoStruct(type: .noPermission, title: BundleI18n.SKResource.Doc_Facade_NoPermissionAccessTip, domainAndCode: nil))
            }
        } else {
            view.config(error: ErrorInfoStruct(type: .noNet, title: BundleI18n.SKResource.Doc_Facade_NetworkInterrutedRetry, domainAndCode: nil))
        }

        return view
    }

    private func hasPermission() -> Bool {
        let noPermissionCode: Int = 4
        return (listCode != noPermissionCode) && (numberCode != noPermissionCode)
    }
}

extension LikeListViewController: LikeUserCellDelegate {
    func didReceiveTapEventAtProfileView(_ cell: LikeUserCell) {
        guard let userId = cell.model?.likeThisUserId else {
            return
        }
        guard let isAllow = cell.model?.allowEnterProfile, isAllow else {
            DocsLogger.info("tap user in likelist, but NOT allowEnterProfile")
            return
        }
        DocsTracker.log(enumEvent: .clientPraiseIcon, parameters: nil)
        self.listDelegate?.requestDisplayUserProfile(userId: userId, fileName: docTitle, listController: self)
    }
}

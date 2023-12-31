//
//  AskOwnerForExternalCollaboratorController.swift
//  SKCommon
//
//  Created by zoujie on 2020/9/20.
//
//swiftlint:disable file_length
import SKResource
import SKUIKit
import SKFoundation
import SwiftyJSON
import EENavigator
import UniverseDesignToast
import LarkTraitCollection
import RxSwift
import UniverseDesignActionPanel
import UniverseDesignColor
import UniverseDesignInput
import CoreGraphics
import SpaceInterface
import SKInfra

//swiftlint:disable type_body_length
public final class AskOwnerForInviteCollaboratorViewController: SKWidgetViewController,
                                                          UITableViewDataSource, UIGestureRecognizerDelegate,
                                                          PermissionTopTipViewDelegate, UITextViewDelegate {
    enum FromScene: Int {
        case addCollaborator
        case imCard
        case applyEdit
    }

    enum Permission: Int {
        case read = 1
        case edit = 4
    }

    enum RustDocType: Int {
        case unknown
        case doc // = 1
        case sheet // = 2
        case bitable // = 3
        case mindnote // = 4
        case file // = 5
        case slides // = 6
        case wiki  // = 7
        case docx  // = 8
        case sync = 13 // 13
        func docType() -> ShareDocsType {
            switch self {
            case .doc: return .doc
            case .sheet: return .sheet
            case .bitable: return .bitable
            case .mindnote: return .mindnote
            case .file: return .file
            case .slides: return .slides
            case .wiki: return .wiki
            case .docx: return .docX
            case .sync: return .sync
            case .unknown: return ShareDocsType.unknownDefaultType
            }
        }
    }

    private var fileModel: CollaboratorFileModel
    private var requestMessage: UDMultilineTextField = UDMultilineTextField()

    ///提示信息，IM场景和邀请外部协作者场景提示信息不同
    private(set) var permissionTipString: String = ""
    ///提示信息富文本
    private(set) var permissionTipAttributeString: NSMutableAttributedString?

    private(set) var shareFolderInfo: FolderEntry.ShareFolderInfo?
    ///布局信息，用来判断当前页面是从IM卡片进入还是邀请外部协作者进入
    private(set) var layoutConfig: CollaboratorInviteModeConfig?
    ///ask owner请求
    private var fileInviteRequest: DocsRequest<Any>?
    
    private let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
    ///请求权限文案：编辑权限、阅读权限
    private(set) var requestPermission: String = BundleI18n.SKResource.Doc_Facade_ReadPermission
    ///当前选择请求的权限
    private(set) var requestPermissionCode: Permission = .read
    ///页面标题
    private(set) var titleText: String?
    ///页面高度
    private var currentHeight: CGFloat = 250
    ///页面最大高度
    private let maxHeight: CGFloat = 648
    ///权限文案高度
    private var permissionTipViewHeight: CGFloat = 0
    ///邀请协作者cell高度
    private let cellHeight: Int = 66
    ///页面内元素左右边距
    private let leftMargin: CGFloat = 16
    ///监听 keyboard 事件
    private let keyboard = Keyboard()
    ///埋点相关
    private var statistics: CollaboratorStatistics?
    /// 权限新埋点
    private var permStatistics: PermissionStatistics?
    ///placeholder
    private var placeHolderString: String = ""
    private var isPlaceHolderOpportunity: Bool = true
    // 按钮文案
    private var buttonTitle: String = ""
    // 按钮点击事件
    private var actionCallback: ((String) -> Void)?
    // 取消事件
    private var cancelCallback: (() -> Void)?

    private let cellReuseIdentifier: String = "CollaboratorSearchResultCell"

    private let bag = DisposeBag()

    private var actionsheet: UDActionSheet?

    private var isDismissed: Bool = false
    // 正在做消失动画
    private var isDismissing: Bool = false
    
    private var fromScene: FromScene = .addCollaborator

    var datas: [CollaboratorSearchResultCellItem] = []
    
    var items: [Collaborator] = [] {
        didSet {
            self.datas = self.items.map {
                return CollaboratorSearchResultCellItem(collaboratorID: $0.userID,
                                                        selectType: .none,
                                                        imageURL: $0.avatarURL,
                                                        imageKey: $0.imageKey,
                                                        title: $0.name,
                                                        detail: $0.detail,
                                                        isExternal: $0.isExternal,
                                                        blockExternal: $0.blockExternal,
                                                        isCrossTenanet: $0.isCrossTenant,
                                                        roleType: $0.type,
                                                        userCount: $0.userCount,
                                                        organizationTagValue: $0.organizationTagValue)
            }
        }
    }

    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    private lazy var topContainerView: UIView = {
        var view = UIView()
        
        var label = UILabel()
        label.textColor = UIColor.ud.N900
        label.textAlignment = .left
        label.text = titleText
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        
        var underLine = UIView()
        underLine.backgroundColor = UIColor.ud.N300
        
        view.addSubview(label)
        view.addSubview(underLine)
        
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(leftMargin)
            make.right.equalToSuperview().offset(-leftMargin)
            make.bottom.equalTo(underLine.snp.top)
        }
        
        underLine.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-2)
            make.top.equalTo(label.snp.bottom)
            make.height.equalTo(0.5)
        }
        
        return view
    }()
    
    private lazy var permissionTopTipView: PermissionTopTipView = {
        var textView = PermissionTopTipView()
        textView.backgroundColor = .clear
        textView.setIconHidden(true)
        var commString = permissionTipString

        let attrContent = NSAttributedString(string: commString)
        let mutableStr = NSMutableAttributedString(attributedString: attrContent)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        mutableStr.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: mutableStr.string.count))

        let select = NSTextAttachment(data: nil, ofType: nil)
        select.image = BundleResources.SKResource.Common.Global.icon_global_arrowdown_nor
        select.bounds = CGRect(x: 0, y: -3, width: 16, height: 16)
        let permissionAtt = NSAttributedString(string: self.requestPermission)
        let mutablePermStr = NSMutableAttributedString(attributedString: permissionAtt)
        mutablePermStr.append(NSAttributedString(attachment: select))
        mutablePermStr.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.ud.colorfulBlue], range: NSRange(location: 0, length: mutablePermStr.string.count))

        if let range = mutableStr.string.range(of: "@" + fileModel.displayName) {
            var nsRange = mutableStr.string.toNSRange(range)
            nsRange = NSRange(location: nsRange.location, length: nsRange.length)
            textView.addTapRange(nsRange)
            mutableStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ud.colorfulBlue, range: nsRange)
        }
        
        if let range = mutableStr.string.range(of: self.requestPermission) {
            let nsRange = mutableStr.string.toNSRange(range)
            mutableStr.replaceCharacters(in: nsRange, with: mutablePermStr)
            if nsRange.length > 1 {
                textView.addTapRange(NSRange(location: nsRange.location, length: nsRange.length - 1))
            }
        }
        self.permissionTipAttributeString = mutableStr
        textView.paragraphStyle = paragraphStyle
        textView.attributeTitle = mutableStr
        textView.linkCheckEnable = true
        textView.delegate = self
        return textView
    }()
    
    private lazy var collaboratorInvitationTableView: UITableView = {
        let tableView = UITableView()
        tableView.allowsSelection = false
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.rowHeight = CGFloat(cellHeight)
        tableView.isScrollEnabled = false
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.register(CollaboratorSearchResultCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        return tableView
    }()

    private lazy var askOwnerView: UIView = {
        var view = UIView()
        var inputView = UIView()
        inputView.layer.cornerRadius = 4
        inputView.backgroundColor = UIColor.ud.N100

        var config = UDMultilineTextFieldUIConfig()
        config.textColor = UIColor.ud.N900
        config.backgroundColor = .clear
        config.textMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        config.font = UIFont.systemFont(ofSize: 14)

        requestMessage.config = config
        requestMessage.placeholder = placeHolderString

        let button = UIButton()
        button.backgroundColor = UIColor.ud.colorfulBlue
        button.layer.cornerRadius = 4
        button.setTitle(buttonTitle, withFontSize: 17, fontWeight: .regular, color: UDColor.primaryOnPrimaryFill, forState: .normal)
        button.titleEdgeInsets = UIEdgeInsets(top: 4, left: 18, bottom: 4, right: 18)
        button.addTarget(self, action: #selector(clickApplyButton(_:)), for: .touchUpInside)
        
        inputView.addSubview(requestMessage)
        view.addSubview(inputView)
        view.addSubview(button)

        requestMessage.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        inputView.snp.makeConstraints { (make) in
            make.height.equalTo(75)
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(leftMargin)
            make.right.equalToSuperview().offset(-leftMargin)
            make.bottom.equalTo(button.snp.top).offset(-20)
        }
        
        button.snp.makeConstraints { (make) in
            make.height.equalTo(48)
            make.left.equalToSuperview().offset(leftMargin)
            make.right.equalToSuperview().offset(-leftMargin)
            make.bottom.equalToSuperview().offset(-34)
            make.top.equalTo(inputView.snp.bottom).offset(20)
        }
        return view
    }()
    
    //从邀请协作者页面进入
    init(items: [Collaborator],
         fileModel: CollaboratorFileModel,
         layoutConfig: CollaboratorInviteModeConfig,
         statistics: CollaboratorStatistics?,
         permStatistics: PermissionStatistics?) {
        self.fromScene = .addCollaborator
        self.items = items
        self.fileModel = fileModel
        self.statistics = statistics
        self.permStatistics = permStatistics
        let typeString: String = (fileModel.docsType == .minutes) ? BundleI18n.SKResource.CreationMobile_Minutes_name : BundleI18n.SKResource.Doc_Facade_Document
        self.permissionTipString = BundleI18n.SKResource.CreatinoMobile_Minutes_share_external_dialog( self.requestPermission, "@" + fileModel.displayName, typeString)
        self.titleText = BundleI18n.SKResource.Doc_Permission_AskOwnerPartUserFailed
        self.placeHolderString = BundleI18n.SKResource.Doc_Permission_AskOwner_placeholder(fileModel.displayName)
        self.buttonTitle = BundleI18n.SKResource.Doc_Permission_SendApply
        let userList: [[String: Any]] = Array(items).map {
            return ["object_uid": DocsTracker.encrypt(id: $0.userID),
                    "collaborate_type": $0.rawValue]
        }
        self.permStatistics?.reportPermissionAskOwnerView(fromScene: .addCollaborator, userList: userList)
        super.init(contentHeight: currentHeight)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    ///IM 卡片邀请协作者
    ///- Parameters:
    ///  -roleType：0表示用户，2表示群
    public convenience init(collaboratorID: String,
                ownerName: String?,
                ownerID: String?,
                docsType: Int?,
                objToken: String?,
                imageKey: String,
                title: String,
                detail: String?,
                isExternal: Bool,
                isCrossTenanet: Bool,
                roleType: Int) {
        self.init(collaboratorID: collaboratorID,
                  ownerName: ownerName,
                  ownerID: ownerID,
                  shareDocsType: RustDocType(rawValue: docsType ?? 0)?.docType() ?? ShareDocsType.doc,
                  objToken: objToken,
                  imageKey: imageKey,
                  title: title,
                  detail: detail,
                  isExternal: isExternal,
                  isCrossTenanet: isCrossTenanet,
                  roleType: roleType)
    }

    ///IM 卡片邀请协作者
    ///- Parameters:
    ///  -roleType：0表示用户，2表示群
    public init(collaboratorID: String,
                ownerName: String?,
                ownerID: String?,
                shareDocsType: ShareDocsType,
                objToken: String?,
                imageKey: String,
                title: String,
                detail: String?,
                isExternal: Bool,
                isCrossTenanet: Bool,
                roleType: Int) {
        self.fromScene = .imCard
        var description: String?
        if let str = detail, str.isEmpty == false {
            description = str
        } else if CollaboratorType(rawValue: roleType) == CollaboratorType.group {
            description = BundleI18n.SKResource.Doc_Facade_NoGroupDesc
        }

        let defaultPerm: UserPermissionMask = [.read]
        let collaborator = Collaborator(rawValue: roleType, userID: collaboratorID, name: title, avatarURL: "",
                                        avatarImage: nil, imageKey: imageKey, userPermissions: defaultPerm, groupDescription: description)
        collaborator.isCrossTenant = isCrossTenanet
        self.items = [collaborator]
        self.shareFolderInfo = nil
        self.statistics = nil
        self.permissionTipString = BundleI18n.SKResource.Doc_Permission_AskOwnerFromIMTips(self.requestPermission, "@" + (ownerName ?? ""))
        self.titleText = BundleI18n.SKResource.Doc_Permission_AskOwnerShare
        self.placeHolderString = BundleI18n.SKResource.Doc_Permission_AskOwner_placeholder(ownerName ?? "")
        self.buttonTitle = BundleI18n.SKResource.Doc_Permission_SendApply
        self.fileModel = CollaboratorFileModel(objToken: objToken ?? "",
                                               docsType: shareDocsType,
                                               title: title,
                                               isOWner: false,
                                               ownerID: ownerID ?? "",
                                               displayName: ownerName ?? "",
                                               spaceID: "",
                                               folderType: .common,
                                               tenantID: "",
                                               createTime: 0,
                                               createDate: "",
                                               creatorID: "",
                                               enableTransferOwner: true,
                                               formMeta: nil)
        super.init(contentHeight: currentHeight)

        self.statistics =
        CollaboratorStatistics(docInfo: CollaboratorAnalyticsFileInfo(fileType: DocsType(rawValue: shareDocsType.rawValue).name, fileId: objToken ?? ""),
                                   module: FileListStatistics.module?.rawValue ?? FileListStatistics.Module.quickaccess.rawValue)
        let publicPermissionMeta = permissionManager.getPublicPermissionMeta(token: fileModel.objToken)
        let userPermissions = permissionManager.getUserPermissions(for: fileModel.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: DocsTracker.encrypt(id: fileModel.objToken),
                                                      fileType: fileModel.docsType.name,
                                                      module: fileModel.docsType.name,
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        self.permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
        let userList = [["object_uid": DocsTracker.encrypt(id: ownerID ?? ""), "collaborate_type": roleType]]
        self.permStatistics?.reportPermissionAskOwnerView(fromScene: .imCard, userList: userList)
    }
    
    // More面板申请编辑权限
    public init(ownerName: String = "",
                ownerID: String = "",
                permStatistics: PermissionStatistics?,
                actionCallback: ((String) -> Void)? = nil,
                cancelCallback: (() -> Void)? = nil) {
        self.fromScene = .applyEdit
        //warn: 构建fileModel的参数除了传入的ownerName和ownerID,其它都赋了一个任意值。
        self.fileModel = CollaboratorFileModel(objToken: "",
                                               docsType: .doc,
                                               title: "",
                                               isOWner: true,
                                               ownerID: ownerID,
                                               displayName: ownerName,
                                               spaceID: "",
                                               folderType: nil,
                                               tenantID: "",
                                               createTime: 0,
                                               createDate: "",
                                               creatorID: "",
                                               enableTransferOwner: true,
                                               formMeta: nil)
        self.permissionTipString = BundleI18n.SKResource.Doc_Permission_ApplyEditPermDesc("@" + ownerName)
        self.titleText = BundleI18n.SKResource.Doc_Resource_ApplyEditPerm
        self.placeHolderString = BundleI18n.SKResource.Doc_Facade_AddRemarks
        self.buttonTitle = BundleI18n.SKResource.Doc_Facade_ApplyFor
        self.actionCallback = actionCallback
        self.cancelCallback = cancelCallback
        let publicPermissionMeta = permissionManager.getPublicPermissionMeta(token: fileModel.objToken)
        let userPermissions = permissionManager.getUserPermissions(for: fileModel.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: DocsTracker.encrypt(id: fileModel.objToken),
                                                      fileType: fileModel.docsType.name,
                                                      module: fileModel.docsType.name,
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        self.permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
        self.permStatistics?.reportPermissionReadWithoutEditView()
        super.init(contentHeight: currentHeight)
    }

    public override func onDismissButtonClick() {
        isDismissing = true
        cancelCallback?()
        super.onDismissButtonClick()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let items = self.items
        self.items = items
        self.collaboratorInvitationTableView.reloadData()
        //打开Ask Owner面板埋点上报
        openAskOwnerPageStatistics()
        keyboard.on(event: .willShow) { [weak self] opt in
            guard let `self` = self else { return }
            if self.modalPresentationStyle == .formSheet {
                let viewWindowBounds = self.view.convert(self.view.bounds, to: nil)
                var offset = viewWindowBounds.maxY - opt.endFrame.minY - self.view.layoutMargins.bottom
                if self.isMyWindowRegularSizeInPad {
                    var endFrameY = (opt.endFrame.minY - self.view.frame.height) / 2
                    endFrameY = endFrameY > 44 ? endFrameY : 44
                    let moveOffest = self.view.convert(self.view.bounds, to: nil).minY - endFrameY
                    offset -= moveOffest
                }

                self.collaboratorInvitationTableView.isScrollEnabled = true
                self.askOwnerView.snp.updateConstraints { (make) in
                    make.bottom.equalToSuperview().offset(min(-offset, 0))
                }
                return
            }

            var height = opt.endFrame.size.height + self.currentHeight - self.bottomSafeAreaHeight
            let safeHeight = self.view.bounds.height - self.topSafeAreaHeight - 20
            if height > safeHeight {
                height = safeHeight
                self.collaboratorInvitationTableView.isScrollEnabled = true
            }
            self.resetContentHeight(height)
            self.askOwnerView.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview().offset(-opt.endFrame.size.height)
            }
            self.view.layoutIfNeeded()
        }
        
        keyboard.on(event: .willHide) { [weak self] _ in
            guard let `self` = self else { return }
            self.resetContentHeight(self.currentHeight)
            self.askOwnerView.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview()
            }
            self.view.layoutIfNeeded()
        }
        keyboard.start()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.singletap))
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 12
        backgroundView.layer.cornerRadius = 12
        contentView.backgroundColor = UDColor.bgBody
        backgroundView.backgroundColor = UIColor.clear

        contentView.addSubview(topContainerView)
        contentView.addSubview(permissionTopTipView)
        contentView.addSubview(collaboratorInvitationTableView)
        contentView.addSubview(askOwnerView)

        // 监听sizeClass
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] change in
                guard SKDisplay.pad else { return }
                if change.old != change.new || self?.modalPresentationStyle == .formSheet {
                    self?.dismiss(animated: false)
                    self?.actionsheet?.dismiss(animated: false)
                }
            }).disposed(by: bag)

        if modalPresentationStyle == .formSheet {
            permissionTipViewHeight = getLabelHeight(width: 508) + 28
        } else {
            permissionTipViewHeight = getLabelHeight(width: self.view.frame.width - 32) + 28
        }
        
        backgroundView.snp.remakeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(currentHeight + bottomSafeAreaHeight)
        }
        contentView.snp.updateConstraints { (make) in
            make.height.equalTo(currentHeight + bottomSafeAreaHeight)
        }
        
        topContainerView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(permissionTopTipView.snp.top).offset(2)
            make.height.equalTo(48)
        }
        
        permissionTopTipView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(topContainerView.snp.bottom).offset(-2)
            make.height.equalTo(permissionTipViewHeight)
        }
        
        collaboratorInvitationTableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(permissionTopTipView.snp.bottom).offset(-11)
            make.bottom.equalTo(askOwnerView.snp.top)
        }
        
        askOwnerView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(collaboratorInvitationTableView.snp.bottom)
        }

        currentHeight += CGFloat(items.count * cellHeight) + permissionTipViewHeight
        if currentHeight > maxHeight {
            currentHeight = maxHeight
            collaboratorInvitationTableView.isScrollEnabled = true
        }

        if modalPresentationStyle == .formSheet {
            currentHeight = getPopoverHeight()
        }

        self.resetContentHeight(currentHeight)
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.isDismissed = false
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        keyboard.stop()
    }

    override public func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        self.isDismissed = true
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard SKDisplay.pad else { return }
        self.dismiss(animated: false)
        actionsheet?.dismiss(animated: false)
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    private func getLabelHeight(width: CGFloat) -> CGFloat {
        let rect = permissionTopTipView.titleLabel.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        return rect.height
    }

    public func getPopoverHeight() -> CGFloat {
        let tipViewHeight = getLabelHeight(width: 508) + 28
        var height = CGFloat(items.count * cellHeight) + tipViewHeight + 250
        if height > maxHeight {
            height = maxHeight
        }
        return height
    }

    private func resetContentHeight(_ height: CGFloat) {
        guard !isDismissing else { return }
        self.resetHeight(height)
    }

    @objc
    private func singletap() {
        requestMessage.endEditing(true)
    }
    
    @objc
    private func clickApplyButton(_ sender: UIButton) {
        let message = requestMessage.text ?? ""
        if let actionCallback = actionCallback {
            actionCallback(message)
            dismiss(animated: false, completion: {})
            return
        }
        //埋点上报
        askOwnerForInviteCollaboratorStatistics()
        self.items.forEach { [weak self] (body) in
            guard let `self` = self else { return }
            body.userPermissions = UserPermissionMask(rawValue: self.requestPermissionCode.rawValue)
        }
        let isAddNotes = message.count > 0
        let listType: PermissionSelectOption = (requestPermissionCode == .read) ? .read : .edit
        let userList: [[String: Any]] = Array(items).map {
            return ["object_uid": DocsTracker.encrypt(id: $0.userID),
                    "collaborate_type": $0.rawValue]
        }
        let context: ReportPermissionAskOwnerClick
        switch fromScene {
        case .addCollaborator:
            context = ReportPermissionAskOwnerClick(click: .sendRequest, target: .noneTargetView, fromScene: .addCollaborator, listType: listType, isAddNotes: isAddNotes, userList: userList)
            self.permStatistics?.reportPermissionAskOwnerClick(context: context)
        case .imCard:
            context = ReportPermissionAskOwnerClick(click: .sendRequest, target: .noneTargetView, fromScene: .imCard, listType: listType, isAddNotes: isAddNotes, userList: userList)
            self.permStatistics?.reportPermissionAskOwnerClick(context: context)
        case .applyEdit:
            self.permStatistics?.reportPermissionReadWithoutEditClick(click: .apply,
                                                                      target: .noneTargetView,
                                                                      isAddNotes: isAddNotes)
        }
        let typeString: String = (self.fileModel.docsType == .minutes)
            ? BundleI18n.SKResource.CreationMobile_Minutes_name
            : BundleI18n.SKResource.Doc_Facade_Document
        self.fileInviteRequest =
            permissionManager.askOwnerForInviteCollaborator(type: fileModel.docsType.rawValue,
                                                            token: fileModel.objToken,
                                                            candidates: Set(self.items),
                                                            larkIMText: message,
                                                            complete: { [weak self] (json, response, err) in
                                                                guard let self = self else { return }

                                                                if let response = response as? HTTPURLResponse, response.statusCode == 429 {
                                                                    //请求频控，超过最大申请次数
                                                                    self.showToast(text: BundleI18n.SKResource.Doc_Permission_SendRequestMaxCount, type: .failure)
                                                                    return
                                                                }

                                                                if let error = err {
                                                                    DocsLogger.info(error.localizedDescription)
                                                                    if let netError = (error as? DocsNetworkError) {
                                                                        self.showToast(text: netError.errorMsg, type: .failure)
                                                                    } else {
                                                                        self.showToast(text: BundleI18n.SKResource.Doc_Permission_SendApplyFailed, type: .failure)
                                                                    }
                                                                    return
                                                                }
                                                                guard let json = json else {
                                                                    self.showToast(text: BundleI18n.SKResource.Doc_Permission_SendApplyFailed, type: .failure)
                                                                    DocsLogger.info("response is nil")
                                                                    return
                                                                }
                                                                guard let code = json["code"].int else {
                                                                    DocsLogger.info("parse ask owner code is not exist")
                                                                    self.showToast(text: BundleI18n.SKResource.Doc_Permission_SendApplyFailed, type: .failure)
                                                                    return
                                                                }
                                                                if code == 0 {
                                                                    self.showToast(text: BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Toast_RequestSubmitted, type: .success)
                                                                    self.dismiss(animated: false, completion: {})
                                                                } else {
                                                                    //迁移过程中，禁止写入
                                                                    if code == ExplorerErrorCode.dataUpgradeLocked.rawValue {
                                                                        self.showToast(text: BundleI18n.SKResource.CreationMobile_DataUpgrade_Locked_toast, type: .failure)
                                                                        return
                                                                    }

                                                                    /// 判断是否有owner不在的群
                                                                    if let dict = json.dictionaryObject,
                                                                       let data = dict["data"] as? [String: Any] {
                                                                        let ownerNotInGroupStr = self.parseOwnerNotInGroupName(data: data)
                                                                        if !ownerNotInGroupStr.isEmpty {
                                                                            self.showToast(text: BundleI18n.SKResource.CreatinoMobile_Minutes_request_unable(typeString, ownerNotInGroupStr),
                                                                                           type: .failure)
                                                                            return
                                                                        }
                                                                    }
                                                                    let fromView = UIViewController.docs.topMost(of: self)?.view
                                                                    let utils = CollaboratorBlockStatusManager(requestType: .askOwner, fromView: fromView, statistics: self.statistics)
                                                                    utils.showAskOwnerFailedToast(json, ownerName: self.fileModel.displayName, isFolder: self.fileModel.isFolder)
                                                                }
                                                            })
    }

    
    /// 判断邀请的协作者中哪些是有owner不在的群，并返回群名称
    private func parseOwnerNotInGroupName(data: [String: Any]) -> String {
        // 根据后台fail_members字段中错误码"10027"，判断邀请的协作者中哪些是有owner不在的群
        let ownerNotInGroupCode = String(CollaboratorBlockStatusManager.ResponseCode.ownerNotInGroup.rawValue)
        if let failMembersDict = data["fail_members"] as? [String: Any],
           let failMembers = failMembersDict[ownerNotInGroupCode] as? [[String: Any]],
           !failMembers.isEmpty {
            var ownerNotInGroupStr = ""
            failMembers.forEach { (member) in
                if let userId = member["owner_id"] as? String,
                   let name = self.getCollaboratorName(with: userId) {
                    ownerNotInGroupStr += ownerNotInGroupStr.isEmpty ? "\(name)" : ",\(name)"
                }
            }
            return ownerNotInGroupStr
        }
        return ""
    }
    
    func getCollaboratorName(with userId: String) -> String? {
        let collaborator = items.first { $0.userID == userId }
        return collaborator?.name
    }
    
    //选择需要请求的权限
    private func selectRequestPermission() {
        guard let range = permissionTopTipView.attributeTitle?.string.range(of: requestPermission),
              let nsRange = permissionTopTipView.attributeTitle?.string.toNSRange(range) else { return }

        self.animation(isShow: false)
        let isRead = requestPermissionCode == .read

        var sourceRect = permissionTopTipView.frame
        sourceRect.origin.y -= sourceRect.size.height

        let source = UDActionSheetSource(sourceView: permissionTopTipView,
                                         sourceRect: sourceRect,
                                         arrowDirection: .up)
        actionsheet = UDActionSheet(config: UDActionSheetUIConfig(popSource: source, dismissedByTapOutside: { [weak self] in
            self?.isDismissed = false
            self?.animation(isShow: true)
        }))

        guard let sheet = actionsheet else { return }
        let userList: [[String: Any]] = Array(items).map {
            return ["object_uid": DocsTracker.encrypt(id: $0.userID),
                    "collaborate_type": $0.rawValue]
        }
        let scene: AskOwnerFromScene = (fromScene == .addCollaborator) ? .addCollaborator : .imCard
        let readAction = UDActionSheetItem(title: BundleI18n.SKResource.Doc_Facade_ReadPermission, titleColor: isRead ? UIColor.ud.colorfulBlue : nil) { [weak self] in
            guard let `self` = self else { return }
            self.animation(isShow: true)
            self.requestPermission = BundleI18n.SKResource.Doc_Facade_ReadPermission
            self.requestPermissionCode = .read
            self.permissionTipAttributeString?.replaceCharacters(in: nsRange, with: self.requestPermission)
            self.permissionTopTipView.attributeTitle = self.permissionTipAttributeString
            self.permStatistics?.reportPermissionAskOwnerTypeClick(click: .read,
                                                                   target: .noneTargetView,
                                                                   fromScene: scene,
                                                                   userList: userList)
        }
        let editAction = UDActionSheetItem(title: BundleI18n.SKResource.Doc_Facade_EditPermission, titleColor: isRead ? nil : UIColor.ud.colorfulBlue) { [weak self] in
            guard let `self` = self else { return }
            self.animation(isShow: true)
            self.requestPermission = BundleI18n.SKResource.Doc_Facade_EditPermission
            self.requestPermissionCode = .edit
            self.permissionTipAttributeString?.replaceCharacters(in: nsRange, with: self.requestPermission)
            self.permissionTopTipView.attributeTitle = self.permissionTipAttributeString
            self.permStatistics?.reportPermissionAskOwnerTypeClick(click: .edit,
                                                                   target: .noneTargetView,
                                                                   fromScene: scene,
                                                                   userList: userList)
        }

        sheet.addItem(readAction)
        sheet.addItem(editAction)

        sheet.setCancelItem(text: BundleI18n.SKResource.Doc_Facade_Cancel) {
            [weak self] in
            guard let `self` = self else { return }
            self.permStatistics?.reportPermissionAskOwnerTypeClick(click: .cancel,
                                                                   target: .noneTargetView,
                                                                   fromScene: scene,
                                                                   userList: userList)
        }
        present(sheet, animated: true, completion: nil)
    }
    // MARK: - UITableViewDataSource
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datas.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: CollaboratorSearchResultCell
        if let tempCell = (tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as? CollaboratorSearchResultCell) {
            cell = tempCell
        } else {
            cell = CollaboratorSearchResultCell(style: .subtitle, reuseIdentifier: cellReuseIdentifier)
        }
        guard indexPath.row >= 0, indexPath.row < datas.count else { return UITableViewCell() }
        cell.update(item: datas[indexPath.row])
        cell.backgroundColor = .clear
        return cell
    }
    // MARK: - UIGestureRecognizerDelegate
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchClass = NSStringFromClass((touch.view?.classForCoder)!)
        let supClass = NSStringFromClass((touch.view?.superview!.superview?.classForCoder)!)
        
        if touchClass.hasPrefix("UITableViewCell") || supClass.hasPrefix("UITableViewCell") {
            return false
        }
        return true
    }
    // MARK: - PermissionTopTipViewDelegate
    public func handleTitleLabelClicked(_ tipView: PermissionTopTipView, index: Int, range: NSRange) {
        if index == 1 {
            //跳转到权限选择alert
            requestMessage.endEditing(true)
            selectRequestPermission()
            let scene: AskOwnerFromScene = (fromScene == .addCollaborator) ? .addCollaborator : .imCard
            self.permStatistics?.reportPermissionAskOwnerTypeView(fromScene: scene)
        } else if index == 0 {
            //跳转到用户profile
            let params = ["type": fileModel.docsType.rawValue]
            HostAppBridge.shared.call(ShowUserProfileService(userId: fileModel.ownerID, fileName: self.fileModel.title, fromVC: self, params: params))
        }
    }

    //打开页面埋点上报
    func openAskOwnerPageStatistics() {
        var source = ""
        var module = ""
        if self.layoutConfig != nil {
            source = "add_external"
            module = FileListStatistics.module?.rawValue ?? FileListStatistics.Module.quickaccess.rawValue
        } else {
            source = "IM_card"
        }
        self.statistics?.openAskOwnerPageStatistics(
            source: source,
            module: module,
            fileType: fileModel.docsType.name,
            fileId: fileModel.objToken)
    }
    //发送请求埋点上报
    func askOwnerForInviteCollaboratorStatistics() {
        var source = ""
        var module = ""
        if self.layoutConfig != nil {
            source = "add_external"
            module = FileListStatistics.module?.rawValue ?? FileListStatistics.Module.quickaccess.rawValue
        } else {
            source = "IM_card"
        }
        self.statistics?.askOwnerForInviteCollaboratorStatistics(
            source: source,
            module: module,
            fileType: fileModel.docsType.name,
            fileId: fileModel.objToken)
    }

    ///页面隐藏显示动画
    private func animation(isShow: Bool) {
        guard modalPresentationStyle != .formSheet, !self.isDismissed else {
            if self.isDismissed {
                //actionSheet的dismiss会调用cancel item的action block，
                //在这个block里面会持有askownerVC，导致askownerVC没有deinit掉
                //因此需要在这里在调一次dismiss
                self.dismiss(animated: false)
            }
            return
        }
        if isShow {
            actionsheet = nil
            backgroundView.snp.updateConstraints { (make) in
                make.bottom.equalTo(currentHeight + bottomSafeAreaHeight)
            }
            self.view.layoutIfNeeded()
        }

        let alpha: CGFloat = isShow ? 0.5 : 0
        let bottom = isShow ? 0 : currentHeight + bottomSafeAreaHeight
        backgroundView.snp.updateConstraints { (make) in
            make.bottom.equalTo(bottom)
        }
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.5, options: [], animations: {
            self.dismissButton.alpha = alpha
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

extension AskOwnerForInviteCollaboratorViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = (self.view.window ?? self.view) else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}

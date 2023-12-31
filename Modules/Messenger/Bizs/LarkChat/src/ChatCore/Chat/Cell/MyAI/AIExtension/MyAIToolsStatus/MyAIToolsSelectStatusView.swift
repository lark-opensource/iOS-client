//
//  MyAIToolsSelectStatusView.swift
//  LarkIMMention
//
//  Created by ByteDance on 2023/6/1.
//

import UIKit
import Foundation
import FigmaKit
import UniverseDesignShadow
import UniverseDesignIcon
import UniverseDesignColor
import ByteWebImage
import LarkMessengerInterface
import LarkModel
import LKCommonsLogging
import RxSwift
import RxCocoa
import LarkContainer
import UniverseDesignToast
import LarkAIInfra

/// 选择状态类型
public enum MyAIToolsSelectStatusType {
    case unselected      // 未选择
    case selected // 已选择
}

public class MyAIToolsSelectStatusView: UIView, MyAIToolsSelectStatusInterface {
    static let logger = Logger.log(MyAIToolsSelectStatusView.self, category: "Module.LarkAI.MyAITool")
    public typealias TapToolAction = (([String]) -> Void)
    public typealias TapCloseToolAction = (() -> Void)
    public var tapToolAction: TapToolAction?
    public var tapCloseToolAction: TapCloseToolAction? {
        didSet {
            Self.logger.info("isAllowQuickClose: \(isAllowQuickClose)")
        }
    }
    public var aiChatModeID: Int64 = 0
    public var isSingleMode: Bool = true {
        didSet {
            let udIconKey: UDIconType = (self.isSingleMode && !toolIds.isEmpty) ? .closeSmallOutlined : .downOutlined
            guard udIconKey != self.currentIconKey else {
                Self.logger.info("not update udIcon")
                return
            }
            self.currentIconKey = udIconKey
            Self.logger.info("isSingleMode: \(isSingleMode) toolIds: \(toolIds)")
            let iconSize = self.isSingleMode ? CGSize(width: Cons.closeTagImageSize, height: Cons.closeTagImageSize) : CGSize(width: Cons.selectTagImageSize, height: Cons.selectTagImageSize)
            let image = UDIcon.getIconByKey(udIconKey, size: iconSize).ud.withTintColor(UIColor.ud.iconN2)
            selectTagButton.setImage(image, for: .normal)
        }
    }
    public var isAllowQuickClose: Bool {
        return (tapCloseToolAction != nil && !toolIds.isEmpty) ? true : false
    }

    private var currentIconKey: UDIconType?
    private var _tipLable: UILabel?
    private var _selectedToolsView: MyAIToolsAvatarListView?

    lazy var contentTapView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapView))
        view.addGestureRecognizer(tap)
        return view
    }()

    lazy var bgView: UIView = {
        let backGroudView = UIView()
        backGroudView.backgroundColor = UIColor.ud.bgFloat
        backGroudView.layer.cornerRadius = Cons.shadowViewHeight / 2.0
        backGroudView.layer.borderWidth = 0.5
        backGroudView.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent, bindTo: self)
        backGroudView.clipsToBounds = true
        return backGroudView
    }()

    lazy var shadowView: UIView = {
        let view = UIView()
        view.layer.ud.setShadowColor(UDShadowColorTheme.s3DownColor)
        view.layer.backgroundColor = UIColor.clear.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowRadius = 6
        view.layer.cornerRadius = 8
        view.clipsToBounds = false
        view.isUserInteractionEnabled = false
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        return view
    }()

    lazy var selectTagButton: UIButton = {
        let tagButton = UIButton(type: .custom)
        let image = UDIcon.getIconByKey(.downOutlined, size: CGSize(width: Cons.selectTagImageSize, height: Cons.selectTagImageSize)).ud.withTintColor(UIColor.ud.iconN3)
        tagButton.setImage(image, for: .normal)
        tagButton.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        tagButton.addTarget(self, action: #selector(selectTagAction), for: .touchUpInside)
        return tagButton
    }()

    var tipLable: UILabel {
        if _tipLable == nil {
            _tipLable = UILabel()
            _tipLable?.text = BundleI18n.AI.MyAI_IM_SelectPlugins_Button
            _tipLable?.textColor = UIColor.ud.textCaption
            _tipLable?.font = UIFont.ud.body2
        }
        guard let label = _tipLable else {
            return UILabel()
        }
        return label
    }

    lazy var crossLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    var selectedToolsView: MyAIToolsAvatarListView {
        if _selectedToolsView == nil {
            _selectedToolsView = MyAIToolsAvatarListView(setToolAvatarTasks: self.toolAvatarTasks)
        }
        guard let toolsView = _selectedToolsView else {
            return MyAIToolsAvatarListView(setToolAvatarTasks: [])
        }
        return toolsView
    }

    private lazy var loadingView: ByteImageView = {
        let imageView = ByteImageView()
        imageView.image = UDIcon.getIconByKey(.loadingOutlined,
                                              iconColor: UIColor.ud.primaryContentDefault,
                                              size: CGSize(width: Cons.closeTagImageSize, height: Cons.closeTagImageSize))
        imageView.isHidden = true
        return imageView
    }()

    private var tools: [MyAIToolInfo]
    private var toolIds: [String]
    private var toolAvatarTasks: [MyAIToolsAvatarListView.SetToolAvatarTask]
    private var toolsCount: Int

    private let userResolver: UserResolver
    private var myAIToolRustService: RustMyAIToolServiceAPI?
    private var myAIService: MyAIService? {
        try? self.userResolver.resolve(type: MyAIService.self)
    }
    private let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        self.tools = []
        self.toolAvatarTasks = []
        self.toolIds = []
        self.toolsCount = 0
        self.userResolver = Container.shared.getCurrentUserResolver()
        super.init(frame: frame)
        setupSubviews()
    }

    init(tools: [MyAIToolInfo],
         userResolver: UserResolver,
         toolTap: TapToolAction? = nil,
         toolCloseTap: TapCloseToolAction? = nil) {
        self.tools = tools
        self.toolAvatarTasks = tools.map { toolItem -> MyAIToolsAvatarListView.SetToolAvatarTask in
            let task: MyAIToolsAvatarListView.SetToolAvatarTask = { avatarView in
                avatarView.setAvatarByIdentifier(toolItem.toolId, avatarKey: toolItem.toolAvatar)
            }
            return task
        }
        self.toolIds = tools.map { $0.toolId }
        self.userResolver = userResolver
        self.tapToolAction = toolTap
        self.tapCloseToolAction = toolCloseTap
        self.toolsCount = toolIds.count
        self.myAIToolRustService = try? userResolver.resolve(assert: RustMyAIToolServiceAPI.self)
        super.init(frame: CGRect.zero)
        Self.logger.info(logId: "init myAIToolsSelectStatusView tools: \(toolIds)")
        setupSubviews()
    }

    init(toolIds: [String],
         userResolver: UserResolver,
         toolTap: TapToolAction? = nil,
         toolCloseTap: TapCloseToolAction? = nil) {
        self.toolIds = toolIds
        self.toolAvatarTasks = []
        self.tools = []
        self.userResolver = userResolver
        self.tapToolAction = toolTap
        self.tapCloseToolAction = toolCloseTap
        self.toolsCount = toolIds.count
        self.myAIToolRustService = try? userResolver.resolve(assert: RustMyAIToolServiceAPI.self)
        super.init(frame: CGRect.zero)
        Self.logger.info(logId: "init myAIToolsSelectStatusView toolIds: \(toolIds)")
        setupSubviews()
        loadToolsInfoByToolIds()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        backgroundColor = UIColor.clear
        addSubview(contentTapView)
        addSubview(shadowView)
        shadowView.addSubview(bgView)
        addSubview(crossLineView)
        addSubview(selectTagButton)
        addSubview(loadingView)
        shadowView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(Cons.shadowViewVMargin)
            make.left.equalToSuperview().offset(Cons.shadowViewHMargin)
            make.right.equalToSuperview().offset(-Cons.shadowViewHMargin)
            make.bottom.equalToSuperview().offset(-Cons.shadowViewVMargin)
            make.height.equalTo(Cons.shadowViewHeight)
        }
        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentTapView.snp.makeConstraints { make in
            make.edges.equalTo(bgView)
        }
        selectTagButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-Cons.contentViewLeftMargin)
            make.size.equalTo(CGSize(width: Cons.selectTagImageSize, height: Cons.selectTagImageSize))
        }
        loadingView.snp.makeConstraints { make in
            make.edges.equalTo(selectTagButton)
        }
        crossLineView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Cons.crossLineViewVMargin)
            make.right.equalTo(selectTagButton.snp.left).offset(-Cons.crossLineViewHMargin)
            make.bottom.equalToSuperview().offset(-Cons.crossLineViewVMargin)
            make.width.equalTo(Cons.crossLineViewWidth)
        }
        if self.toolsCount == 0 {
            unSelectedToolExhibition()
        } else {
            if !self.tools.isEmpty {
                selectedToolExhibition(avatarCount: self.toolsCount)
            }
        }
    }

    private func loadToolsInfoByToolIds() {
        guard !self.toolIds.isEmpty else {
            return
        }
        myAIToolRustService?.getMyAIToolsInfo(toolIds: self.toolIds)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (tools) in
                guard let self = self else { return }
                Self.logger.info("load selectedToolsInfo success toolsNum:\(tools.count)")
                self.tools = tools
                self.updateRenderTools()
            }, onError: { (error) in
                Self.logger.info("load selectedToolsInfo failure error: \(error)")
            }).disposed(by: self.disposeBag)
    }

    private func updateRenderTools() {
        self.resetContentLayout()
        self.toolAvatarTasks = self.tools.map { toolItem -> MyAIToolsAvatarListView.SetToolAvatarTask in
            let task: MyAIToolsAvatarListView.SetToolAvatarTask = { avatarView in
                let completion: (UIImage?, ImageRequestResult) -> Void = { [weak avatarView] (placeholder, result) in
                    guard let avatar = avatarView else { return }
                    switch result {
                    case .success(let imageResult):
                        guard let image = imageResult.image else { return }
                        avatar.image = image
                        avatar.backgroundColor = UIColor.clear
                    case .failure(let error):
                        if placeholder != nil { return }
                        avatar.image = placeholder
                        Self.logger.error("tool select status load avatar failed id=\(String(describing: toolItem.toolId))" +
                                                             "&key=\(String(describing: toolItem.toolAvatar))&error=\(error.localizedDescription)")
                    }
                }
                let placeholder: UIImage? = Resources.imageDownloadFailed
                avatarView.setAvatarByIdentifier(toolItem.toolId, avatarKey: toolItem.toolAvatar) { imageResult in
                    completion(placeholder, imageResult)
                }
            }
            return task
        }
        guard !self.tools.isEmpty else {
            return
        }
        selectedToolExhibition(avatarCount: self.tools.count)
//        self.selectedToolsView.update(setToolAvatarTasks: self.toolAvatarTasks, restCount: nil)
    }

    // MARK: - MyAIToolsSelectStatusInterface
    public func update(tools: [MyAIToolInfo]) {
        let newToolIds = tools.map { $0.toolId }
        Self.logger.info("update tools: \(newToolIds)")
        if self.toolIds == newToolIds {
            Self.logger.info("toolIds equal not update: oldToolIds: \(self.toolIds) newToolIds: \(toolIds)")
            return
        }
        resetData()
        resetContentLayout()
        if tools.isEmpty {
            unSelectedToolExhibition()
        } else {
            self.toolIds = newToolIds
            self.tools = tools
            self.toolsCount = tools.count
            self.toolAvatarTasks = tools.map { toolItem -> MyAIToolsAvatarListView.SetToolAvatarTask in
                let task: MyAIToolsAvatarListView.SetToolAvatarTask = { avatarView in
                    avatarView.setAvatarByIdentifier(toolItem.toolId, avatarKey: toolItem.toolAvatar)
                }
                return task
            }
//            self.selectedToolsView.update(setToolAvatarTasks: self.toolAvatarTasks, restCount: nil)
            selectedToolExhibition(avatarCount: tools.count)
        }
    }

    public func update(toolIds: [String]) {
        Self.logger.info("update toolIds: \(toolIds)")
        if self.toolIds == toolIds {
            Self.logger.info("toolIds equal not update: oldToolIds: \(self.toolIds) newToolIds: \(toolIds)")
            return
        }
        resetData()
        resetContentLayout()
        if toolIds.isEmpty {
            unSelectedToolExhibition()
        } else {
            self.toolIds = toolIds
            self.toolsCount = toolIds.count
            loadToolsInfoByToolIds()
        }
    }

    public func update(aiChatModeID: Int64, isSingleMode: Bool, tapCloseTool: TapCloseToolAction?) {
        Self.logger.info("update aiChatModeID:\(aiChatModeID) tapCloseTool")
        self.aiChatModeID = aiChatModeID
        self.isSingleMode = isSingleMode
        self.tapCloseToolAction = tapCloseTool
    }

    func close(complete: MyAIToolCloseComplete?) {
        startAnimating()
        myAIToolRustService?.sendMyAITools(toolIds: [], messageId: "", aiChatModeID: aiChatModeID, toolInfoList: [])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self, let window = self.window else { return }
                self.stopAnimating()
                Self.logger.info("set my ai tools success")
                self.clearToolCallBack()
                complete?()
                UDToast.showSuccess(with: BundleI18n.AI.MyAI_IM_Extension_ClearExtension_Toast, on: window)
            }, onError: { [weak self] (error) in
                guard let self = self, let window = self.window else { return }
                self.stopAnimating()
                Self.logger.info("set my ai tools failure error: \(error)")
                UDToast.showFailure(
                    with: BundleI18n.AI.Lark_Legacy_NetworkOrServiceError,
                    on: window,
                    error: error.transformToAPIError()
                )
            }).disposed(by: self.disposeBag)
    }

    func clearToolCallBack() {
        guard let aiService = self.myAIService else { return }
        let extensionCallBackInfo = MyAIExtensionCallBackInfo(extensionList: [], fromVc: nil)
        aiService.selectedExtension.accept(extensionCallBackInfo)
    }

    func startAnimating() {
        self.selectTagButton.isHidden = true
        self.loadingView.isHidden = false
        addRoateAnimation(self.loadingView)
    }

    func stopAnimating() {
        removeRotateAnimation(self.loadingView)
        self.selectTagButton.isHidden = false
        self.loadingView.isHidden = true
    }

    private func addRoateAnimation(_ view: UIView) {
        guard view.layer.animation(forKey: "rotate") == nil else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.duration = 0.8
        animation.fillMode = .forwards
        animation.repeatCount = .infinity
        animation.values = [0, Double.pi * 2]
        animation.keyTimes = [NSNumber(value: 0.0), NSNumber(value: 1.0)]
        animation.isRemovedOnCompletion = false
        view.layer.add(animation, forKey: "rotate")
    }

    @inline(__always)
    private func removeRotateAnimation(_ view: UIView) {
        view.layer.removeAllAnimations()
    }

    func resetData() {
        self.tools = []
        self.toolAvatarTasks = []
        self.toolIds = []
        self.toolsCount = 0
    }

    func resetContentLayout() {
        self.tipLable.snp.removeConstraints()
        self.tipLable.removeFromSuperview()
        _tipLable = nil
        self.selectedToolsView.snp.removeConstraints()
        self.selectedToolsView.removeFromSuperview()
        _selectedToolsView = nil
    }

    private func selectedToolExhibition(avatarCount: Int) {
        addSubview(self.selectedToolsView)
        let selectedToolsViewSize = MyAIToolsAvatarListView.sizeToFit(avatarCount: avatarCount)
        Self.logger.info(logId: "selectedToolExhibition toolIds:\(self.toolIds) selectedToolsViewSize:\(selectedToolsViewSize.width)")
        selectedToolsView.snp.remakeConstraints { make in
            make.right.equalTo(crossLineView.snp.left).offset(-Cons.selectedToolViewRightMargin)
            make.left.equalToSuperview().offset(Cons.selectedToolViewLeftMargin)
            make.centerY.equalToSuperview()
            make.width.equalTo(selectedToolsViewSize)
        }
    }

    private func unSelectedToolExhibition() {
        addSubview(self.tipLable)
        Self.logger.info(logId: "unSelectedToolExhibition")
        tipLable.sizeToFit()
        let tipLableWidth = tipLable.bounds.size.width
        tipLable.snp.remakeConstraints { make in
            make.right.equalTo(crossLineView.snp.left).offset(-Cons.tipLableRightMargin)
            make.left.equalToSuperview().offset(Cons.contentViewLeftMargin)
            make.centerY.equalToSuperview()
            make.width.equalTo(tipLableWidth)
        }
    }

    @objc
    func tapView() {
        Self.logger.info("did click tap tools:\(toolIds)")
        if !isAllowQuickClose {
            // 显示关闭入口X时，点击不弹出插件选择面板
            tapToolAction?(self.toolIds)
        }
    }

    @objc
    func selectTagAction() {
        Self.logger.info("did click button tools:\(toolIds)")
        if isAllowQuickClose {
            close { [weak self] in
                guard let self = self else { return }
                self.tapCloseToolAction?()
            }
        } else {
            tapToolAction?(self.toolIds)
        }
    }

    public func sizeToFit(toolCount: Int) -> CGSize {
        return Self.sizeToFit(toolCount: toolCount)
    }

    public static func sizeToFit(toolCount: Int) -> CGSize {
        Self.logger.info("sizeToFit toolCount:\(toolCount)")
        if toolCount <= 0 {
            let tipSize = NSString(string: BundleI18n.AI.MyAI_IM_SelectPlugins_Button)
                .boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: 20),
                              options: [.usesLineFragmentOrigin],
                              attributes: [.font: UIFont.ud.body2],
                              context: nil)
            let leftWidth = Cons.contentViewLeftMargin + tipSize.width + Cons.tipLableRightMargin
            let rightWidth = Cons.crossLineViewHMargin + Cons.selectTagImageSize + Cons.contentViewLeftMargin
            let width = leftWidth + Cons.crossLineViewWidth + rightWidth + Cons.supplementWidth
            let height = Cons.shadowViewHeight + Cons.shadowViewVMargin * 2
            return CGSize(width: width, height: height)
        } else {
            let selectedToolsViewSize = MyAIToolsAvatarListView.sizeToFit(avatarCount: toolCount)
            let leftWidth = Cons.selectedToolViewLeftMargin + selectedToolsViewSize.width + Cons.selectedToolViewRightMargin
            let rightWidth = Cons.crossLineViewHMargin + Cons.selectTagImageSize + Cons.contentViewLeftMargin
            let width = leftWidth + Cons.crossLineViewWidth + rightWidth + Cons.supplementWidth
            let height = Cons.shadowViewHeight + Cons.shadowViewVMargin * 2
            return CGSize(width: width, height: height)
        }
    }

    deinit {
        print("MyAIToolsSelectStatusView deinit")
    }
}

extension MyAIToolsSelectStatusView {
    enum Cons {
        static var selectViewUpdateAnimateTime: TimeInterval { 0.2 }
        static var bgViewBlurRadius: CGFloat { 25 }
        static var selectTagImageSize: Double { 16.auto() }
        static var closeTagImageSize: Double { 18.auto() }
        static var shadowViewHeight: CGFloat { 32.auto() }
        static var contentViewLeftMargin: CGFloat { 20 }
        static var selectedToolViewLeftMargin: CGFloat { 14 }
        static var tipLableRightMargin: CGFloat { 10 }
        static var selectedToolViewRightMargin: CGFloat { 8 }
        static var crossLineViewVMargin: CGFloat { 10 }
        static var crossLineViewHMargin: CGFloat { 8 }
        static var crossLineViewWidth: CGFloat { 1 }
        static var shadowViewHMargin: CGFloat { 8 }
        static var shadowViewVMargin: CGFloat { 4 }
        static var supplementWidth: CGFloat { 1 }
    }
}

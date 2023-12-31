//
//  GroupNoticeTemplatePreviewVC.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/6/19.
//  


import SKUIKit
import RxSwift
import SKResource
import Lottie
import UniverseDesignColor
import UniverseDesignToast
import SKFoundation
import SpaceInterface
import SKInfra

/// 群公告模版预览
public final class GroupNoticeTemplatePreviewVC: TemplatesPreviewViewController {
    public struct GroupNoticeParams {
        public let objType: Int
        public let objToken: String
        public let baseRev: Int
        public let extra: String

        public init(objType: Int,
                    objToken: String,
                    baseRev: Int = 0,
                    extra: String = "") {
            self.objType = objType
            self.objToken = objToken
            self.baseRev = baseRev
            self.extra = extra
        }
    }
    
    public var didUseTemplate: ((TemplateModel) -> Void)?
    private static let bottomViewContentHeight: CGFloat = 139
    private let templates: [TemplateModel]
    private let bottomView = GroupNoticeTemplatePreviewBottomView()
    private let disposeBag = DisposeBag()
    private var currentIndex: UInt
    private let groupNoticeDocsParams: GroupNoticeParams
    private let dataRequester = TemplateDataProvider()

    private lazy var defaultLoadingView: DocsLoadingViewProtocol = {
        DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)!
    }()
    
    public init?(templates: [TemplateModel], currentIndex: UInt, groupNoticeDocsParams: GroupNoticeParams) {
        guard !templates.isEmpty else {
            return nil
        }
        self.templates = templates
        self.currentIndex = min(UInt(templates.count - 1), currentIndex)
        self.groupNoticeDocsParams = groupNoticeDocsParams
        super.init(nibName: nil, bundle: nil)
        self.bottomOffset = Self.bottomViewContentHeight
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        selectIndex(currentIndex)
    }
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        bottomOffset = Self.bottomViewContentHeight + view.safeAreaInsets.bottom
        bottomView.snp.updateConstraints { (make) in
            make.leading.bottom.trailing.equalTo(view)
            make.height.equalTo(bottomOffset)
        }
    }
    
    override func queryParamsAppendToURL() -> [String: String] {
        var params = super.queryParamsAppendToURL()
        params["template_preview_source"] = "announce"
        return params
    }
    
    private func setupUI() {
        title = BundleI18n.SKResource.CreationMobile_Operation_TemplatePreview
        if SKDisplay.pad {
            navigationBar.leadingBarButtonItems = [closeButtonItem]
        }
        
        view.addSubview(bottomView)
        bottomView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(bottomOffset)
        }
        
        bottomView.previousControl.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                guard self.currentIndex > 0 else { return }
                self.currentIndex -= 1
                self.selectIndex(self.currentIndex)
            })
            .disposed(by: disposeBag)
        bottomView.nextControl.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                guard self.currentIndex < self.templates.count - 1 else { return }
                self.currentIndex += 1
                self.selectIndex(self.currentIndex)
            })
            .disposed(by: disposeBag)
        bottomView.useButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.useTemplate(self.templates[Int(self.currentIndex)])
            })
            .disposed(by: disposeBag)
        
        view.addSubview(defaultLoadingView.displayContent)
        defaultLoadingView.displayContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    private func selectIndex(_ index: UInt) {
        bottomView.previousEnabled = index != 0
        bottomView.nextEnabled = index != templates.count - 1
        let template = templates[Int(index)]
        bottomView.titleLabel.text = template.displayTitle
        bottomView.iconImageView.image = template.docsType.imageForCreate
        self.openTemplate(template)
        TemplateCenterTracker.clickTemplatePreview(from: .announcement)
    }
    private func useTemplate(_ template: TemplateModel) {
        showLoading(isShow: true)
        dataRequester.insertTemplate(template.objToken,
                                     toDocs: groupNoticeDocsParams.objToken,
                                     docsType: groupNoticeDocsParams.objType,
                                     baseRev: groupNoticeDocsParams.baseRev,
                                     extra: groupNoticeDocsParams.extra)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] result in
                self?.showLoading(isShow: false)
                guard result else {
                    return
                }
                if let didUse = self?.didUseTemplate {
                    didUse(template)
                    let params = ["action": "use_template",
                                  "source": "from_im_chat_announcement"]
                    DocsTracker.log(enumEvent: .toggleAttribute,
                                    parameters: params)
                }
                if self?.presentingViewController != nil {
                    self?.dismiss(animated: true, completion: nil)
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
            }, onError: {[weak self] _ in
                self?.showLoading(isShow: false)
            })
            .disposed(by: disposeBag)
    }
    private func showLoading(isShow: Bool) {
        view.bringSubviewToFront(defaultLoadingView.displayContent)
        defaultLoadingView.displayContent.isHidden = !isShow
        if isShow {
            defaultLoadingView.startAnimation()
        } else {
            defaultLoadingView.stopAnimation()
        }
    }
}

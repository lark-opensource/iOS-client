//
//  GroupNoticeTemplateSuggestView.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/6/22.
//  

import SKFoundation
import SKUIKit
import UniverseDesignColor
import SKResource
import RxSwift
import Lottie
import UniverseDesignEmpty
import SpaceInterface
import SKInfra

public protocol GroupNoticeTemplateSuggestViewDelegate: NSObject {
    func templateSuggestViewDidClickHideButton(suggestView: GroupNoticeTemplateSuggestView)
    func templateSuggestViewDidClickTemplate(suggestView: GroupNoticeTemplateSuggestView, atIndex: Int)
}

public final class GroupNoticeTemplateSuggestView: UIView {
    public weak var delegate: GroupNoticeTemplateSuggestViewDelegate?
    public private(set) var templates: [TemplateModel] = []
    private let objToken: String
    private let dataProvider = TemplateDataProvider()
    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 128, height: 117)
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 14
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(GroupNoticeTemplatePreviewCell.self, forCellWithReuseIdentifier: "CellId")
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()
    private let tipLabel: UILabel = UILabel().construct { it in
        it.textColor = UDColor.N500
        it.font = UIFont(name: "PingFangSC-Regular", size: 14)
        it.text = BundleI18n.SKResource.CreationMobile_Operation_SelectTemplateforGroupNotice
    }
    private let hideButton: UIButton = UIButton(type: .custom).construct { it in
        it.setTitle(BundleI18n.SKResource.CreationMobile_Operation_HideGroupTemplate, for: .normal)
        it.setTitleColor(UDColor.textLinkNormal, for: .normal)
        it.titleLabel?.font = UIFont(name: "PingFangSC-Regular", size: 14)
    }
    private let loadingView: DocsLoadingViewProtocol = {
        DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)!
    }()
    private lazy var failedView: UIView = {
        let config = UDEmptyConfig(spaceBelowImage: 0, type: .loadingFailure)
        let empty = UDEmpty(config: config)
        let view = UIView()
        view.backgroundColor = .clear
        view.addSubview(empty)
        empty.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(loadData))
        view.addGestureRecognizer(tap)
        return view
    }()
    private let disposeBag = DisposeBag()
    
    public init(objToken: String) {
        self.objToken = objToken
        super.init(frame: .zero)
        setupSubviews()
        loadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        backgroundColor = .clear
        
        addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(22)
        }
        
        addSubview(hideButton)
        hideButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.height.equalTo(22)
            make.width.equalTo(58)
        }
        hideButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self, let delegate = self.delegate else { return }
                delegate.templateSuggestViewDidClickHideButton(suggestView: self)
                let params = ["action": "hidden_template",
                              "source": "from_im_chat_announcement"]
                DocsTracker.log(enumEvent: .toggleAttribute, parameters: params)
            })
            .disposed(by: disposeBag)
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(22)
            make.height.equalTo(141)
        }
        
        addSubview(loadingView.displayContent)
        loadingView.displayContent.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.top.equalTo(tipLabel.snp.bottom)
        }
        
        addSubview(failedView)
        failedView.snp.makeConstraints { (make) in
            make.edges.equalTo(loadingView.displayContent)
        }
    }
    
    @objc
    private func loadData() {
        failedView.isHidden = true
        loadingView.displayContent.isHidden = false
        loadingView.startAnimation()
        dataProvider.fetchGroupNoticeRecommendTemplates(objToken: objToken)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] templates in
                self?.loadingView.displayContent.isHidden = true
                self?.loadingView.stopAnimation()
                self?.failedView.isHidden = !templates.isEmpty
                self?.templates = templates
                self?.collectionView.reloadData()
            }, onError: { [weak self] _ in
                self?.failedView.isHidden = false
                self?.loadingView.displayContent.isHidden = true
                self?.loadingView.stopAnimation()
            })
            .disposed(by: disposeBag)
    }
}

extension GroupNoticeTemplateSuggestView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return templates.count
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellId", for: indexPath) as? GroupNoticeTemplatePreviewCell else {
            fatalError("Invalid Cell,Must be GroupNoticeTemplatePreviewCell")
        }
        let template = templates[indexPath.item]
        cell.configCell(with: template, hostViewWidth: self.frame.width)
        cell.needSelectedBorder = false
        TemplateCenterTracker.reportShowSingleTemplateTracker(template, from: .announcement)
        return cell
    }
}

extension GroupNoticeTemplateSuggestView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.templateSuggestViewDidClickTemplate(suggestView: self, atIndex: indexPath.item)
    }
}

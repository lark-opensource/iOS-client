//
//  TemplateSuggestionView.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/7/9.
//  

import UIKit
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import Lottie
import RxSwift
import SpaceInterface
import SKInfra

protocol TemplateSuggestionViewDelegate: AnyObject {
    func didClickMoreButtonOfTemplateSuggestionView(templateSuggestionView: TemplateSuggestionView)
    func templateSuggestionView(templateSuggestionView: TemplateSuggestionView, didClick template: TemplateModel)
}

public final class TemplateSuggestionView: UIControl {
    weak var delegate: TemplateSuggestionViewDelegate?
    public var grayBgViewHeight: CGFloat {
        return 45
    }
    public var collectionViewHeight: CGFloat {
        if SKDisplay.pad { return collectionViewHeightForIPad }
        return 143
    }

    public var collectionViewHeightForIPad: CGFloat {
        return 143
    }
    private(set) lazy var grayBgView = UIView()
    private lazy var templateLabel = UILabel()
    private lazy var moreLabel = UILabel()
    private lazy var moreContentView = UIView()
    private lazy var triangleImageView = UIImageView()
    private lazy var failedView = TemplateSpecialViewProvider.makeFailViewForSuggestion()
    
    private let disposeBag = DisposeBag()

    private lazy var noNetworkView: UIView = {
        let networkView = TemplateSpecialViewProvider.makeNoNetForSuggestion()
        networkView.isHidden = true
        return networkView
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let padding: CGFloat = 16

        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: padding, right: 16)
        layout.minimumLineSpacing = 20
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        return cv
    }()
    private lazy var defaultLoadingView: DocsLoadingViewProtocol = {
        DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)!
    }()

    private(set) var templateDataSource = [TemplateModel]() {
        didSet {
            self.collectionView.reloadData()
        }
    }

    var isNetworkReachable: Bool {
        return DocsNetStateMonitor.shared.isReachable
    }

    private let bag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefaultValue()
        setupSubviews()
    }

    private func setupDefaultValue() {
        collectionView.register(TemplateSuggestCell.self, forCellWithReuseIdentifier: TemplateSuggestCell.reuseIdentifier)


        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        grayBgView.backgroundColor = UDColor.bgBody
        templateLabel.text = BundleI18n.SKResource.Doc_LIst_TemplateTitle
        templateLabel.font = UIFont.docs.createDefaultFont(size: 14)
        templateLabel.textColor = UDColor.textTitle
        moreLabel.text = BundleI18n.SKResource.Doc_Create_MoreTemplate
        moreLabel.textColor = UDColor.primaryContentDefault
        moreLabel.font = UIFont.docs.createDefaultFont(size: 12)
        triangleImageView.image = UDIcon.rightSmallCcmOutlined.ud.withTintColor(UDColor.primaryContentDefault)
        self.backgroundColor = UDColor.bgBody
        moreContentView.docs.addStandardHighlight()
        let tap = UITapGestureRecognizer(target: self, action: #selector(moreButtonAction))
        moreContentView.addGestureRecognizer(tap)
    }
    private func setupSubviews() {
        self.addSubview(grayBgView)
        grayBgView.addSubview(templateLabel)
        grayBgView.addSubview(moreContentView)
        self.addSubview(collectionView)
        self.addSubview(defaultLoadingView.displayContent)
        self.addSubview(failedView)
        self.addSubview(noNetworkView)
        failedView.isHidden = true

        moreContentView.addSubview(moreLabel)
        moreContentView.addSubview(triangleImageView)
        setupSubviewConstraints()
    }

    private func setupSubviewConstraints() {
        let leftOffset = 16

        grayBgView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(grayBgViewHeight)
            make.bottom.equalTo(collectionView.snp.top)
        }

        templateLabel.snp.makeConstraints { (make) in
            make.left.equalTo(leftOffset)
            make.height.equalTo(20)
            make.top.equalToSuperview().offset(leftOffset - 2)
        }

        moreContentView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-leftOffset)
            make.height.equalTo(18)
            make.centerY.equalTo(templateLabel)
        }

        moreLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalTo(triangleImageView.snp.left).offset(-2)
            make.centerY.equalTo(moreContentView)
        }

        triangleImageView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.centerY.equalTo(moreContentView)
            make.width.height.equalTo(16)
        }

        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(grayBgView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(collectionViewHeight)
            make.bottom.equalToSuperview()
        }
        defaultLoadingView.displayContent.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(collectionView.snp.top)
            make.height.equalTo(3)// topSpaceView的存在导致Lottie view被挤到下面。topSpaceView的高度为superview的1/3，故这里把superview的高度设置得比较小，让topSpaceView的高度接近0
        }
        failedView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(collectionView.snp.top)
        }

        noNetworkView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(collectionView.snp.top).offset(-6)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func moreButtonAction() {
        delegate?.didClickMoreButtonOfTemplateSuggestionView(templateSuggestionView: self)
    }

    func startLoading() {
        hideFailedView()
        defaultLoadingView.displayContent.isHidden = false
        defaultLoadingView.startAnimation()
    }

    func endLoading() {
        hideFailedView()
        defaultLoadingView.displayContent.isHidden = true
        defaultLoadingView.stopAnimation()
    }

    func updateData(_ templates: [TemplateModel]) {
        templateDataSource = templates
        collectionView.reloadData()
        if templates.isEmpty {
            showFailedView()
        } else {
            hideFailedView()
        }
    }

    func showFailedView() {
        self.bringSubviewToFront(failedView)
        failedView.isHidden = false
    }
    
    func showNoNetView() {
        self.bringSubviewToFront(noNetworkView)
        noNetworkView.isHidden = false
        failedView.isHidden = true
    }

    func reloadData() {
        collectionView.reloadData()
    }
    
    private func hideFailedView() {
        failedView.isHidden = true
        noNetworkView.isHidden = true
    }
}

extension TemplateSuggestionView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.templateDataSource.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let template = templateDataSource[indexPath.item]
        return getCell(
            collectionView,
            indexPath: indexPath,
            template: template,
            delegate: nil,
            hostViewWidth: collectionView.frame.width
        )
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let template = templateDataSource[indexPath.item]
        return TemplateCellLayoutInfo.suggest(with: TemplateCellLayoutInfo.baseScreenWidth)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < self.templateDataSource.count else {
            DocsLogger.error("did click template out of range \(indexPath)")
            return
        }
        let template = self.templateDataSource[indexPath.item]
        notifyDelegateDidClickCellForTemplate(template)
    }
    
    private func getCell(
        _ collectionView: UICollectionView,
        indexPath: IndexPath,
        template: TemplateModel,
        delegate: TemplateBaseCellDelegate?,
        hostViewWidth: CGFloat
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TemplateSuggestCell.reuseIdentifier, for: indexPath)
        guard let templateCell = cell as? TemplateSuggestCell else {
            return cell
        }
        templateCell.configCell(with: template, hostViewWidth: hostViewWidth)
        templateCell.delegate = delegate
        templateCell.resetNetStatus(isreachable: DocsNetStateMonitor.shared.isReachable)
        TemplateCenterTracker.reportShowSingleTemplateTracker(template)
        return templateCell
    }
    
    func notifyDelegateDidClickCellForTemplate(_ template: TemplateModel) {
        delegate?.templateSuggestionView(templateSuggestionView: self, didClick: template)
    }
}

extension TemplateSuggestionView {
    public var onboardingFrame: CGRect {
        CGRect(x: 0,
               y: grayBgViewHeight,
               width: frame.width,
               height: collectionViewHeight)
    }
}

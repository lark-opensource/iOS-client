//
//  TemplatePreviewBottomView.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/5/28.
//  


import SKFoundation
import UniverseDesignColor
import RxSwift
import RxCocoa
import SKResource

class TemplatePreviewBottomView: UIView {
    let templates = PublishSubject<[TemplateModel]>()
    private let disposeBag = DisposeBag()
    
    let titleLabel: UILabel = {
        let lb = UILabel()
        lb.textColor = UDColor.textTitle
        lb.font = UIFont.docs.pfsc(14)
        lb.lineBreakMode = .byTruncatingMiddle
        return lb
    }()
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 102, height: 96)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        layout.minimumLineSpacing = 12
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = UDColor.bgBody
        cv.register(TemplatePreviewCell.self, forCellWithReuseIdentifier: "\(TemplatePreviewCell.self)")
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()
    private lazy var titleContainerView: UIView = {
        let view = UIView()
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.trailing.top.bottom.equalTo(view)
        }
        return view
    }()
    private let line: UIView = {
        let line = UIView()
        line.backgroundColor = UDColor.lineDividerDefault
        return line
    }()
    let button: UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 6
        btn.layer.masksToBounds = true
        btn.setBackgroundColor(UDColor.primaryContentDefault, for: .normal)
        btn.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        btn.titleLabel?.font = UIFont.docs.pfsc(17)
        btn.setTitle(BundleI18n.SKResource.CreationMobile_Operation_ApplyTemplateSolution, for: .normal)
        return btn
    }()
    
    // MARK: - Life cycle
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        bind()
    }
    
    private func setupSubviews() {
        backgroundColor = UDColor.bgBody
        layer.ud.setShadowColor(UDColor.shadowDefaultSm)
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowOpacity = 1
        layer.shadowRadius = 6
        
        addSubview(titleContainerView)
        titleContainerView.snp.makeConstraints { (make) in
            make.top.equalTo(self).offset(16)
            make.leading.equalTo(self).offset(15)
            make.trailing.equalTo(self)
            make.height.equalTo(20)
        }
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(titleContainerView.snp.bottom).offset(0)
            make.height.equalTo(120)
        }
        
        addSubview(line)
        line.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(self)
            make.height.equalTo(0.5)
            make.top.equalTo(collectionView.snp.bottom).offset(7)
        }
        
        addSubview(button)
        button.snp.makeConstraints { (make) in
            make.leading.equalTo(self).offset(16)
            make.trailing.equalTo(self).offset(-16)
            make.top.equalTo(line.snp.bottom).offset(16)
            make.height.equalTo(46)
        }
        
        
    }

    private func bind() {
        templates.bind(to: collectionView.rx.items(cellIdentifier: "\(TemplatePreviewCell.self)", cellType: TemplatePreviewCell.self)) { [weak self] (_, template, cell) in
            guard let self = self else { return }
            cell.configCell(with: template, hostViewWidth: self.collectionView.frame.width)
            TemplateCenterTracker.reportShowSingleTemplateTracker(template, from: .preview)
        }.disposed(by: disposeBag)
    }
    
}

extension Reactive where Base: TemplatePreviewBottomView {
    var title: Binder<String> {
        return Binder(base) { (target, value) in
            target.button.setTitle(value, for: .normal)
        }
    }
}

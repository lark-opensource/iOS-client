//
//  BitableLoadingView.swift
//  SKSpace
//
//  Created by qiyongka on 2023/11/8.
//

import Foundation
import SkeletonView
import UniverseDesignColor


fileprivate final class SkeletonView: UIView {
    
    init() {
        super.init(frame: .zero)
        self.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let loadingLayer = layer.sublayers?.first(where: {
            $0.isKind(of: CAGradientLayer.self)
        }) {
            adjustLoadingLayer(loadingLayer)
        }
    }
    
    func adjustLoadingLayer(_ layer: CALayer) {
        layer.frame = bounds
    }
}

final class BitableListCellLoadingView: UITableViewCell {
    
    struct Const {
        static let iconViewSice: CGFloat = 36.0
        static let iconCornerRadius: CGFloat = 8.0
        
        static let titleCornerRadius: CGFloat = 4.0
        
        static let titleHeight: CGFloat = 14.0
        static let titleWidth: CGFloat = 279.0
        
        static let subTitleHeight: CGFloat = 10.0
        static let subTitleWidth: CGFloat = 72.0
    }
    
    static var reuseID: String = "BitableListCellLoadingView"
    
    private lazy var iconView: SkeletonView = {
        let view = SkeletonView()
        view.layer.cornerRadius = Const.iconCornerRadius
        view.isSkeletonable = true
        return view
    }()
    
    private lazy var titleView: SkeletonView = {
        let view = SkeletonView()
        view.layer.cornerRadius = Const.titleCornerRadius
        view.isSkeletonable = true
        return view
    }()

    private lazy var subTitleView: SkeletonView = {
        let view = SkeletonView()
        view.layer.cornerRadius = Const.titleCornerRadius
        view.isSkeletonable = true
        return view
    }()
    
    lazy var skeletonGradient = SkeletonGradient(baseColor: UIColor.ud.N900.withAlphaComponent(0.05), secondaryColor: UIColor.ud.N900.withAlphaComponent(0.1))
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.backgroundColor = UIColor.clear
        self.contentView.backgroundColor = UIColor.clear
        self.contentView.addSubview(iconView)
        self.contentView.addSubview(titleView)
        self.contentView.addSubview(subTitleView)
        
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            
            make.width.height.equalTo(Const.iconViewSice)
        }
        
        titleView.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.left).offset(44)
            make.top.equalTo(iconView.snp.top).offset(3)
            
            make.height.equalTo(Const.titleHeight)
            make.width.equalTo(Const.titleWidth)
        }
        
        subTitleView.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.left).offset(44)
            make.bottom.equalTo(iconView.snp.bottom).inset(3)
            
            make.height.equalTo(Const.subTitleHeight)
            make.width.equalTo(Const.subTitleWidth)
        }
        contentView.showAnimatedGradientSkeleton(usingGradient: self.skeletonGradient)
    }
}

final class BitableListLoadingView: UIView, UITableViewDelegate, UITableViewDataSource {
    
    private let loadingCellNumbers: Int = 5
    
    var shouldShowLoadingAnimation: Bool = false
    
    lazy var tableView = UITableView(frame: .zero).construct { it in
        it.register(BitableListCellLoadingView.self, forCellReuseIdentifier: BitableListCellLoadingView.reuseID)
        it.backgroundColor = UIColor.clear
        it.delegate = self
        it.dataSource = self
        it.isScrollEnabled = false
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        tableView.separatorStyle = .none
        setSubViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    func setSubViews() {
        isUserInteractionEnabled = false
        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    /// TableView Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return loadingCellNumbers
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
        
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BitableListCellLoadingView.reuseID, for: indexPath)
        if shouldShowLoadingAnimation {
            cell.contentView.startSkeletonAnimation()
        } else {
            cell.contentView.stopSkeletonAnimation()
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func startLoading() {
        shouldShowLoadingAnimation = true
        tableView.reloadData()
    }
    
    func stopLoading() {
        shouldShowLoadingAnimation = false
        tableView.reloadData()
    }
}


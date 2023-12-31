//
//  HomeLoadingViewCell.swift
//  SKSpace
//
//  Created by majie.7 on 2023/5/26.
//

import Foundation


public class HomeLoadingViewCell: UICollectionViewCell {
    private lazy var loadingView = HomeLoadingSkeletonView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        loadingView.showLoading()
    }
}

class HomeLoadingSkeletonView: UIView {
    private lazy var titleSkeleton = LoadingSkeletonView()
    private lazy var topView = SkeletonItemView()
    private lazy var middleView = SkeletonItemView()
    private lazy var bottomView = SkeletonItemView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(titleSkeleton)
        addSubview(topView)
        addSubview(middleView)
        addSubview(bottomView)
        
        titleSkeleton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(9)
            make.left.equalToSuperview().offset(24)
            make.height.equalTo(14)
            make.width.equalTo(45)
        }
        
        topView.snp.makeConstraints { make in
            make.top.equalTo(titleSkeleton.snp.bottom).offset(26)
            make.left.right.equalToSuperview()
            make.height.equalTo(18)
        }
        
        middleView.snp.makeConstraints { make in
            make.top.equalTo(topView.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(18)
        }
        
        bottomView.snp.makeConstraints { make in
            make.top.equalTo(middleView.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(18)
        }
    }
    
    func showLoading() {
        titleSkeleton.playAnimation()
        [topView, middleView, bottomView].forEach { view in
            view.showLoading()
        }
    }
}


class SkeletonItemView: UIView {
    
    private lazy var leftView = LoadingSkeletonView()
    private lazy var rightView = LoadingSkeletonView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(leftView)
        addSubview(rightView)
        
        leftView.layer.cornerRadius = 9
        leftView.layer.masksToBounds = true
        leftView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(24)
            make.width.height.equalTo(18)
        }
        
        rightView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(leftView.snp.right).offset(8)
            make.height.equalTo(14)
            make.right.equalToSuperview().inset(86)
        }
    }
    
    func showLoading() {
        leftView.playAnimation()
        rightView.playAnimation()
    }
}

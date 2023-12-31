//
//  BTCardLoadingView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/10/10.
//

import Foundation
import UniverseDesignColor
import SKFoundation
import SkeletonView

protocol BTCardLoadingViewDelegate: AnyObject {
    func didClickClose()
}

final class BTCardLoadingView: UIView {
    
    struct Const {
        static let smallCornerRadius: CGFloat = 6.0
        static let topLineHeight: CGFloat = 20.0
        static let blockHeight: CGFloat = 27.0
        static let blockWidth: CGFloat = 40.0
        static let leftMargin: CGFloat = 16.0
        static let rightMargin: CGFloat = 16.0
        static let topStackMargin: CGFloat = 12.0
        static let topStackSpacing: CGFloat = 16.0
        static let topStackHeight: CGFloat = 56.0
        static let blockStackHeight: CGFloat = 40.0
        static let blockStackMargin: CGFloat = 28.0
        static let blockStackSpacing: CGFloat = 24.0
        static let normalStackMargin: CGFloat = 12.0
        static let normalItemStackSpacing: CGFloat = 32.0
        static let normalItemViewHeight: CGFloat = 16.0
        static let normalItemStackHieght: CGFloat = 60.0
    }
    
    private lazy var headerView = BTRecordHeaderView().construct { it in
        it.backgroundColor = UserScopeNoChangeFG.ZJ.btCardReform ? .clear : UDColor.bgBody
        it.onlyShowClose()
        it.delegate = self
    }
    
    private lazy var topStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = Const.topStackSpacing
        stackView.isSkeletonable = true
        return stackView
    }()
    
    private lazy var blockStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.spacing = Const.blockStackSpacing
        stackView.isSkeletonable = true
        return stackView
    }()
    
    private var normalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 0
        stackView.isSkeletonable = true
        return stackView
    }()
    
    weak var delegate: BTCardLoadingViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createNormalView(cornerRadius: CGFloat) -> BTSkeletonView {
        let view = BTSkeletonView()
        view.layer.cornerRadius = cornerRadius
        view.isSkeletonable = true
        return view
    }
    
    private func createBlockView() -> BTSkeletonView {
        let view = BTSkeletonView()
        view.layer.cornerRadius = Const.smallCornerRadius
        view.isSkeletonable = true
        return view
    }
    
    private func createNoramlStackItemView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.isSkeletonable = true
        stackView.spacing = Const.normalItemStackSpacing
        let cornerRadius = Const.normalItemViewHeight / 2.0
        let firstView = createNormalView(cornerRadius: cornerRadius)
        let secondView = createNormalView(cornerRadius: cornerRadius)
        stackView.addArrangedSubview(firstView)
        stackView.addArrangedSubview(secondView)
        firstView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.height.equalTo(Const.normalItemViewHeight)
            make.width.equalTo(80)
        }
        secondView.snp.makeConstraints { make in
            make.height.equalTo(Const.normalItemViewHeight)
            make.right.equalToSuperview()
        }
        return stackView
    }
    
    private func setup() {
        backgroundColor = UDColor.bgBody    // 设置一个背景色防止底下内容提前透出
        addSubview(headerView)
        addSubview(topStackView)
        addSubview(blockStackView)
        addSubview(normalStackView)
        headerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        topStackView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(Const.topStackMargin)
            make.left.equalToSuperview().inset(Const.leftMargin)
            make.right.equalToSuperview().inset(Const.rightMargin)
            make.height.equalTo(Const.topStackHeight)
        }
        blockStackView.snp.makeConstraints { make in
            make.top.equalTo(topStackView.snp.bottom).offset(Const.blockStackMargin)
            make.left.equalToSuperview().inset(Const.leftMargin)
            make.right.lessThanOrEqualToSuperview().inset(Const.rightMargin)
            make.height.equalTo(Const.blockHeight)
        }
        normalStackView.snp.makeConstraints { make in
            make.top.equalTo(blockStackView.snp.bottom).offset(Const.normalStackMargin)
            make.left.equalToSuperview().inset(Const.leftMargin)
            make.right.equalToSuperview().inset(Const.rightMargin)
            make.bottom.lessThanOrEqualToSuperview()
        }
        setupTopStackView()
        setupBlockStackView()
        setupNormalStackView()
    }
    
    private func setupTopStackView() {
        let cornerRadius = Const.topLineHeight / 2.0
        let topLine = createNormalView(cornerRadius: cornerRadius)
        let secondLine = createNormalView(cornerRadius: cornerRadius)
        topStackView.addArrangedSubview(topLine)
        topStackView.addArrangedSubview(secondLine)
        topLine.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(Const.topLineHeight)
        }
        secondLine.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.33)
            make.height.equalTo(Const.topLineHeight)
        }
    }
    
    private func setupBlockStackView() {
        // 添加三个
        for _ in 0...2 {
            let block = createBlockView()
            blockStackView.addArrangedSubview(block)
            block.snp.makeConstraints { make in
                make.width.equalTo(Const.blockWidth)
                make.height.equalTo(Const.blockHeight)
            }
        }
    }
    
    private func setupNormalStackView() {
        for _ in 0...5 {
            let item = createNoramlStackItemView()
            normalStackView.addArrangedSubview(item)
            item.snp.makeConstraints { make in
                make.height.equalTo(Const.normalItemStackHieght)
                make.left.equalToSuperview()
                make.right.equalToSuperview()
            }
        }
    }
}

extension BTCardLoadingView: BTRecordHeaderViewDelegate {
    func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        
    }
    
    func didClickHeaderButton(action: BTActionFromUser) {
        delegate?.didClickClose()
    }
    
    func didTapTitle(withAttributes attributes: [NSAttributedString.Key : Any]) {
        
    }
    
    func didClickMoreButton(sourceView: UIView) {
        
    }
    
    func didClickCloseNoticeButton() {
        
    }
    
    func didClickShareButton(sourceView: UIView) {
        
    }
    
    func recordHeaderViewDidClickAddCover(view: BTRecordHeaderView, sourceView: UIView) {
        
    }
    
    func recordSubscribeViewDidClick(isSubscribe: Bool, completion: @escaping (BTRecordSubscribeCode) -> Void) {
        
    }
    
    
}

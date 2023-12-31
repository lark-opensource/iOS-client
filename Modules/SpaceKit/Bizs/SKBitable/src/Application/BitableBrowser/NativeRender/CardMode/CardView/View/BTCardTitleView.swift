//
//  BTCardTitleView.swift
//  SKBitable
//
//  Created by zoujie on 2023/10/31.

import Foundation
import SkeletonView
import UniverseDesignColor
import SnapKit

protocol BTCardTitleViewDelegate: AnyObject {
    func didClickComment(params: [String: Any])
}

struct BTCardCommentConst {
    static let commentFontSize = 12.0
    static let textInset = UIEdgeInsets(top: 1,
                                        left: 4,
                                        bottom: 1,
                                        right: 4)
    static let leftInset: CGFloat = 4.0
}

final class BTCardTitleView: UICollectionViewCell {
    private var comment: SimpleItem?
    private lazy var loadingView = BTSkeletonView().construct { it in
        it.layer.cornerRadius = 7
    }
    private var valueView: BTCellValueViewProtocol?
    private var model: BTCardFieldCellModel?
    private var isShowLoading = false
    private let emptyView = BTCardEmptyValueView()
    private var titleValueHasCommentConstraint: SnapKit.ConstraintMakerEditable?
    private var titleValueConstraint: SnapKit.ConstraintMakerEditable?
    
    weak var delegate: BTCardTitleViewDelegate?
    
    private lazy var commentView = UIButton().construct { it in
        it.layer.cornerRadius = 2
        it.isHidden = true
        it.backgroundColor = UDColor.colorfulYellow
        it.hitTestEdgeInsets = UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)
        it.setContentCompressionResistancePriority(.required, for: .horizontal)
        it.setContentHuggingPriority(.required, for: .horizontal)
        it.addTarget(self, action: #selector(didClickComment), for: .touchUpInside)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(loadingView)
        contentView.addSubview(commentView)
        contentView.addSubview(emptyView)
        
        loadingView.snp.makeConstraints { make in
            make.left.width.equalToSuperview()
            make.height.equalTo(14)
        }
        
        commentView.snp.makeConstraints { make in
            make.height.equalTo(14)
            make.width.greaterThanOrEqualTo(18)
            make.width.lessThanOrEqualTo(24)
            make.top.equalToSuperview().offset(5)
            make.right.equalToSuperview()
        }
        emptyView.snp.makeConstraints { make in
            make.left.bottom.top.equalToSuperview()
            make.right.lessThanOrEqualTo(commentView.snp.left).offset(-4)
        }
    }
    
    private func updateUI(isSubtitle: Bool = false) {
        if let commentData = comment {
            commentView.isHidden = false
            commentView.contentEdgeInsets = BTCardCommentConst.textInset
            commentView.setTitle(commentData.text,
                                 withFontSize: BTCardCommentConst.commentFontSize,
                                 fontWeight: .medium,
                                 color: UDColor.staticWhite, forState: .normal)
            commentView.sizeToFit()
            self.layoutIfNeeded()
        } else {
            commentView.isHidden = true
            commentView.contentEdgeInsets = .zero
            commentView.setTitle(nil, for: .normal)
            commentView.sizeToFit()
        }
        
        let loadingViewHeight = isSubtitle ? 12 : 14
        let widthMultip = isSubtitle ? 0.4 : 0.72
        loadingView.snp.remakeConstraints { make in
            make.width.equalToSuperview().multipliedBy(widthMultip)
            make.left.centerY.equalToSuperview()
            make.height.equalTo(loadingViewHeight)
        }
    }
    
    private func updateHighlight(with model: BTCardFieldCellModel?) {
        if let colorString = model?.highlightColor {
            let color = UIColor.docs.rgb(colorString)
            self.backgroundColor = color
        } else {
            self.backgroundColor = .clear
        }
        if let colorString = model?.borderHighlightColor {
            let color = UIColor.docs.rgb(colorString)
            self.layer.borderColor = color.cgColor
            self.layer.borderWidth = 2.0
        } else {
            self.layer.borderColor = UIColor.clear.cgColor
            self.layer.borderWidth = 0
        }
    }
    
    func updateModel(_ model: BTCardFieldCellModel?, 
                     comment: SimpleItem?,
                     containerWidth: CGFloat,
                     isSubtitle: Bool = false) {
        self.comment = comment
        updateUI(isSubtitle: isSubtitle)
        updateHighlight(with: model)
        let hasComment = comment != nil
        if let model = model {
            emptyView.isHidden = true
            hideLoading()
            let valueWidth = containerWidth - commentView.intrinsicContentSize.width - BTCardCommentConst.leftInset
            func rebuildValueView() {
                let valueView = BTNativeRenderViewManager.createTitleValueView(model: model, containerWidth: valueWidth, isMainTitle: !isSubtitle)
                self.valueView?.removeFromSuperview()
                self.valueView = valueView
                contentView.addSubview(valueView)
                valueView.snp.remakeConstraints({ make in
                    make.left.bottom.top.equalToSuperview()
                    titleValueHasCommentConstraint = make.right.equalTo(commentView.snp.left).offset(-BTCardCommentConst.leftInset)
                    titleValueConstraint = make.right.equalToSuperview()
                })
                valueView.isUserInteractionEnabled = false
            }
            if model.isEmpty {
                // 是empty
                emptyView.isHidden = false
                self.valueView?.isHidden = true
                if self.model?.fieldUIType != model.fieldUIType {
                    // 类型发生变化，置空valueView，下次数据更新重新构建
                    self.valueView = nil
                }
            } else {
                if self.model?.fieldUIType != model.fieldUIType || self.valueView == nil || self.valueView is BTCardEmptyValueView {
                    // 字段类型发生变化，或者valueView没有
                    rebuildValueView()
                } else {
                    // 字段类型没发生变化，这里只更新数据
                    if let view = self.valueView as? BTTextCellValueViewProtocol {
                        if isSubtitle {
                            view.setData(model, containerWidth: containerWidth)
                        } else {
                            // 现在只有富文本字段处理了 numberOfLines
                            view.set(model,
                                     with: CardViewConstant.LayoutConfig.textTtileFont,
                                     numberOfLines: 2)
                        }
                    } else {
                        self.valueView?.setData(model, containerWidth: valueWidth)
                    }
                }
                titleValueHasCommentConstraint?.constraint.isActive = hasComment
                titleValueConstraint?.constraint.isActive = !hasComment
                self.valueView?.isHidden = false
                self.emptyView.isHidden = true
            }
            
        } else {
            showLoading()
            self.valueView?.isHidden = true
        }
        self.model = model
    }
    
    private func showLoading() {
        guard !isShowLoading else {
            return
        }
        
        isShowLoading = true
        let skeletonGradient = SkeletonGradient(baseColor: UIColor.ud.N900.withAlphaComponent(0.05), secondaryColor: UIColor.ud.N900.withAlphaComponent(0.1))
        loadingView.isSkeletonable = true
        loadingView.showAnimatedGradientSkeleton(usingGradient: skeletonGradient)
        loadingView.startSkeletonAnimation()
    }
    
    private func hideLoading() {
        guard isShowLoading else {
            return
        }
        loadingView.hideSkeleton()
    }
    
    @objc
    private func didClickComment() {
        guard let params = comment?.clickActionPayload as? [String: Any] else {
            return
        }
        
        delegate?.didClickComment(params: params)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == commentView ? view : nil
    }
}

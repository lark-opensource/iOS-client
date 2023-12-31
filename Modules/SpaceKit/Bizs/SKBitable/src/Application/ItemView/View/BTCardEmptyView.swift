//
//  BTCardEmptyView.swift
//  SKBitable
//
//  Created by zhysan on 2023/11/8.
//

import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignEmpty
import SKResource

enum BTCardEmptyState {
    case none
    
    /// 记录将被静默添加
    case recordWillBeAddedSilently
    
    /// 记录添加成功后无权限查看
    case recordAddSuccessButNoViewPerm
    
    /// 数据表不存在
    case tableNotExist
    
    /// 没有添加权限
    case noRecordAddPerm
    
    /// 记录添加成功后未返回记录 token
    case recordAddSuccessButNoShareToken
}

private extension BTCardEmptyState {
    var isHidden: Bool {
        self == .none
    }
}

private extension BTCardEmptyState {
    var description: String {
        switch self {
        case .none:
            return ""
        case .recordWillBeAddedSilently:
            return BundleI18n.SKResource.Bitable_QuickAdd_SubmitTrafficCongestion_Desc
        case .recordAddSuccessButNoViewPerm:
            return BundleI18n.SKResource.Bitable_QuickAdd_SubmittedCannotAccess_Toast
        case .tableNotExist:
            return BundleI18n.SKResource.Bitable_QuickAdd_TableDeleted_Toast
        case .noRecordAddPerm:
            return BundleI18n.SKResource.Bitable_QuickAdd_NoRecordAccess_Desc
        case .recordAddSuccessButNoShareToken:
            return BundleI18n.SKResource.Bitable_QuickAdd_SubmittedNoRedirect_Desc
        }
    }
    
    var type: UDEmptyType {
        switch self {
        case .none:
            return .initial
        case .recordWillBeAddedSilently:
            return .ccmPositiveStorageLimit
        case .recordAddSuccessButNoViewPerm:
            return .done
        case .tableNotExist:
            return .noContent
        case .noRecordAddPerm:
            return .noAccess
        case .recordAddSuccessButNoShareToken:
            return .done
        }
    }
    
    var primaryBtnTitle: String? {
        switch self {
        case .none:
            return nil
        case .recordWillBeAddedSilently, .recordAddSuccessButNoViewPerm, .recordAddSuccessButNoShareToken:
            return BundleI18n.SKResource.Bitable_QuickAdd_NewRecord_Option
        case .tableNotExist:
            return nil
        case .noRecordAddPerm:
            return nil
        }
    }
    
    var secondaryBtnTitle: String? {
        switch self {
        case .none:
            return nil
        case .recordWillBeAddedSilently, .recordAddSuccessButNoViewPerm, .recordAddSuccessButNoShareToken:
            return BundleI18n.SKResource.Bitable_ShareSingleRecord_ViewTable_Button
        case .tableNotExist:
            return nil
        case .noRecordAddPerm:
            return nil
        }
    }
}

protocol BTCardEmptyViewDelegate: AnyObject {
    func onEmptyPrimaryButtonClick(_ sender: BTCardEmptyView)
    func onEmptySecondaryButtonClick(_ sender: BTCardEmptyView)
    func onEmptyBackButtonClick(_ sender: BTCardEmptyView)
}

final class BTCardEmptyView: UIView {
    // MARK: - public
    
    var state: BTCardEmptyState = .none {
        didSet {
            updateEmpty()
        }
    }
    
    weak var delegate: BTCardEmptyViewDelegate?
    
    func updateStateAfterDelay(state: BTCardEmptyState, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.state = state
        }
    }
    
    // MARK: - life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backBtn.frame = CGRect(
            x: self.safeAreaInsets.left + 12,
            y: self.safeAreaInsets.top + 16,
            width: 24,
            height: 24
        )
    }
    
    // MARK: - private
    
    private let udEmpty: UDEmpty = UDEmpty(config: .init(type: .initial))
    
    private let backBtn: UIButton = {
        let vi = UIButton(type: .custom)
        vi.setImage(UDIcon.leftOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        return vi
    }()
    
    private func updateEmpty() {
        // 1. 处理隐藏状态
        isHidden = state.isHidden
        
        // 2. 更新 empty 样式
        let config: UDEmptyConfig
        
        let primaryBtnHandler: (String, (UIButton) -> Void)?
        if let title = state.primaryBtnTitle, !title.isEmpty {
            primaryBtnHandler = (title, { [weak self] sender in
                self?.onEmptyPrimaryButtonClick(sender)
            })
        } else {
            primaryBtnHandler = nil
        }
        
        let secondaryBtnHandler: (String, (UIButton) -> Void)?
        if let title = state.secondaryBtnTitle, !title.isEmpty {
            secondaryBtnHandler = (title, { [weak self] sender in
                self?.onEmptySecondaryButtonClick(sender)
            })
        } else {
            secondaryBtnHandler = nil
        }
        
        config = UDEmptyConfig(
            description: .init(descriptionText: state.description),
            type: state.type,
            primaryButtonConfig: primaryBtnHandler,
            secondaryButtonConfig: secondaryBtnHandler
        )
        
        udEmpty.update(config: config)
    }
    
    private func onEmptyPrimaryButtonClick(_ sender: UIButton) {
        self.delegate?.onEmptyPrimaryButtonClick(self)
    }
    
    private func onEmptySecondaryButtonClick(_ sender: UIButton) {
        self.delegate?.onEmptySecondaryButtonClick(self)
    }
    
    @objc
    private func onEmptyBackButtonClick(_ sender: UIButton) {
        self.delegate?.onEmptyBackButtonClick(self)
    }
    
    private func subviewsInit() {
        backgroundColor = UDColor.bgBody
        addSubview(udEmpty)
        udEmpty.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }
        
        addSubview(backBtn)
        backBtn.addTarget(self, action: #selector(onEmptyBackButtonClick(_:)), for: .touchUpInside)
        
        updateEmpty()
    }
}

//
//  BTGroupHeaderFixedView.swift
//  SKBitable
//
//  Created by zoujie on 2023/11/1.
//

import SKFoundation

final class BTGroupHeaderFixedView: UIView {
    private let TAG = "[BTGroupHeaderFixedView]"
    var onClick: ((String) -> Void)?
    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        return view
    }()
    
    private var items: [RenderItem] =  []
    private var dataMap: [String: GroupModel] = [:]
    private var showHeaderIds: [String] = []
    private var lastTopOffset: CGFloat = 0
    
    var currentFixedHeaderId: String?
    var currentFixedHeaderIndex: Int? {
        showHeaderIds.firstIndex(where: { $0 == currentFixedHeaderId })
    }
    
    init() {
        super.init(frame: .zero)
        clipsToBounds = true
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 重置header数据
    /// - Parameters:
    ///   - items: 渲染结构
    ///   - dataMap: group数据
    func resetModel(items: [RenderItem], dataMap: [String: GroupModel], fixedId: String? = nil) {
        self.items = items
        self.dataMap = dataMap
        updateShowHeaderIds()
        stackView.removeAllArrangedSubviews()
        items.forEach { group in
            if let groupData = dataMap[group.id],
               groupData.lastLevelGroup {
                //最后一级分组需要处理吸顶
                let headerView = BTCardGroupHeaderView()
                headerView.updateModel(model: groupData, cardSetting: nil)
                headerView.onClick = { [weak self] id in
                    self?.onClick?(id)
                }
                stackView.addArrangedSubview(headerView)
                headerView.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.height.equalTo(CardViewConstant.LayoutConfig.groupHeaderHeight)
                }
            }
        }
        
        if currentFixedHeaderId == nil {
            currentFixedHeaderId = showHeaderIds.first
        }
        
        // 更新锁定的ID
        if let id = fixedId, showHeaderIds.contains(id) {
            currentFixedHeaderId = id
            fixOffset()
        }
    }
    
    /// 更新header数据
    /// - Parameters:
    ///   - dataMap: group数据
    func updateItemsModel(_ dataMap: [String: GroupModel]) {
        self.dataMap = dataMap
        updateShowHeaderIds()
        stackView.arrangedSubviews.forEach { view in
            if let groupHeaderView = view as? BTCardGroupHeaderView,
               let id = groupHeaderView.id {
                groupHeaderView.updateModel(model: dataMap[id], cardSetting: nil)
            }
        }
    }
    
    private func updateShowHeaderIds() {
        showHeaderIds.removeAll()
        items.forEach { group in
            if let groupData = dataMap[group.id],
               groupData.lastLevelGroup {
                showHeaderIds.append(groupData.id)
            }
        }
    }
    
    /// 是否有上一个固定的header
    /// - Returns: 有/没有
    func hasPreFixHeaderView() -> Bool {
        guard let currentFixedHeaderIndex = currentFixedHeaderIndex,
              currentFixedHeaderIndex != 0  else {
            return false
        }
        
        return true
    }
    
    /// 下一个固定的header的Id
    func getNextFixId() -> String? {
        guard let currentFixedHeaderIndex = currentFixedHeaderIndex,
              currentFixedHeaderIndex + 1 < showHeaderIds.count else {
            return nil
        }
        
        return showHeaderIds[currentFixedHeaderIndex + 1]
    }
    
    /// header完成取消固定
    func hasDoneCancleFixed() {
        guard hasPreFixHeaderView(),
              let currentFixedHeaderIndex = currentFixedHeaderIndex else {
            return
        }
        
        let preIndex = max(currentFixedHeaderIndex - 1, 0)
        guard currentFixedHeaderId != showHeaderIds[preIndex] else {
            return
        }
        
        // 切换到上一个ID
        currentFixedHeaderId = showHeaderIds[preIndex]
        fixOffset()
    }
    
    /// header完成固定
    func hasDoneFixed() {
        fixOffset()
    }
    
    /// 切换到当前固定的下一个
    func switchToNext() {
        guard let nextFixedId = getNextFixId() else {
            return
        }
        // 切换到下一个ID
        currentFixedHeaderId = nextFixedId
        fixOffset()
    }
    
    /// 校验需要设置的fixedHeaderId是否合法，当前列表内容在向上滚动，则fixedHeaderId不应该在currentFixedHeaderId之前
    /// 反之，当前列表内容在向下滚动，则fixedHeaderId不应该在currentFixedHeaderId之后
    /// 若无滚动方向则直接设置即可
    /// - Parameter scrollDirection: 内容滚动方向，大于0向上，小于0向下
    /// - Returns: 要设置的fixedHeaderId是否合法
    private func checkFixedHeaderId(id: String, scrollDirection: CGFloat?) -> Bool {
        guard let direction = scrollDirection else {
            return true
        }
        
        guard let index = showHeaderIds.firstIndex(of: id) else {
            return false
        }
        
        guard let currentFixedHeaderIndex = currentFixedHeaderIndex else {
            // 当前无fixedID，需要更新
            return true
        }
        
        if direction > 0 {
            // 向上
            return index >= currentFixedHeaderIndex
        } else {
            // 向下
            return index <= currentFixedHeaderIndex
        }
    }
    
    /// 更新当前固定的header
    /// - Parameter id: 需要固定的header id
    func updateFixHeaderView(id: String, scrollDirection: CGFloat? = nil) {
        guard checkFixedHeaderId(id: id, scrollDirection: scrollDirection) else {
            return
        }
        currentFixedHeaderId = id
        fixOffset()
        DocsLogger.btInfo("\(TAG) updateFixHeaderView id:\(id)")
    }
    
    private func getLastTargetOffset() -> CGFloat {
        let currentIndex = currentFixedHeaderIndex ?? 0
        return -CGFloat(currentIndex) * CardViewConstant.LayoutConfig.groupHeaderHeight
    }
    
    /// 根据偏移量更新fixed id
    private func updateCurrentFixedHeaderId() {
        let currentIndex = currentFixedHeaderIndex ?? 0
        let lastTargetOffset = getLastTargetOffset()
        
        let indexOffset = Int((lastTargetOffset - lastTopOffset) / CardViewConstant.LayoutConfig.groupHeaderHeight)
         let newIndex = currentIndex + indexOffset
        
        guard newIndex >= 0, newIndex < showHeaderIds.count else {
            return
        }
        
        currentFixedHeaderId = showHeaderIds[newIndex]
    }
    
    /// 修正偏移
    func fixOffset() {
        let targetOffset = getLastTargetOffset()
        guard lastTopOffset != targetOffset else {
            return
        }

        stackView.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(targetOffset)
        }
    }
    
    /// 更新偏移
    /// - Parameter offset: 偏移
    func updateOffset(_ offset: CGFloat) {
        guard stackView.bounds.height > 0 else {
            return
        }
        
        lastTopOffset = getLastTargetOffset() + offset
        let maxOffset = stackView.bounds.height - CardViewConstant.LayoutConfig.groupHeaderHeight
        
        lastTopOffset = max(min(lastTopOffset, 0), -maxOffset)
        DocsLogger.btInfo("\(TAG) updateOffset currentFixedHeaderIndex:\(currentFixedHeaderIndex) offset:\(offset)")
        stackView.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(lastTopOffset)
        }
        
        updateCurrentFixedHeaderId()
    }
}

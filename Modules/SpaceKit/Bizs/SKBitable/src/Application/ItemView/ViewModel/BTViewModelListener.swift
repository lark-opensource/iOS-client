//
//  BTViewModelListener.swift
//  DocsSDK
//
//  Created by Webster on 2020/5/18.
//

protocol BTViewModelListener: AnyObject {

    /// 跟前端请求数据失败
    func didFailRequestingValue()

    /// 打开卡片时前端请求数据异常
    func didRequestingValueErrorWhenOpenCard(_ error: Error?)

    /// 跟前端请求meta失败
    func didFailRequestingMeta()

    /// 第一次 model 已拉到
    func didLoadInitial(model: BTTableModel)

    /// model 发生了变化
    func didUpdateModel(model: BTTableModel)

    /// meta 发生了变化
    func didUpdateMeta(meta: BTTableMeta)
    /// bitable数据是否加载完
    func bitableReady()

    /// 前端请求关闭卡片模式
    func jsRequestCloseCard(newAction: BTCardActionTask)
    
    /// 前端请求隐藏/显示当前的卡片（如果当前正在显示卡片）
    func jsRequestCardHidden(newAction: BTCardActionTask, isHidden: Bool)

    /// 当前提交表单 有必填字段未填写时 滚动到合适位置
    @available(*, deprecated, message: "currentCardScrollToField(with fieldId:scrollPosition:) instead")
    func currentCardScrollToField(at indexPath: IndexPath, scrollPosition: UICollectionView.ScrollPosition)
    
    /// 当前提交表单 或者阶段字段流转 有必填字段未填写时 滚动到合适位置，上层别管UI层啊，让UI层自己根据数据进行处理
    func currentCardScrollToField(with fieldId: String, scrollPosition: UICollectionView.ScrollPosition)

    /// 前端控制，滚动到指定card
    func scrollToDesignatedCard(animated: Bool, completion: (() -> Void)?)

    /// 前端控制，滚动到card指定field
    func notifyScrollToCardField(fieldID: String)
    
    /// 当前卡片打开的前提下，前端再次打开卡片，触发数据更新后需要通知进行滚动，且通知卡片打开。
    func notifyRefreshDataByShowCard()
}

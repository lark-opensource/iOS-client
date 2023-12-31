//
//  InlineAIItemPromptView.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/4/26.
//  


import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon
import LarkExtensions
import RxSwift
import RxCocoa

class PromptCell: UITableViewCell {
    
    var promptLabel = UILabel()
    var iconView = UIImageView()
    var arrowView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectedBackgroundView = UIView()
        selectedBackgroundView?.layer.cornerRadius = 8
        selectedBackgroundView?.clipsToBounds = true
        selectedBackgroundView?.backgroundColor = UDColor.fillHover
        setupSubview()
        setupLayout()
    }
    struct Layout {
        static let iconSize = CGSize(width: 16, height: 16)
        static let iconLeftMargin: CGFloat = 12
        static let titleLeftMargin: CGFloat = 10
        static let arrowRightMargin: CGFloat = 16
    }

    func setupSubview() {
        contentView.addSubview(iconView)
        
        promptLabel.font = UIFont.systemFont(ofSize: 16)
        promptLabel.lineBreakMode = .byTruncatingTail
        promptLabel.numberOfLines = 1
        promptLabel.textColor = UDColor.textTitle
        contentView.addSubview(promptLabel)
        
        let icon = UDIcon.getIconByKey(.rightOutlined, size: Layout.iconSize)
        arrowView.image = icon.ud.withTintColor(UDColor.iconN2)
        contentView.addSubview(arrowView)
    }
    
    func setupLayout() {
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Layout.iconLeftMargin)
            make.centerY.equalToSuperview()
            make.size.equalTo(Layout.iconSize)
        }
        promptLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(Layout.titleLeftMargin)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        arrowView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(Layout.arrowRightMargin)
            make.size.equalTo(Layout.iconSize)
            make.centerY.equalToSuperview()
        }
    }
    
    func update(attributedText: NSAttributedString, showArrow: Bool, image: UIImage? = nil) {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        let attrText = NSMutableAttributedString(attributedString: attributedText)
        attrText.addAttributes([.paragraphStyle : style])
        promptLabel.attributedText = attrText
        arrowView.isHidden = !showArrow
        iconView.image = image?.ud.withTintColor(UDColor.iconN2)
        if image == nil {
            promptLabel.snp.remakeConstraints { make in
                make.left.equalTo(iconView.snp.left).offset(0)
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().inset(4)
            }
        } else {
            promptLabel.snp.remakeConstraints { make in
                make.left.equalTo(iconView.snp.right).offset(Layout.titleLeftMargin)
                make.right.equalToSuperview().inset(4)
                make.centerY.equalToSuperview()
            }
        }
        promptLabel.lineBreakMode = .byTruncatingTail
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PromptHeaderView: UITableViewHeaderFooterView {
    
    var titleLabel = UILabel()
    
    struct Metric {
        static var font = UIFont.systemFont(ofSize: 16)
        static var horizontalMargin: CGFloat = 14
    }
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .clear
        backgroundColor = .clear
        titleLabel.font = Metric.font
        titleLabel.textColor = UDColor.textCaption
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Metric.horizontalMargin)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(4)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class InlineAIItemPromptView: InlineAIItemBaseView {

    struct Metric {
        static let rowHeight: CGFloat = 40
        static let sectionHeaderHeight: CGFloat = 26
        static let sectionFooterHeight: CGFloat = 8
        static let bottomInset: CGFloat = 8
        static let groupHeaderTopMargin: CGFloat = 8
    }
    
    var groupModels: [InlineAIPanelModel.PromptGroups] = []
    
    let bottomLine = UIView()

    var promptTextColor: UIColor?

    weak var gestureDelegate: InlineAIViewPanGestureDelegate?
    
    var sectionHeights: [Int: CGFloat] = [:]
    
    var panGesture: UIPanGestureRecognizer?
    
    let disposeBag = DisposeBag()

    lazy var tableView: UITableView = {
        let tView = UITableView(frame: .zero, style: .grouped)
        tView.rowHeight = Metric.rowHeight
        tView.delegate = self
        tView.dataSource = self
        tView.showsVerticalScrollIndicator = false
        tView.separatorStyle = .none
        tView.contentInsetAdjustmentBehavior = .never
        tView.contentInset = .zero
        if #available(iOS 15.0, *) {
            tView.sectionHeaderTopPadding = 0
        }
        tView.backgroundColor = UDColor.bgFloat
        tView.register(PromptCell.self, forCellReuseIdentifier: "PromptCell")
        tView.register(PromptHeaderView.self, forHeaderFooterViewReuseIdentifier: "PromptHeaderView")
        tView.estimatedSectionHeaderHeight = Metric.sectionHeaderHeight
        tView.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: 1, height: 0.01))
        return tView
    }()
    
    private lazy var bottomGradientShadow: InlineAIGradientView = {
       let gradientView = InlineAIGradientView(direction: .vertical, colors: [UDColor.bgFloat.withAlphaComponent(0.00),UDColor.bgFloat.withAlphaComponent(1)])
       gradientView.isUserInteractionEnabled = false
       return gradientView
    }()
    
    private lazy var bottomGradientMaskView: UIView = {
       let maskView = UIView()
        maskView.backgroundColor = .clear
       return maskView
    }()
    
    private lazy var topGradientShadow: UIView = {
        let view = UIView()
        let layer = CAGradientLayer()
        layer.position = view.center
        layer.bounds = view.bounds
        view.layer.addSublayer(layer)
        layer.ud.setColors([
            UDColor.bgFloat.withAlphaComponent(1),
            UDColor.bgFloat.withAlphaComponent(0.00)
        ])
        layer.locations = [0, 1]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1.0)
        layer.needsDisplayOnBoundsChange = true
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupInit() {
        addSubview(tableView)
        addSubview(topGradientShadow)
        addSubview(bottomGradientShadow)
        addSubview(bottomGradientMaskView)
        addSubview(bottomLine)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(gesture:)))
        panGesture.delegate = self
        tableView.addGestureRecognizer(panGesture)
        self.panGesture = panGesture

        bottomGradientShadow.rx
                            .isHiddenBeSet
                            .bind(to: bottomGradientMaskView.rx.isHidden)
                            .disposed(by: disposeBag)

    }
    
    func setupLayout() {
        tableView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(Metric.bottomInset)
            make.left.right.equalToSuperview()
        }

        bottomLine.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        topGradientShadow.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(20)
        }

        bottomGradientShadow.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(60)
        }
        
        bottomGradientMaskView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(bottomGradientShadow)
            make.height.equalTo(20)
        }
    }
    
    var isIncreaseReload = false
    
    func update(groups: InlineAIPanelModel.Prompts?, withoutAnimation: Bool = true) {
        let preCount = self.groupModels.count
        self.groupModels = groups?.data ?? []
        if preCount == 0, self.groupModels.count > 0 {
            isIncreaseReload = true
        } else {
            isIncreaseReload = false
        }
        if withoutAnimation {
            UIView.performWithoutAnimation {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.tableView.reloadData()
                self.tableView.layoutIfNeeded()
                CATransaction.commit()
            }
        } else {
            self.tableView.reloadData()
        }
        
        let isGroupHeaderAlone = (self.groupModels.count == 1 && self.groupModels.first?.prompts.count == 0)
        self.panGesture?.isEnabled = !isGroupHeaderAlone
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self else { return }
            if isGroupHeaderAlone {
                self.topGradientShadow.isHidden = true
                self.bottomGradientShadow.isHidden = true
                self.tableView.isScrollEnabled = false
            } else {
                self.tableView.isScrollEnabled = true
                let maxOffset = self.tableView.contentSize.height - self.tableView.frame.height
                let current = self.tableView.contentOffset.y + 2
                self.bottomGradientShadow.isHidden = current >= maxOffset
            }
        }
        tableView.snp.updateConstraints { make in
            make.top.equalToSuperview().inset(isGroupHeaderAlone ? Metric.groupHeaderTopMargin : 0)
        }
    }
    
    private func caculateHeaderHeight() {
        guard self.frame.size.width > 0 else {
            return
        }
        for (idx, groupModel) in groupModels.enumerated() {
            let title = groupModel.title ?? ""
            sectionHeights[idx] = caculateContentHeight(title)
        }
    }
    
    private func caculateContentHeight(_ title: String) -> CGFloat {
        let contentW = self.bounds.width - PromptHeaderView.Metric.horizontalMargin * 2
        var height: CGFloat = 0.01
        if !title.isEmpty {
            height = title.boundingRect(with: CGSize(width: contentW, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: PromptHeaderView.Metric.font], context: nil).size.height + 6
            height = max(Metric.sectionHeaderHeight, height)
        }
        return height
    }
    
    override func didDismissCompletion() {
        super.didDismissCompletion()
        tableView.contentOffset = .zero
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        topGradientShadow.layer.sublayers?.forEach { layer in
            if layer is CAGradientLayer {
                layer.position = bottomGradientShadow.bounds.center
                layer.bounds = bottomGradientShadow.bounds
            }
        }

        bottomGradientShadow.layer.sublayers?.forEach { layer in
            if layer is CAGradientLayer {
                layer.position = bottomGradientShadow.bounds.center
                layer.bounds = bottomGradientShadow.bounds
            }
        }
    }
    
    func getPromptRealHeight() -> CGFloat {
        guard show else {
            return 0
        }
        if sectionHeights.isEmpty {
            caculateHeaderHeight()
        }
        var totalHeight: CGFloat = 0
        for (idx, model) in groupModels.enumerated() {
            var sectionHeaderHeight = sectionHeights[idx] ?? Metric.sectionHeaderHeight
            if model.title.isEmpty == true {
                sectionHeaderHeight = 0.01
            }
            totalHeight += (CGFloat(model.prompts.count) * Metric.rowHeight + sectionHeaderHeight)
        }
        if self.groupModels.count == 1, self.groupModels.first?.prompts.count == 0 {
            // 只有一个组头时，增加高度
            totalHeight += Metric.groupHeaderTopMargin
        }
        // 第二组以及之后的组头和前面有一个间距
        totalHeight += CGFloat(self.groupModels.count - 1) * Metric.sectionFooterHeight
        return totalHeight + Metric.bottomInset
    }
    
    func disableListContentPanGesture() {
        if let panGesture = panGesture {
            tableView.removeGestureRecognizer(panGesture)
        }
        panGesture = nil
    }
    
    var isPromptPanGestureEnable: Bool {
        return panGesture != nil
    }
}


extension InlineAIItemPromptView: UITableViewDelegate, UITableViewDataSource {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        topGradientShadow.isHidden = !(scrollView.contentOffset.y > 0)
        
        let height = scrollView.frame.height
        let delta = scrollView.contentSize.height - height
        let offsetRemain = scrollView.contentSize.height - height - scrollView.contentOffset.y
        let deviation: CGFloat = 1
        if offsetRemain < deviation  {
            self.bottomGradientShadow.isHidden = true
        } else {
            self.bottomGradientShadow.isHidden = delta <= 0
        }
        isIncreaseReload = false
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return groupModels.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupModels[section].prompts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PromptCell", for: indexPath) as? PromptCell else {
            return UITableViewCell()
        }
        guard indexPath.section < groupModels.count,
           indexPath.row < groupModels[indexPath.section].prompts.count else {
            return UITableViewCell()
        }
        let prompt = groupModels[indexPath.section].prompts[indexPath.row]
        
        var attributedText: NSAttributedString
        if let color = promptTextColor {
            attributedText = prompt.text.htmlAttributedString(attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                                                                                     NSAttributedString.Key.foregroundColor: color])
        } else if let attributedString = prompt.attributedString?.value {
            attributedText = attributedString
        } else {
            attributedText = prompt.text.htmlAttributedString(attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
        }
        
        cell.update(attributedText: attributedText, showArrow: prompt.rightArrow == true, image: prompt.iconImage)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section < groupModels.count,
           indexPath.row < groupModels[indexPath.section].prompts.count else {
            return
        }
        let prompt = groupModels[indexPath.section].prompts[indexPath.row]
        eventRelay.accept(.choosePrompt(prompt: prompt))
    }

    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "PromptHeaderView") as? PromptHeaderView
        guard section < groupModels.count else {
            return nil
        }
        header?.titleLabel.text = groupModels[section].title
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section < groupModels.count else {
            return UITableView.automaticDimension
        }
        let title = groupModels[section].title ?? ""
        let height = caculateContentHeight(title)
        sectionHeights[section] = height
        return height
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == self.numberOfSections(in: tableView) - 1 {
            return 0.01
        }
        return Metric.sectionFooterHeight
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        return view
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if isIncreaseReload,
           tableView.contentOffset.y < 10,
           section > 0 {
            DispatchQueue.main.async {
                view.alpha = 0
                view.setNeedsLayout()
                view.layoutIfNeeded()
                UIView.animate(withDuration: 0.8) {
                    view.alpha = 1
                }
            }
        }
    }
    
    // MARK: - delete
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard indexPath.section < groupModels.count,
           indexPath.row < groupModels[indexPath.section].prompts.count else {
            return nil
        }
        let prompt = groupModels[indexPath.section].prompts[indexPath.row]
        if prompt.type == InlineAIPanelModel.PromptType.historyPrompt.rawValue, !prompt.rightArrow {
            let deleteAction = UIContextualAction(style: .destructive, title: "") { [weak self] (_, _, completionHandler) in
                self?.eventRelay.accept(.deleteHistoryPrompt(prompt: prompt))
                completionHandler(true)
            }
            deleteAction.image = UDIcon.getIconByKey(.deleteTrashOutlined, iconColor: UDColor.staticWhite)
            deleteAction.backgroundColor = UDColor.colorfulRed
            let config = UISwipeActionsConfiguration(actions: [deleteAction])
            config.performsFirstActionWithFullSwipe = false
            return config
        } else {
            return nil
        }
    }

}


extension InlineAIItemPromptView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc
    func panGestureAction(gesture: UIPanGestureRecognizer) {
        guard let gestureDelegate = self.gestureDelegate else { return }
        if tableView.contentOffset.y < 0 {
            tableView.setContentOffset(.zero, animated: false)
            tableView.isScrollEnabled = false
        }
        switch gesture.state {
        case .began, .changed:
            if tableView.contentOffset.y <= 0 || !tableView.isScrollEnabled {
                gestureDelegate.panGestureRecognizerDidReceive(gesture, in: self)
            }
        case .ended, .cancelled, .failed:
            if !tableView.isScrollEnabled {
                gestureDelegate.panGestureRecognizerDidReceive(gesture, in: self)
            } else {
                gestureDelegate.panGestureRecognizerDidFinish(gesture, in: self)
            }
            tableView.isScrollEnabled = true
        default:
            break
        }
    }
}


extension Reactive where Base: UIView {
    var isHiddenBeSet: Observable<Bool> {
        let anyObservable = self.base.rx.methodInvoked(#selector(setter: self.base.isHidden))
        let boolObservable = anyObservable
            .flatMap { Observable.from(optional: $0.first as? Bool) }
            .startWith(self.base.isHidden)
            .distinctUntilChanged()
            .share()

        return boolObservable
    }
    
    var isRemoveFromSuperviewSet: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(base.removeFromSuperview)).map { _ in }
        return ControlEvent(events: source)
    }
}

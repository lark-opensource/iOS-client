//
//  LabVirtualBgView.swift
//  ByteView
//
//  Created by liquanmin on 2020/9/17.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import SnapKit
import ByteViewCommon
import ByteViewUI

class LabVirtualBgView: UIView, VirtualBgDataDelegate {
    struct Layout {
        static func cellWidth() -> CGFloat { // 本身宽度+边框
            return LabVirtualBgCell.Layout.cellImageWidth() + 2 * LabVirtualBgCell.Layout.cellBorderTotalWidth()
        }

        static func cellHeight() -> CGFloat {
            return LabVirtualBgCell.Layout.cellImageHeight() + 2 * LabVirtualBgCell.Layout.cellBorderTotalWidth()
        }

        static let landscapeModeCellSpacing: CGFloat = 16  // 横屏模式视觉间隔为16

        static func viewWidth(isLandscapeMode: Bool) -> CGFloat {
            if isLandscapeMode {
                let lineCount: CGFloat = max(VCScene.bounds.height, VCScene.bounds.width) > 720 ? 5 : 4  //screenHeight不会随横竖屏而改变
                return LabVirtualBgCell.Layout.cellImageWidth() * lineCount + landscapeModeCellSpacing * (lineCount + 1)
            }
            return Display.pad ? VCScene.bounds.width : min(VCScene.bounds.height, VCScene.bounds.width)  // 横竖屏的时候 VCScene.bounds宽高会变化
        }

        static func calculateSpacing(isLandscapeMode: Bool) -> CGFloat { // 视觉上的间隔，间隔包括了边框
            if isLandscapeMode {
                return 16
            } else {
                return (Layout.viewWidth(isLandscapeMode: isLandscapeMode) - LabVirtualBgCell.Layout.cellImageWidth() * 5) / 6
            }
        }

        static func cellSpacing(isLandscapeMode: Bool) -> CGFloat { // 真正的间隔，减去了边框
            if Layout.isRegular() {
                return 20 - 2 * LabVirtualBgCell.Layout.cellBorderTotalWidth()
            } else {
                return floor(Layout.calculateSpacing(isLandscapeMode: isLandscapeMode) - 2 * LabVirtualBgCell.Layout.cellBorderTotalWidth())
            }
        }

        static func collectionLeftRightMarin(isLandscapeMode: Bool) -> CGFloat {
            if Layout.isRegular() {
                return 28 - LabVirtualBgCell.Layout.cellBorderTotalWidth()
            } else {
                return Layout.calculateSpacing(isLandscapeMode: isLandscapeMode) - LabVirtualBgCell.Layout.cellBorderTotalWidth()
            }
        }

        static func isRegular() -> Bool { VCScene.rootTraitCollection?.isRegular ?? false }
    }
    private let viewModel: InMeetingLabViewModel
    private lazy var itemLayout = UICollectionViewFlowLayout.init()
    lazy var bgCollectionView: UICollectionView = {
        UICollectionView.init(frame: .zero, collectionViewLayout: itemLayout)
    }()

    lazy var loadingView: LabLoadingView = {
        let view = LabLoadingView()
        view.status = .none
        return view
    }()

    private var viewWidth: CGFloat = 0
    var deleteBlock: ((VirtualBgModel) -> Void)?
    var longPressBlock: (() -> Void)?
    var showDecorate: Bool = false

    private lazy var imageLoader = LabImageLoader(service: viewModel.service)
    let serialQueue = DispatchQueue(label: "lab bg quene")
    var isLandscapeMode: Bool { return viewModel.fromSource == .inMeet && isPhoneLandscape } // preview进入特效不横屏

    init(frame: CGRect, vm: InMeetingLabViewModel) {
        self.viewModel = vm
        super.init(frame: frame)
        self.showDecorate = (vm.fromSource == .inMeet &&
                             vm.setting.isDecorateEnabled &&
                             vm.setting.canPersonalInstall &&
                             vm.setting.enableCustomMeetingBackground)
        self.viewModel.virtualBgDataDelegate = self
        setupViews()
        checkVirtualBgStatus(status: viewModel.virtualBgService.loadingStatus)
        viewModel.virtualBgService.addListener(self)
        if viewModel.virtualBgService.calendarMeetingVirtual != nil {
            checkForUnAllow()
            viewModel.virtualBgService.addCalendarListener(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        Logger.lab.info("lab: LabVirtualBgView deinit")
    }

    func viewDidLayoutSubviews(width: CGFloat) {
        updateCollectionView(width: width)
    }

    private func setupCollectionView() {
        itemLayout.scrollDirection = .vertical
        resetItemLayout()

        bgCollectionView.delegate = self
        bgCollectionView.dataSource = self
        bgCollectionView.showsVerticalScrollIndicator = false
        bgCollectionView.delaysContentTouches = false
        bgCollectionView.backgroundColor = UIColor.clear
        bgCollectionView.bounces = true
        bgCollectionView.register(LabVirtualBgCell.self, forCellWithReuseIdentifier: "labVirtualBgCell")
        bgCollectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        bgCollectionView.register(LabDecorateView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "FooterDecorate")
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        bgCollectionView.addGestureRecognizer(gesture)
        addSubview(bgCollectionView)
    }

    private func setupViews() {
        setupCollectionView()
        addSubview(loadingView)
        loadingView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        bindLoadingStatus()
    }

    func layoutForTraitCollection() {
        // ipad c视图和r视图区别太大，重新生成collectionview
        bgCollectionView.removeFromSuperview()
        bgCollectionView = UICollectionView.init(frame: .zero, collectionViewLayout: itemLayout)
        bgCollectionView.isHidden = !(loadingView.status == .none)
        setupCollectionView()
        updateCollectionView(width: Layout.viewWidth(isLandscapeMode: isLandscapeMode))
        self.reloadCollection()
    }

    @objc
    private func handleLongPress(_ tap: UILongPressGestureRecognizer) {
        if tap.state == .began {
            let pointTouch = tap.location(in: bgCollectionView)  // 只有有图片的cell才可以长按
            let indexPath = bgCollectionView.indexPathForItem(at: pointTouch)
            guard let indexPath = indexPath else {
                return
            }
            let row = indexPath.row
            if row >= 0, row < viewModel.virtualBgs.count {
                let model = self.viewModel.virtualBgs[row]
                if model.isSettingModel() || model.bgType == .blur {
                    return
                }
            }
            // nolint-next-line: magic number
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                self.longPressBlock?()
            }
        }
    }

    func resetItemLayout() {
        let margin: CGFloat = Layout.isRegular() ? 20 : 16
        itemLayout.minimumLineSpacing = margin - 2 * LabVirtualBgCell.Layout.cellBorderTotalWidth()
        itemLayout.minimumInteritemSpacing = Layout.cellSpacing(isLandscapeMode: isLandscapeMode)
        itemLayout.headerReferenceSize = CGSize(width: Layout.viewWidth(isLandscapeMode: isLandscapeMode), height: margin - LabVirtualBgCell.Layout.cellBorderTotalWidth())
        itemLayout.footerReferenceSize = showDecorate ? CGSize(width: Layout.viewWidth(isLandscapeMode: isLandscapeMode), height: LabDecorateView.Layout.height()) : CGSize(width: Layout.viewWidth(isLandscapeMode: isLandscapeMode), height: ((Layout.isRegular() ? 28 : 23) - LabVirtualBgCell.Layout.cellBorderTotalWidth()))
    }

    private func updateCollectionView(width: CGFloat) {
        viewWidth = width
        guard !self.viewModel.virtualBgs.isEmpty else { return }

        bgCollectionView.snp.remakeConstraints { maker in
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.left.right.equalToSuperview().inset(Layout.collectionLeftRightMarin(isLandscapeMode: isLandscapeMode))
        }
    }

    func getExtraBgFrame() -> CGRect? {
        var index = -1
        for (i, model) in viewModel.virtualBgs.enumerated() {
            if model.imageSource == .appCalendar, model.isSelected == true {
                index = i
            }
         }
        if index >= 0, extraCellVisible(index: index), let cellFrame = bgCollectionView.layoutAttributesForItem(at: IndexPath(row: index, section: 0))?.frame {
            return cellFrame
        }
        return nil
    }

    func extraCellVisible(index: Int) -> Bool {
        let cellIndexs = bgCollectionView.indexPathsForVisibleItems
        let iscontain = cellIndexs.first { $0.row == index }
        return iscontain != nil
    }

    func dataSetChanged() {
        reloadCollection()
        updateCollectionView(width: viewWidth)
    }

    func reloadCollection() {
        UIView.performWithoutAnimation {
            bgCollectionView.reloadData()
        }
    }

    private func bindLoadingStatus() {
        loadingView.reloadHandler = { [weak self] in
            self?.viewModel.reloadVirtualBg()
        }
    }

    private func checkForUnAllow() {
        if !viewModel.virtualBgService.allowVirtualBgInfo.allow {
            changeForAllowedStatus(allowInfo: viewModel.virtualBgService.allowVirtualBgInfo)
        }
    }

    private func checkVirtualBgStatus(status: EffectLoadingStatus) {
        switch status {
        case .loading, .unStart:
            self.loadingView.status = .loading
            self.bgCollectionView.isHidden = true
        case .failed:
            self.loadingView.status = .failed
            self.bgCollectionView.isHidden = true
        case .done:
            self.loadingView.status = .none
            self.bgCollectionView.isHidden = false
        }
        Logger.lab.info("bg loading status: \(status), type: virtualbg")
        checkForUnAllow() //兜底逻辑
    }

    func changeForAllowedStatus(allowInfo: AllowVirtualBgRelayInfo) {
        if !allowInfo.allow {
            self.loadingView.status = .notAllowBackground
            self.bgCollectionView.isHidden = true
        }
        Logger.lab.info("bg allow status: \(allowInfo), type: virtualbg")
    }
}

extension LabVirtualBgView: EffectVirtualBgListener, EffectVirtualBgCalendarListener {
    func didChangeVirtualBgloadingStatus(status: EffectLoadingStatus) {
        Util.runInMainThread {
            self.checkVirtualBgStatus(status: status)
        }
    }

    func didChangeVirtualBgAllow(allowInfo: AllowVirtualBgRelayInfo) {
        Util.runInMainThread {
            self.changeForAllowedStatus(allowInfo: allowInfo)
        }
    }
}

extension LabVirtualBgView: LabVirtualBgCellDelegate {
    func didTapDelete(model: VirtualBgModel) {
    }
}

/// 实现 UICollection 的协议
extension LabVirtualBgView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.virtualBgs.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "labVirtualBgCell",
                                                         for: indexPath) as? LabVirtualBgCell {
            cell.tag = indexPath.item

            let model = self.viewModel.virtualBgs[indexPath.row]
            cell.delegate = self
            cell.deleteBlock = deleteBlock
            cell.bindData(model: model)

            if model.bgType == .virtual {
                imageLoader.obtainImageWithPath(model: model) { [weak cell] image in
                    if cell?.tag == indexPath.item {
                        cell?.imageView.image = image
                    }
                }
            }

            return cell
        }
        return UICollectionViewCell(frame: .zero)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let reusableView = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: "Header",
                for: indexPath as IndexPath)
            return reusableView
        } else if kind == UICollectionView.elementKindSectionFooter {
            if let reusableView = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionFooter,
                withReuseIdentifier: "FooterDecorate",
                for: indexPath as IndexPath) as? LabDecorateView {
                if showDecorate {
                    reusableView.viewModel = viewModel
                    reusableView.updateView(inset: LabVirtualBgCell.Layout.cellBorderTotalWidth())
                    reusableView.containerView.isHidden = false
                } else {
                    reusableView.containerView.isHidden = true
                }
                // 关闭灵禅 FG
                reusableView.containerView.isHidden = true
                return reusableView
            }
            return UICollectionReusableView()
        }
        return UICollectionReusableView()
    }
}

extension LabVirtualBgView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedModel = viewModel.virtualBgs[indexPath.row]  // loading不给点击
        if !selectedModel.status.isLoading {
            viewModel.selectVirtualBg(index: indexPath.row)
        }
    }
}

extension LabVirtualBgView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Layout.cellWidth(), height: Layout.cellHeight())
    }
}

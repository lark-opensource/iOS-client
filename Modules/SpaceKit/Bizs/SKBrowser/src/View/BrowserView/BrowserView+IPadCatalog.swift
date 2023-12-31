//
//  BrowserView+IPadCatalog.swift
//  SKBrowser
//
//  Created by lizechuang on 2021/4/6.
//

import SKFoundation
import SKCommon

typealias IpadCatalogDisplayInfo = (mode: IPadCatalogMode, width: CGFloat)

extension BrowserView: CatalogPadDisplayer {
    
    public func presentCatalogSideView(catalogSideView: IPadCatalogSideView, autoPresentInEmbed: Bool, complete: ((_ mode: IPadCatalogMode) -> Void)?) {
        let infos = self.calculateDisplayInfos()
        if infos.mode == .covered, autoPresentInEmbed {
            return
        }
        self.catalogSideViewPad = catalogSideView
        if self.catalogSideViewPad?.superview == nil {
            addSubview(catalogSideView)
        }
        self.ipadCatalogDisplayInfo = infos
        // 嵌入式目录 需要在menuBlock后面才不会遮挡住menuBlock
        if infos.mode == .embedded {
            subviews.forEach({ (view) in
                if view is BlockMenuBaseView {
                    insertSubview(catalogSideView, belowSubview: view)
                }
            })
        }
        catalogSideView.setIPadCatalogMode(infos.mode,
                                           docsInfo: docsInfo,
                                           browserHeight: self.frame.height)
        if infos.mode == .embedded {
            catalogSideView.snp.remakeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                make.left.equalToSuperview().offset(-infos.width)
                make.width.equalTo(infos.width)
            }
            self.layoutIfNeeded()
            editorWrapperView.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(self.ipadCatalogContainWidth)
            }
            catalogSideView.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(0)
            }
        } else {
            catalogSideView.snp.remakeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                make.left.equalToSuperview().offset(-infos.width)
                make.width.equalTo(infos.width)
            }
            self.layoutIfNeeded()
            editorWrapperView.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(self.ipadCatalogContainWidth)
            }
            catalogSideView.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(0)
            }
        }
        self.ipadCatalogAlreadyDismiss = false
        self.jsEngine.callFunction(DocsJSCallBack.catalogChangeDisplayMode,
                                   params: ["mode": (infos.mode == .embedded) ? "embedded" : "covered", "isShowing": true],
                                   completion: nil)
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        } completion: { (_) in
            self.setIpadCatalogState(isOpen: true)
            complete?(infos.mode)
        }
    }

    public func dismissCatalogSideView(complete: @escaping () -> Void) {
        guard let catalogSideViewPad = self.catalogSideViewPad,
              catalogSideViewPad.superview != nil,
              let infos = self.ipadCatalogDisplayInfo else {
            return
        }
        self.ipadCatalogAlreadyDismiss = true
        self.jsEngine.callFunction(DocsJSCallBack.catalogChangeDisplayMode,
                                   params: ["mode": (infos.mode == .embedded) ? "embedded" : "covered", "isShowing": false],
                                   completion: nil)
        UIView.animate(withDuration: 0.25) {
            catalogSideViewPad.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(-infos.width)
            }
            self.editorWrapperView.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(0)
            }
            self.layoutIfNeeded()
        } completion: { (_) in
            self.resetCatalogSideView()
            complete()
        }
    }

    public func dismissCatalogSideViewByTapContent(complete: @escaping () -> Void) {
        guard let catalogSideViewPad = self.catalogSideViewPad,
              catalogSideViewPad.superview != nil,
              let infos = self.ipadCatalogDisplayInfo else {
            return
        }
        // 当点击正文区域此时是嵌入式的情况，不需要隐藏目录
        guard infos.mode == .covered, !self.ipadCatalogAlreadyDismiss else {
            return
        }
        dismissCatalogSideView(complete: complete)
    }

    func resetCatalogSideView() {
        if catalogSideViewPad != nil {
            catalogSideViewPad?.snp.removeConstraints()
            catalogSideViewPad?.removeFromSuperview()
            catalogSideViewPad = nil
            ipadCatalogDisplayInfo = nil
            self.editorWrapperView.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(0)
            }
        }
    }

    func updateCatalogSideView() {
        // 当前状态是不处于.background，才需要去处理相关逻辑 分屏模式下是处于.inactive模式
        guard UIApplication.shared.applicationState != .background else {
            return
        }
        guard let catalogSideViewPad = self.catalogSideViewPad, catalogSideViewPad.superview != nil, let infos = self.ipadCatalogDisplayInfo else {
            return
        }
        let newInfos = self.calculateDisplayInfos()
        // 1.0 这种情况下只需要更新当前的宽度
        if newInfos.mode == infos.mode {
            // 因为版本的目录入口不会常驻，还会收到more面板里去，如果旋转后，目录入口不展示了，要dissmiss掉
            if docsInfo?.isVersion ?? false,
               self.isMyWindowCompactSize() {
                self.dismissCatalogSideView { [weak self] in
                    self?.setIpadCatalogState(isOpen: false)
                }
                return
            }
            
            if newInfos.width != infos.width {
                if newInfos.mode == .covered {
                    UIView.animate(withDuration: 0.25) {
                        catalogSideViewPad.snp.updateConstraints { (make) in
                            make.width.equalTo(newInfos.width)
                        }
                        self.layoutIfNeeded()
                    } completion: { (_) in
                        self.ipadCatalogDisplayInfo?.width = newInfos.width
                        catalogSideViewPad.updateLayout()
                    }
                } else {
                    catalogSideViewPad.snp.updateConstraints { (make) in
                        make.width.equalTo(newInfos.width)
                    }
                    self.editorWrapperView.snp.updateConstraints { (make) in
                        make.left.equalToSuperview().offset(newInfos.width)
                    }
                    self.ipadCatalogDisplayInfo?.width = newInfos.width
                    self.catalogSideViewPad?.layoutIfNeeded()
                    self.catalogSideViewPad?.updateLayout()
                    UIView.animate(withDuration: 0.25) {
                        self.layoutIfNeeded()
                    }
                }
            }
            return
        }
        // 2.0 模式转换逻辑走dismiss - present逻辑
        // 2.1 嵌入式 - 覆盖式，直接移除
        if infos.mode == .embedded, newInfos.mode == .covered {
            self.dismissCatalogSideView { [weak self] in
                self?.setIpadCatalogState(isOpen: false)
            }
            return
        }
        // 2.2 覆盖式 - 嵌入式，走dismiss - present逻辑
        catalogSideViewPad.snp.updateConstraints { (make) in
            make.left.equalToSuperview().offset(-infos.width)
        }
        self.editorWrapperView.snp.updateConstraints { (make) in
            make.left.equalToSuperview().offset(self.ipadCatalogContainWidth)
        }
        self.presentCatalogSideView(catalogSideView: catalogSideViewPad, autoPresentInEmbed: false, complete: nil)
    }
}

// MARK: - 计算显示样式
extension BrowserView {
    func calculateDisplayInfos() -> IpadCatalogDisplayInfo {
        let containerWidth = self.frame.width
        var catalogWidth: CGFloat = 0.0
        if containerWidth > IPadCatalogConst.embeddedMinimumContainerWidth {
            // 嵌入式
            if containerWidth >= IPadCatalogConst.maxContentWidth {
                catalogWidth = containerWidth * IPadCatalogConst.catalogDisplayLargePercentage
            } else {
                catalogWidth = containerWidth * IPadCatalogConst.catalogDisplayNormalPercentage
            }
            catalogWidth = max(catalogWidth, IPadCatalogConst.catalogDisplayMinWidth)
            return (.embedded, catalogWidth)
        } else {
            // 覆盖式
            return (.covered, IPadCatalogConst.catalogDisplayCoveredWidth)
        }
    }
}

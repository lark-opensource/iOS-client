//
//  ExportPictureAnimator.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/28.
//
// 处理导出长图的view展示

import Foundation
import Lottie
import SnapKit
import SKCommon
import SKResource
import SKUIKit
import UniverseDesignLoading

class ExportPictureAnimator {
    
    private var loadingView = UDLoading.loadingImageView()
    
    private weak var hostView: UIView?
    init(hostView: UIView?) {
        self.hostView = hostView
    }

    private lazy var loadingTipsMask: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N00
        return view
    }()

    private lazy var loadingTips: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        label.text = BundleI18n.SKResource.Doc_Normal_ImageIsExporting
        return label
    }()

    func showExportLongPicLoading(duration: Int = 5) {
        if loadingTipsMask.superview == nil {
            hostView?.addSubview(loadingTipsMask)
            loadingTipsMask.addSubview(loadingView)
            loadingTipsMask.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            loadingView.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
            }
            hostView?.bringSubviewToFront(loadingTipsMask)
        }
        loadingTips.sizeToFit()

        if duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(duration), execute: {
                self.hideExportLongPicLoading()
            })
        }
    }

    public func hideExportLongPicLoading() {
        DispatchQueue.main.async(execute: {
            self.loadingView.removeFromSuperview()
            self.loadingTipsMask.removeFromSuperview()
            self.loadingTipsMask.snp.removeConstraints()
        })
    }
}

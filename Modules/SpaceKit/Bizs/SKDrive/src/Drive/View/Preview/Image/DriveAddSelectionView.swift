//
//  DriveAddSelectionView.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/6/5.
//

import UIKit
import SnapKit
import SKCommon
import SKResource
import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon

class DriveAddSelectionView: UIView {
    var closeBtnDidClick: ((_ selectionView: DriveAddSelectionView) -> Void)?
    var commentBtnClick: ((_ selectionView: DriveAddSelectionView, _ area: DriveAreaComment.Area) -> Void)?
    var touchToCreateArea: ((_ selectionView: DriveAddSelectionView, _ position: CGPoint) -> Void)?
    private var needTouchToCreateArea: Bool = false
    private(set) var selectionEditView: DriveSelectionEditView?
    var panGesture: UIPanGestureRecognizer? {
        return selectionEditView?.activeAreaView?.panGesture
    }
    private lazy var tapGesture: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(gesture:)))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        return tap
    }()

    private lazy var closeBtn: UIButton = {
        let btn = UIButton()
        let image = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 30, height: 30))
            .ud.withTintColor(UDColor.primaryOnPrimaryFill)
        btn.setImage(image, for: .normal)
        btn.addTarget(self, action: #selector(closeClicked), for: .touchUpInside)
        return btn
    }()

    private lazy var commentBtn: UIButton  = {
        let btn = UIButton()
        btn.setTitle(BundleI18n.SKResource.Drive_Drive_AreaCommentAddText, for: .normal)
        btn.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.backgroundColor = UDColor.primaryContentDefault
        btn.layer.cornerRadius = 4.0
        btn.layer.masksToBounds = true
        btn.addTarget(self, action: #selector(commentClick), for: .touchUpInside)
        btn.isHidden = true
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        return btn
    }()
    private lazy var editTipsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N00
        label.text = BundleI18n.SKResource.Drive_Drive_PrepareAreaCommentAdd
        label.isHidden = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    /// selectionPosition: 选区中心点，相对位置，百分比表示
    func show(on supperView: UIView, contentRect: CGRect, selectionPosition: CGPoint? = nil) {
        supperView.addSubview(self)
        self.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        selectionEditView?.removeFromSuperview()
        let view = DriveSelectionEditView(frame: contentRect)
        insertSubview(view, at: 0)
        selectionEditView = view
        if let position = selectionPosition {
            commentBtn.isHidden = false
            needTouchToCreateArea = false
            createArea(at: position)
        } else {
            editTipsLabel.isHidden = false
            needTouchToCreateArea = true
        }
    }

    func createArea(at position: CGPoint) {
        guard let view = selectionEditView else { return }
        var selctionRect = CGRect(origin: CGPoint.zero,
                                  size: CGSize(width: 150, height: 150))
        selctionRect.center = position.absolutedPoint(in: view.frame)
        let selectionView = DriveSelectionView()
        view.addArea(selctionRect.relativeArea(in: view.frame),
                     view: selectionView)
    }
    /// 除按钮和选区外，蒙层其他位置不响应触摸事件
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if commentBtn.frame.contains(point) {
            return commentBtn
        } else if closeBtn.frame.contains(point) {
            return closeBtn
        }
        if let editView = selectionEditView,
            needTouchToCreateArea,
            editView.frame.contains(point) {
            return editView
        }
        if let editView = selectionEditView, let areaFrame = editView.activeAreaView?.frame {
            let rect = editView.convert(areaFrame, to: self)
            if rect.contains(point) {
                return editView.activeAreaView
            }
        }
        return nil
    }
    private func setupUI() {
        backgroundColor = .clear
        addSubview(closeBtn)
        addSubview(commentBtn)
        addSubview(editTipsLabel)
        addGestureRecognizer(tapGesture)
        closeBtn.snp.makeConstraints { (make) in
            make.width.height.equalTo(30)
            make.left.equalToSuperview().offset(8)
            make.top.equalToSuperview().offset(26)
        }
        commentBtn.snp.makeConstraints { (make) in
            make.width.greaterThanOrEqualTo(108)
            make.height.equalTo(28)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).offset(-20)
        }
        editTipsLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-128)
            make.height.equalTo(40)
        }
    }
    @objc
    private func closeClicked() {
        closeBtnDidClick?(self)
    }
    @objc
    private func commentClick() {
        guard let area = selectionEditView?.activeArea else {
            DocsLogger.warning("selection area is nil")
            return
        }
        commentBtnClick?(self, area)
    }

    @objc
    private func handleSingleTap(gesture: UITapGestureRecognizer) {
        guard let editView = selectionEditView, needTouchToCreateArea else {
            return
        }
        needTouchToCreateArea = false
        editTipsLabel.isHidden = true
        commentBtn.isHidden = false
        let position = gesture.location(in: editView)
        touchToCreateArea?(self, position)
    }
}

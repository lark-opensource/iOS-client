//
//  CommentQuoteAndReplyCell.swift
//  SpaceKit
//
//  Created by chenhuaguan on 2020/2/27.
//

import SKFoundation
import UIKit
import RxSwift
import RxCocoa
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import SpaceInterface
import UniverseDesignFont

protocol CommentQuoteAndResolveViewDelegate: NSObjectProtocol {
    func didClickResolveBtn(from: UIView, comment: Comment?)
    func didClickMoreBtn(from: UIView, comment: Comment?)
}


class CommentQuoteAndReplyCell: CommentShadowBaseCell {

    weak var delegate: CommentQuoteAndResolveViewDelegate?
    static var cellId = "CommentQuoteAndReplyCell"

    var canResolve: Bool = true {
        didSet {
            resolveBtn.isHidden = (canResolve == false)
        }
    }

    lazy var resolveBtn: UIButton = {
        let btn = DocsButton(frame: .zero)
        btn.widthInset = -8
        btn.heightInset = -8
        btn.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        let image = UDIcon.getIconByKey(.yesOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconN2, size: .init(width: 16, height: 16))
        btn.setImage(image, for: .normal)
        btn.accessibilityIdentifier = "docs.comment.headerview.more"
        btn.contentHorizontalAlignment = .center
        btn.docs.addHighlight(with: UIEdgeInsets(top: -2, left: -4, bottom: -2, right: -4), radius: 4)
        return btn
    }()

    // 背景白板
    private lazy var bgView: UIView = {
        let bg = UIView(frame: .zero)
        bg.backgroundColor = .clear
        bg.layer.shadowRadius = 8
//        bg.layer.shadowColor = UIColor.ud.N1000.withAlphaComponent(0.08).cgColor
        bg.layer.ud.setShadowColor(UIColor.ud.shadowDefaultMd)
        bg.layer.shadowOpacity = 1.0
        bg.layer.shadowOffset = CGSize(width: 0, height: 0)

        let bgColorView = UIView(frame: .zero)
        bgColorView.backgroundColor = UIColor.ud.bgFloat
        bgColorView.layer.cornerRadius = 8
        bgColorView.layer.masksToBounds = true
        bgColorView.layer.borderWidth = 0.5
        bgColorView.layer.ud.setBorderColor(UIColor.ud.N300 & UIColor.clear)
        bg.addSubview(bgColorView)
        bgColorView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return bg
    }()

    // 坐标竖线
    lazy var line: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UDColor.udtokenQuoteBarBg
        view.layer.cornerRadius = 1
        view.layer.masksToBounds = true
        return view
    }()

    // 文字Label
    lazy var quote: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = UIFont.systemFont(ofSize: 14.0)
        view.textColor = UIColor.ud.N600
        return view
    }()


    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(bgView)
        contentView.addSubview(line)
        contentView.addSubview(quote)
        contentView.addSubview(resolveBtn)

        bgView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-3)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(3)
        }

        line.snp.makeConstraints { (make) in
            make.width.equalTo(2)
            make.height.equalTo(14)
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(bgView.snp.top).offset(13)
            make.bottom.equalTo(bgView.snp.bottom).offset(-13)
        }

        quote.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.right.equalTo(resolveBtn.snp.left).offset(-16)
            make.left.equalTo(line.snp.right).offset(5)
            make.centerY.equalTo(line.snp.centerY)
        }

        resolveBtn.snp.makeConstraints { (make) in
            make.width.equalTo(30)
            make.height.equalTo(24)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(line.snp.centerY)
        }
    }
    
    enum Style {
        case onlyResolve
        case onlyMore
        case coexist
    }

    var style: Style = .onlyResolve
    
    func updateResolveStyle(_ style: Style = .onlyResolve) {
        self.style = style
        switch style {
        case .onlyResolve:
            let resolveImage = UDIcon.getIconByKey(.yesOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconN2, size: .init(width: 16, height: 16))
            resolveBtn.setImage(resolveImage, for: .normal)
            resolveBtn.isHidden = !canResolve
        case .onlyMore:
            let moreImage = UDIcon.getIconByKey(.moreOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconN2, size: .init(width: 16, height: 16))
            resolveBtn.setImage(moreImage, for: .normal)
            resolveBtn.isHidden = false
        case .coexist:
            DocsLogger.error("coexist is not allowed", component: LogComponents.comment)
            spaceAssertionFailure("coexist is not allowed")
        }
        
    }

    func updateWithQuoteText(text: String?, fontZoomable: Bool) {
        // bugfix, 和产品确认的预期:
        // 1. 引用头部不应该有换行符，但是目前移动端和web都可能操作产生引用以\n开头的情况，因此手动忽略
        // 2. 如果引用中间有换行，可以对齐 android 的体验，用 ... 显示
        // 3. 如果引用的头部有空格，需要从有文字的地方开始显示
        let trimmedText = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let formattedText = trimmedText.replacingOccurrences(of: "\n", with: "...\n")
        quote.text = formattedText
        let font = fontZoomable ? UIFont.ud.body2 : UIFont.systemFont(ofSize: 14.0)
        quote.font = font
        if fontZoomable {
            line.snp.updateConstraints { (make) in
                make.height.equalTo(max(font.lineHeight, 14))
            }
        }
    }

    @objc
    func onTap() {
        if canResolve || style != .onlyResolve {
            self.delegate?.didClickResolveBtn(from: resolveBtn, comment: curCommment)
        }
    }

}

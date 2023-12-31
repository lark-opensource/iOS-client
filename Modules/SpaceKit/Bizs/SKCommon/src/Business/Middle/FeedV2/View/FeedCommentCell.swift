//
//  FeedCommentCell.swift
//  SKCommon
//
//  Created by huayufan on 2021/5/14.
//  

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher
import UniverseDesignColor

protocol FeedRedDotDelegate: AnyObject {
    func shouldDisplayRedDot(cell: UITableViewCell, data: FeedCellDataSource) -> Bool
}


class FeedCommentCell: UITableViewCell {
   
    static var simpleStyleIdentifier = "simpleStyleIdentifier"
    
    private let Layout = FeedMessageStyle.cellSubviewsLayout
    
    enum Event {
        case content(FeedContentView.Event)
        case translated(FeedContentView.Event)
        case tapAvatar
    }
    
    /// 头像
    var avatarView = UIImageView()
    
    var circleView = UIImageView()
    
    /// 显示姓名或者评论信息
    var titleLabel = UILabel()
    
    /// 引文
    var quoteView = FeedCellQuoteView()
    
    /// 显示评论内容
    var commentContentView = FeedContentView()
    
    /// 显示翻译内容
    var translateView = FeedContentView()
    
    var timeLabel = UILabel()
    
    /// 分割线
    var bottomLine = UIView()
    
    /// 小红点
    var redDotView = UIImageView()
    
    var disposeBag = DisposeBag()
    
    var reuseBag = DisposeBag()
    
    var actions = PublishRelay<Event>()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupInit()
        setupLayout()
        bindAction()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        reuseBag = DisposeBag()
    }
    
    private func setupInit() {
        
        self.selectedBackgroundView = UIView(frame: self.frame)
        self.selectedBackgroundView?.backgroundColor = UDColor.Y100
        
        avatarView.construct {
            $0.contentMode = .scaleAspectFit
            $0.isUserInteractionEnabled = true
            $0.layer.cornerRadius = Layout.iconSize.width * 0.5
            $0.layer.masksToBounds = true
            $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarClick)))
        }
        
        circleView.construct {
            $0.contentMode = .scaleAspectFit
            $0.isUserInteractionEnabled = true
//            $0.image = CircleComponent.holeImage(diameter: Layout.iconSize.width)?.ud.withTintColor(UIColor.ud.bgBody)
            $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarClick)))
        }
        
        titleLabel.construct({
            $0.textColor = UIColor.ud.N900
            $0.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            $0.numberOfLines = 0
            $0.textAlignment = .left
        })
        
        timeLabel = UILabel().construct({
            $0.textColor = UIColor.ud.N500
            $0.textAlignment = .left
            $0.font = UIFont.systemFont(ofSize: 14)
        })
        
        redDotView.construct({
            $0.contentMode = .scaleAspectFit
        })
        
        bottomLine.construct({
            $0.backgroundColor = UIColor.ud.N300
        })
        
        contentView.addSubview(avatarView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(quoteView)
        contentView.addSubview(commentContentView)
        contentView.addSubview(translateView)
        contentView.addSubview(timeLabel)
        contentView.addSubview(bottomLine)
        avatarView.addSubview(circleView)
        contentView.addSubview(redDotView)
//        selectionStyle = .none
    }
    
    private func setupLayout() {
        
        avatarView.snp.makeConstraints {
            $0.left.equalToSuperview().inset(Layout.padding)
            $0.top.equalToSuperview().offset(Layout.iconTopMargin)
            $0.size.equalTo(Layout.iconSize)
        }
        
        circleView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        redDotView.snp.makeConstraints { (make) in
            make.width.height.equalTo(Layout.redDotDiameter)
            make.top.right.equalTo(avatarView).inset(Layout.redDotInset)
        }
        
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Layout.titleTopMargin)
            $0.left.equalToSuperview().offset(Layout.iconRightMargin + Layout.iconSize.width + Layout.padding)
            $0.right.equalToSuperview().inset(Layout.padding)
        }
        
        if reuseIdentifier == FeedCommentCell.simpleStyleIdentifier { // 不显示评论
            timeLabel.snp.makeConstraints {
                $0.top.equalTo(titleLabel.snp.bottom).offset(Layout.timeTopMargin)
                $0.left.equalTo(titleLabel)
                $0.height.equalTo(Layout.timeHeight)
                $0.right.equalToSuperview().inset(Layout.padding)
                $0.bottom.equalToSuperview().inset(Layout.timeBottomMargin)
            }
        } else { // 显示评论
            quoteView.snp.makeConstraints {
                $0.left.equalTo(titleLabel)
                $0.right.equalToSuperview().inset(Layout.padding)
                $0.top.equalTo(titleLabel.snp.bottom).offset(Layout.quoteTopMargin)
                $0.height.equalTo(Layout.quoteHeight)
            }
            
            commentContentView.setContentHuggingPriority(.defaultHigh, for: .vertical)
            commentContentView.snp.makeConstraints {
                $0.left.equalTo(titleLabel)
                $0.right.equalToSuperview().inset(Layout.padding)
                $0.top.equalTo(quoteView.snp.bottom).offset(Layout.contentTopMargin)
            }
            translateView.setContentHuggingPriority(.defaultHigh, for: .vertical)
            translateView.snp.makeConstraints {
                $0.left.equalTo(titleLabel)
                $0.right.equalToSuperview().inset(Layout.padding)
                $0.top.equalTo(commentContentView.snp.bottom).offset(Layout.translateTopMargin)
                $0.bottom.equalTo(timeLabel.snp.top).offset(-Layout.timeTopMargin)
            }
            
            timeLabel.snp.makeConstraints {
                $0.left.equalTo(titleLabel.snp.left)
                $0.height.equalTo(Layout.timeHeight)
                $0.right.equalToSuperview().inset(Layout.padding)
                $0.bottom.equalToSuperview().inset(Layout.timeBottomMargin)
            }
        }
        
        bottomLine.snp.makeConstraints {
            $0.height.equalTo(0.5)
            $0.left.equalTo(titleLabel)
            $0.bottom.right.equalToSuperview()
        }
    }
    
    func bindAction() {
        if reuseIdentifier != FeedCommentCell.simpleStyleIdentifier {
            Observable.merge(self.commentContentView.actions.asObservable(),
                             self.translateView.actions.asObservable())
                      .map { Event.content($0) }
                      .bind(to: actions)
                      .disposed(by: disposeBag)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: - event

extension FeedCommentCell {
    
    @objc
    func avatarClick() {
        actions.accept(.tapAvatar)
    }
}

// MARK: - public

extension FeedCommentCell {
    
    func config(data: FeedCellDataSource, redDotDelegate: FeedRedDotDelegate) {
        let avatarResouce = data.avatarResouce
        if let defaultDocsImage = avatarResouce.defaultDocsImage {
            avatarView.image = defaultDocsImage
        } else {
            avatarView.kf.setImage(with: URL(string: avatarResouce.url ?? ""),
                                   placeholder: avatarResouce.placeholder)
        }
        titleLabel.text = data.titleText
        
        if reuseIdentifier != FeedCommentCell.simpleStyleIdentifier {
            self.commentContentView.isHidden = false
            self.translateView.isHidden = false
            let showQuote = (data.quoteText ?? "").isEmpty == false
            quoteView.setQuote(text: data.quoteText)
            quoteView.snp.updateConstraints {
                $0.top.equalTo(titleLabel.snp.bottom).offset(showQuote ? Layout.quoteTopMargin : 0)
                $0.height.equalTo(showQuote ? Layout.quoteHeight : 0)
            }
            
            data.getContentConfig { [weak self] (config) in
                self?.commentContentView.update(mode: .normal(config: config))
            }
            
            data.getTranslateConfig { [weak self] (config) in
                guard let self = self else { return }
                self.translateView.update(mode: .hilighted(config: config))
                if config.text == nil {
                    self.translateView.snp.updateConstraints {
                        $0.top.equalTo(self.commentContentView.snp.bottom).offset(0)
                    }
                } else {
                    self.translateView.snp.updateConstraints {
                        $0.top.equalTo(self.commentContentView.snp.bottom).offset(self.Layout.translateTopMargin)
                    }
                }
            }
        } else {
            self.commentContentView.isHidden = true
            self.translateView.isHidden = true
        }
        
        data.getTime { [weak self] (time) in
            self?.timeLabel.text = time
        }
        let showRedDot = redDotDelegate.shouldDisplayRedDot(cell: self, data: data)
        redDotView.isHidden = !showRedDot
        if showRedDot, redDotView.image == nil {
            redDotView.image = CircleComponent.redDotImage(diameter: Layout.redDotDiameter)
        }
    }
    
    func hideRedDot() {
        redDotView.isHidden = true
    }
}

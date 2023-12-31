//
//  CommentCollectionViewCell.swift
//  SpaceKit
//
//  Created by xurunkang on 2018/11/16.
//

import UIKit
import SKFoundation
import SpaceInterface
import SKCommon

class CommentCollectionViewCell: UICollectionViewCell {

    weak var delegate: CommentCollectionViewCellDelegate?

    var isHideMoreActionButtons: Bool = true {
        didSet {
            if oldValue != isHideMoreActionButtons {
                tableView?.reloadData()
            }
        }
    }

    var currentEditingCommentItem: CommentItem?

    var indexPath: IndexPath!
    var docsInfo: DocsInfo?
    var canComment: Bool = false
    var canShowReaction: Bool = false
    var fromFeed: Bool = false

    var permission: CommentPermission?
    
    var mode: CardCommentMode = .browseMode

    var tableView: UITableView?
    
    var translateConfig: CommentBusinessConfig.TranslateConfig?

    private var oriComment: Comment?
    private(set) var comment: Comment! { // 必须有值
        didSet {
            oriComment = oldValue
            tableView?.reloadData()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    func initUI() {
        setupUI()
    }

    func configComment(_ comment: Comment) {
        self.comment = comment
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func scrollTableViewToBottom(animated: Bool) {
        DispatchQueue.main.async {
            if self.comment.commentList.count > 0 {
                let lastIndexPath = IndexPath(row: self.comment.commentList.count - 1, section: 0)
                self.tableView?.scrollToRow(at: lastIndexPath, at: .middle, animated: animated)
            } else {
                DocsLogger.info("scrollTableViewToBottom, listCount=\(self.comment.commentList.count)", component: LogComponents.comment)
            }
        }
    }
}

extension CommentCollectionViewCell: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comment.commentList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier: "CommentTableViewCell") as? CommentTableViewCell) ?? CommentTableViewCell(style: .default, reuseIdentifier: "CommentTableViewCell")
        if indexPath.row < comment.commentList.count {
            let item = comment.commentList[indexPath.row]
            cell.translateConfig = translateConfig
            cell.delegate = delegate
            cell.cellWidth = self.frame.size.width > 0 ? self.frame.size.width : nil
            cell.permission = permission
            cell.canShowMoreActionButton = !_isHideMoreActionButton(for: item)
            cell.canShowReactionView = canShowReaction
            cell.configCellData(item, isFailState: comment.isUnsummit || item.errorCode != 0, isLoadingState: item.isSending)
            cell.updateMoreButton(18)
            
            var editingCommentItem = currentEditingCommentItem
            if case let .edit(item) = mode {
                editingCommentItem = item
            }
            if editingCommentItem?.replyID == item.replyID { // 正在编辑的 cell
                cell.backgroundColor = UIColor.ud.N100  // 颜色可能需要调整
            } else {
                cell.backgroundColor = .clear
            }
        }
        return cell
    }

    private func _isHideMoreActionButton(for item: CommentItem) -> Bool {

        // 0. [没有强制隐藏]
        if isHideMoreActionButtons {
            return true
        }

        // sheet 特殊处理
        if let type = docsInfo?.type, type == .sheet {
            return false
        }

        // 什么情况都显示
        if let permission = permission {
            return !permission.contains(.canShowMore)
        }

        // 什么情况显示三个点，前提是[没有强制隐藏]
        // 1. 自己发送的卡片评论都显示
        // 2. 自己发送的全文评论都显示
        // 3. 有评论权限的全文评论

        // 1. 自己发送的卡片评论都显示
        // 2. 自己发送的全文评论都显示
        if item.userID == User.current.info?.userID {
            return false
        }

        return true
    }
}

// PRIVATE METHOD
extension CommentCollectionViewCell {
    private func setupUI() {
        guard let tableView = self.tableView, tableView.superview == nil else { return }
        tableView.backgroundColor = UIColor.ud.bgBody
        addSubview(tableView)

        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension CommentCollectionViewCell: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row < comment.commentList.count else {
            return
        }
        let item = comment.commentList[indexPath.row]
        guard item.status == .unread else {
            return
        }
        delegate?.markReadMessage(commentItem: item)
        item.status = .read
    }
}

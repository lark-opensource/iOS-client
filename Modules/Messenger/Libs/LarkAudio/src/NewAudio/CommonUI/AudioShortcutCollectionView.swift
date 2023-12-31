//
//  AudioShortcutCollectionView.swift
//  LarkAudio
//
//  Created by kangkang on 2023/10/31.
//

import LarkAIInfra
import Foundation
import UniverseDesignFont
import UniverseDesignColor

final class AudioShortcutCollectionView: UIView {
    enum Cons {
        static let shortcutCollectionHeight: CGFloat = 32
    }
    private static let cellID = "AudioAICollectionCell"
    private let collection: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 8
        return UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    }()
    var dataSource: [AIPrompt] = []
    var clickCallback: (AIPrompt) -> Void = { _ in }

    init() {
        super.init(frame: .zero)
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.showsVerticalScrollIndicator = false
        collection.contentInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        collection.register(AudioAICell.self, forCellWithReuseIdentifier: AudioShortcutCollectionView.cellID)

        collection.delegate = self
        collection.dataSource = self
        self.addSubview(collection)
        collection.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(Cons.shortcutCollectionHeight)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AudioShortcutCollectionView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AudioShortcutCollectionView.cellID, for: indexPath) as? AudioAICell else { return UICollectionViewCell() }
        cell.setValue(dataSource[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = dataSource[indexPath.row].text
        let rect = NSString(string: title).boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT)),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: UDFont.body0], context: nil)
        return CGSize(width: ceil(rect.width) + 42, height: Cons.shortcutCollectionHeight)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        clickCallback(dataSource[indexPath.row])
    }
}

final class AudioAICell: UICollectionViewCell {
    private let icon = UIImageView()
    private let textLabel = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UDColor.bgBody
        self.layer.cornerRadius = AudioShortcutCollectionView.Cons.shortcutCollectionHeight / 2
        self.layer.masksToBounds = true
        textLabel.font = UDFont.body0
        let wrapper = UIView()
        self.addSubview(wrapper)
        wrapper.addSubview(icon)
        wrapper.addSubview(textLabel)

        icon.snp.makeConstraints { make in
            make.width.height.equalTo(18)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
        }
        textLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
            make.left.equalTo(icon.snp.right).offset(4)
        }
        wrapper.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-4)
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
    }

    func setValue(_ prompt: AIPrompt) {
        self.icon.image = PromptIcon(rawValue: prompt.icon)?.image?.ud.withTintColor(UDColor.colorfulIndigo)
        self.textLabel.text = prompt.text
        let width = prompt.text.getWidth(font: textLabel.font)
        let height = textLabel.font.lineHeight
        textLabel.textColor = UDColor.AIPrimaryContentDefault.toColor(withSize: CGSize(width: width, height: height))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

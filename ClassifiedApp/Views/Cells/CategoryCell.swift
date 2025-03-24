import UIKit
import ClassifiedCoreKit

class CategoryCell: UICollectionViewCell {
    static let reuseIdentifier = "CategoryCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private let dotSeparator: UILabel = {
        let label = UILabel()
        label.text = "•"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .systemGray
        label.isHidden = true
        return label
    }()
    
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(dotSeparator)
        
        titleLabel.anchor(
            top: contentView.topAnchor,
            left: contentView.leadingAnchor,
            bottom: contentView.bottomAnchor
        )
        
        dotSeparator.anchor(
            left: titleLabel.trailingAnchor, paddingLeft: 8,
            right: contentView.trailingAnchor,
            width: 8
        )
        dotSeparator.centerY(inView: titleLabel)
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        if isSelected {
            titleLabel.textColor = .systemBlue
            titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        } else {
            titleLabel.textColor = .label
            titleLabel.font = UIFont.systemFont(ofSize: 16)
        }
    }
    
    func configure(with category: ClassifiedCoreKit.Category, showDot: Bool = true) {
        titleLabel.text = category.name
        dotSeparator.isHidden = !showDot
    }
} 
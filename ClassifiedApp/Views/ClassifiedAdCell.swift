import UIKit
import ClassifiedCoreKit

class ClassifiedAdCell: UICollectionViewCell {
    static let reuseIdentifier = "ClassifiedAdCell"
    
    // MARK: - Properties
    private var imageLoader: CoreImageLoader?
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()
    
    private let adImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        return imageView
    }()
    
    private let urgentBadge: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 4
        view.isHidden = true
        return view
    }()
    
    private let urgentLabel: UILabel = {
        let label = UILabel()
        label.text = "URGENT"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .systemBlue
        return label
    }()
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Setup
    private func setupViews() {
        contentView.addSubview(containerView)
        
        containerView.addSubview(adImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(priceLabel)
        containerView.addSubview(categoryLabel)
        containerView.addSubview(dateLabel)
        
        containerView.addSubview(urgentBadge)
        urgentBadge.addSubview(urgentLabel)
        
        // Layout using UIView+Layout
        containerView.anchor(
            top: contentView.topAnchor, paddingTop: 4,
            left: contentView.leadingAnchor, paddingLeft: 4,
            bottom: contentView.bottomAnchor, paddingBottom: 4,
            right: contentView.trailingAnchor, paddingRight: 4
        )
        
        adImageView.anchor(
            top: containerView.topAnchor, paddingTop: 8,
            left: containerView.leadingAnchor, paddingLeft: 8,
            width: 120, height: 120
        )
        
        urgentBadge.anchor(
            top: adImageView.topAnchor, paddingTop: 8,
            left: adImageView.leadingAnchor, paddingLeft: 8,
            height: 20
        )
        
        urgentLabel.anchor(
            top: urgentBadge.topAnchor, paddingTop: 3,
            left: urgentBadge.leadingAnchor, paddingLeft: 6,
            bottom: urgentBadge.bottomAnchor, paddingBottom: 3,
            right: urgentBadge.trailingAnchor, paddingRight: 6
        )
        
        titleLabel.anchor(
            top: containerView.topAnchor, paddingTop: 12,
            left: adImageView.trailingAnchor, paddingLeft: 12,
            right: containerView.trailingAnchor, paddingRight: 12
        )
        
        priceLabel.anchor(
            top: titleLabel.bottomAnchor, paddingTop: 8,
            left: adImageView.trailingAnchor, paddingLeft: 12,
            right: containerView.trailingAnchor, paddingRight: 12
        )
        
        categoryLabel.anchor(
            left: containerView.leadingAnchor, paddingLeft: 8,
            bottom: containerView.bottomAnchor, paddingBottom: 12
        )
        categoryLabel.setHorizontalDimension(equalTo: containerView.widthAnchor, multiplier: 0.5)
        
        dateLabel.anchor(
            bottom: containerView.bottomAnchor, paddingBottom: 12,
            right: containerView.trailingAnchor, paddingRight: 12
        )
        dateLabel.setHorizontalDimension(equalTo: containerView.widthAnchor, multiplier: 0.5)
    }
    
    // MARK: - Configuration
    func configure(with ad: CoreClassifiedAd, categoryName: String, imageLoader: CoreImageLoader = CoreImageLoader.shared) {
        self.imageLoader = imageLoader
        
        titleLabel.text = ad.title
        priceLabel.text = ad.formattedPrice
        categoryLabel.text = categoryName
        dateLabel.text = ad.formattedDate
        
        urgentBadge.isHidden = !ad.isUrgent
        
        loadImage(from: ad.imagesUrl.small ?? ad.imagesUrl.thumb)
    }
    
    private func loadImage(from url: URL?) {
        // Reset image for reused cells
        adImageView.image = nil
        
        guard let url = url else {
            adImageView.image = UIImage(systemName: "photo")
            return
        }
        
        imageLoader?.loadImage(from: url) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    self?.adImageView.image = image
                case .failure:
                    self?.adImageView.image = UIImage(systemName: "photo")
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        adImageView.image = nil
        titleLabel.text = nil
        priceLabel.text = nil
        categoryLabel.text = nil
        dateLabel.text = nil
        urgentBadge.isHidden = true
        // Don't set imageLoader to nil here, as it's a dependency
    }
} 
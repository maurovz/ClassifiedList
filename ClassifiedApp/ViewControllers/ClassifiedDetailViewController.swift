import UIKit
import ClassifiedCoreKit

class ClassifiedDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let classifiedAd: CoreClassifiedAd
    private let categoryName: String
    private let imageLoader: CoreImageLoader
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        return scrollView
    }()
    
    private let contentView = UIView()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
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
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .systemBlue
        return label
    }()
    
    private let categoryTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.text = "Category"
        return label
    }()
    
    private let categoryValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()
    
    private let dateTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.text = "Date Posted"
        return label
    }()
    
    private let dateValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()
    
    private let siretTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.text = "SIRET"
        return label
    }()
    
    private let siretValueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()
    
    private let descriptionTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.text = "Description"
        return label
    }()
    
    private let descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = .label
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        return textView
    }()
    
    // MARK: - Initialization
    init(classifiedAd: CoreClassifiedAd, categoryName: String, imageLoader: CoreImageLoader = CoreImageLoader.shared) {
        self.classifiedAd = classifiedAd
        self.categoryName = categoryName
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        configureUI()
    }
    
    // MARK: - Setup
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(categoryTitleLabel)
        contentView.addSubview(categoryValueLabel)
        contentView.addSubview(dateTitleLabel)
        contentView.addSubview(dateValueLabel)
        contentView.addSubview(descriptionTitleLabel)
        contentView.addSubview(descriptionTextView)
        
        contentView.addSubview(urgentBadge)
        urgentBadge.addSubview(urgentLabel)
        
        if classifiedAd.siret != nil {
            contentView.addSubview(siretTitleLabel)
            contentView.addSubview(siretValueLabel)
        }
        
        scrollView.anchor(
            top: view.safeAreaLayoutGuide.topAnchor,
            left: view.leadingAnchor,
            bottom: view.bottomAnchor,
            right: view.trailingAnchor
        )
        
        contentView.anchor(
            top: scrollView.topAnchor,
            left: scrollView.leadingAnchor,
            bottom: scrollView.bottomAnchor,
            right: scrollView.trailingAnchor
        )
        contentView.setHorizontalDimension(equalTo: scrollView.widthAnchor, multiplier: 1.0)
        
        imageView.anchor(
            top: contentView.topAnchor,
            left: contentView.leadingAnchor,
            right: contentView.trailingAnchor,
            height: 300
        )
        
        urgentBadge.anchor(
            top: imageView.topAnchor, paddingTop: 16,
            right: imageView.trailingAnchor, paddingRight: 16,
            height: 24
        )
        
        urgentLabel.anchor(
            top: urgentBadge.topAnchor, paddingTop: 4,
            left: urgentBadge.leadingAnchor, paddingLeft: 8,
            bottom: urgentBadge.bottomAnchor, paddingBottom: 4,
            right: urgentBadge.trailingAnchor, paddingRight: 8
        )
        
        titleLabel.anchor(
            top: imageView.bottomAnchor, paddingTop: 16,
            left: contentView.leadingAnchor, paddingLeft: 16,
            right: contentView.trailingAnchor, paddingRight: 16
        )
        
        priceLabel.anchor(
            top: titleLabel.bottomAnchor, paddingTop: 8,
            left: contentView.leadingAnchor, paddingLeft: 16,
            right: contentView.trailingAnchor, paddingRight: 16
        )
        
        categoryTitleLabel.anchor(
            top: priceLabel.bottomAnchor, paddingTop: 16,
            left: contentView.leadingAnchor, paddingLeft: 16,
            width: 120
        )
        
        categoryValueLabel.anchor(
            left: categoryTitleLabel.trailingAnchor, paddingLeft: 8,
            right: contentView.trailingAnchor, paddingRight: 16
        )
        categoryValueLabel.centerY(inView: categoryTitleLabel)
        
        dateTitleLabel.anchor(
            top: categoryTitleLabel.bottomAnchor, paddingTop: 8,
            left: contentView.leadingAnchor, paddingLeft: 16,
            width: 120
        )
        
        dateValueLabel.anchor(
            left: dateTitleLabel.trailingAnchor, paddingLeft: 8,
            right: contentView.trailingAnchor, paddingRight: 16
        )
        dateValueLabel.centerY(inView: dateTitleLabel)
        
        if classifiedAd.siret != nil {
            siretTitleLabel.anchor(
                top: dateTitleLabel.bottomAnchor, paddingTop: 8,
                left: contentView.leadingAnchor, paddingLeft: 16,
                width: 120
            )
            
            siretValueLabel.anchor(
                left: siretTitleLabel.trailingAnchor, paddingLeft: 8,
                right: contentView.trailingAnchor, paddingRight: 16
            )
            siretValueLabel.centerY(inView: siretTitleLabel)
            
            descriptionTitleLabel.anchor(
                top: siretTitleLabel.bottomAnchor, paddingTop: 20,
                left: contentView.leadingAnchor, paddingLeft: 16,
                right: contentView.trailingAnchor, paddingRight: 16
            )
        } else {
            descriptionTitleLabel.anchor(
                top: dateTitleLabel.bottomAnchor, paddingTop: 20,
                left: contentView.leadingAnchor, paddingLeft: 16,
                right: contentView.trailingAnchor, paddingRight: 16
            )
        }
        
        descriptionTextView.anchor(
            top: descriptionTitleLabel.bottomAnchor, paddingTop: 8,
            left: contentView.leadingAnchor, paddingLeft: 12,
            bottom: contentView.bottomAnchor, paddingBottom: 20,
            right: contentView.trailingAnchor, paddingRight: 12
        )
    }
    
    private func configureUI() {
        titleLabel.text = classifiedAd.title
        priceLabel.text = classifiedAd.formattedPrice
        categoryValueLabel.text = categoryName
        dateValueLabel.text = classifiedAd.formattedDate
        descriptionTextView.text = classifiedAd.description
        
        if let siret = classifiedAd.siret {
            siretValueLabel.text = siret
        }
        
        urgentBadge.isHidden = !classifiedAd.isUrgent
        
        loadImage()
    }
    
    private func loadImage() {
        let imageUrl = classifiedAd.imagesUrl.small ?? classifiedAd.imagesUrl.thumb
        
        guard let url = imageUrl else {
            imageView.image = UIImage(systemName: "photo")
            return
        }
        
        imageLoader.loadImage(from: url) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    self?.imageView.image = image
                case .failure:
                    self?.imageView.image = UIImage(systemName: "photo")
                }
            }
        }
    }
} 
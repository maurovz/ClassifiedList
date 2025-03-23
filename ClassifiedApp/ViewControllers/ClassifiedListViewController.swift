import UIKit
import ClassifiedCoreKit

// MARK: - Navigation Coordinator Protocol
protocol ClassifiedListCoordinator: AnyObject {
    func showDetail(for ad: CoreClassifiedAd, categoryName: String)
}

class ClassifiedListViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: ClassifiedListViewModel
    private var selectedCategoryId: Int? = Category.all.id
    private let imageLoader: CoreImageLoader
    weak var coordinator: ClassifiedListCoordinator?
    
    // MARK: - UI Components
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
    
    private let categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    // MARK: - Initialization
    init(viewModel: ClassifiedListViewModel? = nil, 
         imageLoader: CoreImageLoader = CoreImageLoader.shared,
         coordinator: ClassifiedListCoordinator? = nil) {
        self.viewModel = viewModel ?? ClassifiedListViewModel(
            repository: ServiceFactory.shared.createClassifiedRepository()
        )
        self.imageLoader = imageLoader
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.viewModel = ClassifiedListViewModel(
            repository: ServiceFactory.shared.createClassifiedRepository()
        )
        self.imageLoader = CoreImageLoader.shared
        self.coordinator = nil
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureCollectionViews()
        setupBindings()
        loadData()
        
        title = "Classified Ads"
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(categoryCollectionView)
        view.addSubview(collectionView)
        view.addSubview(activityIndicator)
        view.addSubview(errorLabel)
        
        // Using your UIView+Layout extension
        categoryCollectionView.anchor(
            top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 8,
            left: view.leadingAnchor,
            right: view.trailingAnchor,
            height: 44
        )
        
        collectionView.anchor(
            top: categoryCollectionView.bottomAnchor, paddingTop: 8,
            left: view.leadingAnchor,
            bottom: view.bottomAnchor,
            right: view.trailingAnchor
        )
        
        activityIndicator.center(inView: view)
        
        errorLabel.anchor(
            left: view.leadingAnchor, paddingLeft: 32,
            right: view.trailingAnchor, paddingRight: 32
        )
        errorLabel.centerY(inView: view)
    }
    
    private func configureCollectionViews() {
        collectionView.register(ClassifiedAdCell.self, forCellWithReuseIdentifier: ClassifiedAdCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        categoryCollectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.reuseIdentifier)
        categoryCollectionView.dataSource = self
        categoryCollectionView.delegate = self
        categoryCollectionView.tag = 1 // Tag to differentiate from main collection view
    }
    
    private func setupBindings() {
        viewModel.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.handleStateChange(state)
            }
        }
    }
    
    private func handleStateChange(_ state: ClassifiedListViewModel.State) {
        switch state {
        case .idle:
            activityIndicator.stopAnimating()
            errorLabel.isHidden = true
            collectionView.isHidden = false
            
        case .loading:
            activityIndicator.startAnimating()
            errorLabel.isHidden = true
            collectionView.isHidden = true
            
        case .loaded:
            activityIndicator.stopAnimating()
            errorLabel.isHidden = true
            collectionView.isHidden = false
            collectionView.reloadData()
            
        case .error(let message):
            activityIndicator.stopAnimating()
            errorLabel.text = message
            errorLabel.isHidden = false
            collectionView.isHidden = true
            
        case .categoriesLoaded:
            updateCategoryFilter()
        }
    }
    
    private func loadData() {
        viewModel.loadCategories()
        viewModel.loadClassifiedAds()
    }
    
    private func updateCategoryFilter() {
        categoryCollectionView.reloadData()
        // Select the first category by default
        if viewModel.categories.isNotEmpty {
            let indexPath = IndexPath(item: 0, section: 0)
            categoryCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
            categoryFilterChanged(indexPath)
        }
    }
    
    private func categoryFilterChanged(_ indexPath: IndexPath) {
        guard indexPath.item >= 0 && indexPath.item < viewModel.categories.count else { return }
        
        let selectedCategory = viewModel.categories[indexPath.item]
        selectedCategoryId = selectedCategory.id
        
        viewModel.filterAds(by: selectedCategoryId)
    }
}

// MARK: - UICollectionViewDataSource
extension ClassifiedListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 1 {
            return viewModel.categories.count
        } else {
            return viewModel.filteredAds.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView.tag == 1 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.reuseIdentifier, for: indexPath) as? CategoryCell else {
                return UICollectionViewCell()
            }
            
            let category = viewModel.categories[indexPath.item]
            let showDot = indexPath.item < viewModel.categories.count - 1
            cell.configure(with: category, showDot: showDot)
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ClassifiedAdCell.reuseIdentifier, for: indexPath) as? ClassifiedAdCell else {
                return UICollectionViewCell()
            }
            
            let ad = viewModel.filteredAds[indexPath.item]
            let categoryName = viewModel.getCategoryName(for: ad.categoryId)
            
            cell.configure(with: ad, categoryName: categoryName, imageLoader: imageLoader)
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate
extension ClassifiedListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.tag == 1 {
            // Category collection view
            categoryFilterChanged(indexPath)
        } else {
            // Main collection view
            collectionView.deselectItem(at: indexPath, animated: true)
            
            let ad = viewModel.filteredAds[indexPath.item]
            let categoryName = viewModel.getCategoryName(for: ad.categoryId)
            
            // Use the coordinator for navigation instead of directly handling it
            coordinator?.showDetail(for: ad, categoryName: categoryName)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ClassifiedListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView.tag == 1 {
            let category = viewModel.categories[indexPath.item]
            let font = UIFont.systemFont(ofSize: 16)
            
            let textWidth = category.name.size(withAttributes: [.font: font]).width
            
            let padding: CGFloat = 20.0
            
            let dotSpace: CGFloat = indexPath.item < viewModel.categories.count - 1 ? 16 : 0
            return CGSize(width: textWidth + dotSpace + padding, height: 44)
        } else {
            let width = collectionView.bounds.width - 32  // 16 points padding on each side
            return CGSize(width: width, height: 200)
        }
    }
}

// MARK: - Category Cell
class CategoryCell: UICollectionViewCell {
    static let reuseIdentifier = "CategoryCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dotSeparator: UILabel = {
        let label = UILabel()
        label.text = "•"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
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
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            dotSeparator.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            dotSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dotSeparator.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            dotSeparator.widthAnchor.constraint(equalToConstant: 8)
        ])
        
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

extension Collection {
    var isNotEmpty: Bool {
        return !isEmpty
    }
} 

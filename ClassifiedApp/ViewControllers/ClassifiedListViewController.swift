import UIKit
import ClassifiedCoreKit

// MARK: - Navigation Coordinator Protocol
protocol ClassifiedListCoordinator: AnyObject {
    func showDetail(for ad: CoreClassifiedAd, categoryName: String)
}

class ClassifiedListViewController: UIViewController {
    
    // MARK: - Constants
    private enum CollectionViewType: Int {
        case categories = 1
        case listings = 2
    }
    
    // MARK: - Properties
    private let viewModel: ClassifiedListViewModel
    private let imageLoader: CoreImageLoader
    weak var coordinator: ClassifiedListCoordinator?
    
    // MARK: - UI Components
    private let listingsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.showsVerticalScrollIndicator = false
        collectionView.tag = CollectionViewType.listings.rawValue
        return collectionView
    }()
    
    private let categoriesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.tag = CollectionViewType.categories.rawValue
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
        setupNavigationBar()
    }
    
    // MARK: - Private Methods
    private func setupNavigationBar() {
        let logoImageView = UIImageView(image: UIImage(named: "logo"))
        logoImageView.contentMode = .scaleAspectFit
        
        let height: CGFloat = 30
        logoImageView.frame = CGRect(x: 0, y: 0, width: 150, height: height)
        
        navigationItem.titleView = logoImageView
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(categoriesCollectionView)
        view.addSubview(listingsCollectionView)
        view.addSubview(activityIndicator)
        view.addSubview(errorLabel)
        
        // Using your UIView+Layout extension
        categoriesCollectionView.anchor(
            top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 8,
            left: view.leadingAnchor,
            right: view.trailingAnchor,
            height: 44
        )
        
        listingsCollectionView.anchor(
            top: categoriesCollectionView.bottomAnchor, paddingTop: 8,
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
        // Configure listings collection view
        listingsCollectionView.register(ClassifiedAdCell.self, forCellWithReuseIdentifier: ClassifiedAdCell.reuseIdentifier)
        listingsCollectionView.dataSource = self
        listingsCollectionView.delegate = self
        
        // Configure categories collection view
        categoriesCollectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.reuseIdentifier)
        categoriesCollectionView.dataSource = self
        categoriesCollectionView.delegate = self
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
            listingsCollectionView.isHidden = false
            
        case .loading:
            activityIndicator.startAnimating()
            errorLabel.isHidden = true
            listingsCollectionView.isHidden = true
            
        case .loaded:
            activityIndicator.stopAnimating()
            errorLabel.isHidden = true
            listingsCollectionView.isHidden = false
            listingsCollectionView.reloadData()
            
        case .error(let message):
            activityIndicator.stopAnimating()
            errorLabel.text = message
            errorLabel.isHidden = false
            listingsCollectionView.isHidden = true
            
        case .categoriesLoaded:
            updateCategoryFilter()
        }
    }
    
    private func loadData() {
        viewModel.loadCategories()
        viewModel.loadClassifiedAds()
    }
    
    private func updateCategoryFilter() {
        categoriesCollectionView.reloadData()
        if viewModel.categories.isNotEmpty {
            let indexPath = IndexPath(item: 0, section: 0)
            categoriesCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
            categoryFilterChanged(indexPath)
        }
    }
    
    private func categoryFilterChanged(_ indexPath: IndexPath) {
        guard indexPath.item >= 0 && indexPath.item < viewModel.categories.count else { return }
        
        let selectedCategory = viewModel.categories[indexPath.item]
        viewModel.filterAds(by: selectedCategory.id)
    }
}

// MARK: - UICollectionViewDataSource
extension ClassifiedListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let type = CollectionViewType(rawValue: collectionView.tag) else { return 0 }
        
        switch type {
        case .categories:
            return viewModel.categories.count
        case .listings:
            return viewModel.filteredAds.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let type = CollectionViewType(rawValue: collectionView.tag) else { 
            return UICollectionViewCell() 
        }
        
        switch type {
        case .categories:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.reuseIdentifier, for: indexPath) as? CategoryCell else {
                return UICollectionViewCell()
            }
            
            let category = viewModel.categories[indexPath.item]
            let showDot = indexPath.item < viewModel.categories.count - 1
            cell.configure(with: category, showDot: showDot)
            return cell
            
        case .listings:
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
        guard let type = CollectionViewType(rawValue: collectionView.tag) else { return }
        
        switch type {
        case .categories:
            categoryFilterChanged(indexPath)
            
        case .listings:
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
        guard let type = CollectionViewType(rawValue: collectionView.tag) else {
            return CGSize(width: 100, height: 100) // Default size
        }
        
        switch type {
        case .categories:
            let category = viewModel.categories[indexPath.item]
            let font = UIFont.systemFont(ofSize: 16)
            
            let textWidth = category.name.size(withAttributes: [.font: font]).width
            let padding: CGFloat = 20.0
            let dotSpace: CGFloat = indexPath.item < viewModel.categories.count - 1 ? 16 : 0
            
            return CGSize(width: textWidth + dotSpace + padding, height: 44)
            
        case .listings:
            let width = collectionView.bounds.width - 32
            return CGSize(width: width, height: 200)
        }
    }
}

extension Collection {
    var isNotEmpty: Bool {
        return !isEmpty
    }
} 

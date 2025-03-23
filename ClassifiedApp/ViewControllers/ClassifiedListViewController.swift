import UIKit
import ClassifiedCoreKit

// MARK: - Navigation Coordinator Protocol
protocol ClassifiedListCoordinator: AnyObject {
    func showDetail(for ad: CoreClassifiedAd, categoryName: String)
}

class ClassifiedListViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: ClassifiedListViewModel
    private let imageLoader: CoreImageLoader
    weak var coordinator: ClassifiedListCoordinator?
    
    // MARK: - Data Sources
    private lazy var categoriesDataSource: CategoriesDataSource = {
        let dataSource = CategoriesDataSource(viewModel: viewModel)
        dataSource.delegate = self
        return dataSource
    }()
    
    private lazy var listingsDataSource: ListingsDataSource = {
        let dataSource = ListingsDataSource(viewModel: viewModel, imageLoader: imageLoader)
        dataSource.delegate = self
        return dataSource
    }()
    
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
        
        // Debug the coordinator status
        if let coord = coordinator {
            print("Coordinator successfully initialized: \(type(of: coord))")
        } else {
            print("Warning: Initializing ClassifiedListViewController with nil coordinator")
        }
        
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
        listingsCollectionView.dataSource = listingsDataSource
        listingsCollectionView.delegate = listingsDataSource
        
        // Configure categories collection view
        categoriesCollectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.reuseIdentifier)
        categoriesCollectionView.dataSource = categoriesDataSource
        categoriesCollectionView.delegate = categoriesDataSource
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
            selectCategory(at: indexPath)
        }
    }
    
    private func selectCategory(at indexPath: IndexPath) {
        guard indexPath.item >= 0 && indexPath.item < viewModel.categories.count else { return }
        
        let selectedCategory = viewModel.categories[indexPath.item]
        viewModel.filterAds(by: selectedCategory.id)
    }
}

// MARK: - CategoriesDataSourceDelegate
extension ClassifiedListViewController: CategoriesDataSourceDelegate {
    func categoriesDataSource(_ dataSource: CategoriesDataSource, didSelectCategory category: ClassifiedCoreKit.Category) {
        viewModel.filterAds(by: category.id)
    }
}

// MARK: - ListingsDataSourceDelegate
extension ClassifiedListViewController: ListingsDataSourceDelegate {
    func listingsDataSource(_ dataSource: ListingsDataSource, didSelectAd ad: CoreClassifiedAd, withCategoryName categoryName: String) {
        if coordinator == nil {
            print("Error: coordinator is nil, navigation won't work")
        }
        
        coordinator?.showDetail(for: ad, categoryName: categoryName)
    }
}

extension Collection {
    var isNotEmpty: Bool {
        return !isEmpty
    }
} 

import UIKit
import ClassifiedCoreKit

class ClassifiedListViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: ClassifiedListViewModel
    private var selectedCategoryId: Int? = Category.all.id
    private let imageLoader: CoreImageLoader
    
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
    
    private let categoryFilterControl: UISegmentedControl = {
        let control = UISegmentedControl()
        return control
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
    init(viewModel: ClassifiedListViewModel? = nil, imageLoader: CoreImageLoader = CoreImageLoader.shared) {
        self.viewModel = viewModel ?? ClassifiedListViewModel(
            repository: ServiceFactory.shared.createClassifiedRepository()
        )
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.viewModel = ClassifiedListViewModel(
            repository: ServiceFactory.shared.createClassifiedRepository()
        )
        self.imageLoader = CoreImageLoader.shared
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureCollectionView()
        setupBindings()
        loadData()
        
        title = "Classified Ads"
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(categoryFilterControl)
        view.addSubview(collectionView)
        view.addSubview(activityIndicator)
        view.addSubview(errorLabel)
        
        // Using your UIView+Layout extension
        categoryFilterControl.anchor(
            top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 8,
            left: view.leadingAnchor, paddingLeft: 16,
            right: view.trailingAnchor, paddingRight: 16
        )
        
        collectionView.anchor(
            top: categoryFilterControl.bottomAnchor, paddingTop: 8,
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
        
        categoryFilterControl.addTarget(self, action: #selector(categoryFilterChanged), for: .valueChanged)
    }
    
    private func configureCollectionView() {
        collectionView.register(ClassifiedAdCell.self, forCellWithReuseIdentifier: ClassifiedAdCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
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
        categoryFilterControl.removeAllSegments()
        
        for (index, category) in viewModel.categories.enumerated() {
            categoryFilterControl.insertSegment(withTitle: category.name, at: index, animated: false)
        }
        
        if viewModel.categories.isNotEmpty {
            categoryFilterControl.selectedSegmentIndex = 0
        }
    }
    
    @objc private func categoryFilterChanged() {
        let selectedIndex = categoryFilterControl.selectedSegmentIndex
        guard selectedIndex >= 0 && selectedIndex < viewModel.categories.count else { return }
        
        let selectedCategory = viewModel.categories[selectedIndex]
        selectedCategoryId = selectedCategory.id
        
        viewModel.filterAds(by: selectedCategoryId)
    }
}

// MARK: - UICollectionViewDataSource
extension ClassifiedListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.filteredAds.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ClassifiedAdCell.reuseIdentifier, for: indexPath) as? ClassifiedAdCell else {
            return UICollectionViewCell()
        }
        
        let ad = viewModel.filteredAds[indexPath.item]
        let categoryName = viewModel.getCategoryName(for: ad.categoryId)
        
        cell.configure(with: ad, categoryName: categoryName, imageLoader: imageLoader)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ClassifiedListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let ad = viewModel.filteredAds[indexPath.item]
        let categoryName = viewModel.getCategoryName(for: ad.categoryId)
        
        let detailVC = ClassifiedDetailViewController(
            classifiedAd: ad,
            categoryName: categoryName,
            imageLoader: imageLoader
        )
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ClassifiedListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 32  // 16 points padding on each side
        return CGSize(width: width, height: 200)
    }
}

extension Collection {
    var isNotEmpty: Bool {
        return !isEmpty
    }
} 

import UIKit
import ClassifiedCoreKit

class CategoriesDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Properties
    private let viewModel: ClassifiedListViewModel
    weak var delegate: CategoriesDataSourceDelegate?
    
    // MARK: - Initialization
    init(viewModel: ClassifiedListViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.reuseIdentifier, for: indexPath) as? CategoryCell else {
            return UICollectionViewCell()
        }
        
        let category = viewModel.categories[indexPath.item]
        let showDot = indexPath.item < viewModel.categories.count - 1
        cell.configure(with: category, showDot: showDot)
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item >= 0 && indexPath.item < viewModel.categories.count else { return }
        
        let selectedCategory = viewModel.categories[indexPath.item]
        delegate?.categoriesDataSource(self, didSelectCategory: selectedCategory)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let category = viewModel.categories[indexPath.item]
        let font = UIFont.systemFont(ofSize: 16)
        
        let textWidth = category.name.size(withAttributes: [.font: font]).width
        let padding: CGFloat = 20.0
        let dotSpace: CGFloat = indexPath.item < viewModel.categories.count - 1 ? 16 : 0
        
        return CGSize(width: textWidth + dotSpace + padding, height: 44)
    }
}

// MARK: - Delegate Protocol
protocol CategoriesDataSourceDelegate: AnyObject {
    func categoriesDataSource(_ dataSource: CategoriesDataSource, didSelectCategory category: ClassifiedCoreKit.Category)
} 
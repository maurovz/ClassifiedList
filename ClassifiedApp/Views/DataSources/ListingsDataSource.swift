import UIKit
import ClassifiedCoreKit

class ListingsDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Properties
    private let viewModel: ClassifiedListViewModel
    private let imageLoader: ImageLoader
    weak var delegate: ListingsDataSourceDelegate?
    
    // MARK: - Initialization
    init(viewModel: ClassifiedListViewModel, imageLoader: ImageLoader) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init()
    }
    
    // MARK: - UICollectionViewDataSource
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
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        guard indexPath.item < viewModel.filteredAds.count else { return }
        
        let ad = viewModel.filteredAds[indexPath.item]
        let categoryName = viewModel.getCategoryName(for: ad.categoryId)
        
        guard let delegate = delegate else {
            print("Error: ListingsDataSource delegate is nil")
            return
        }
        
        delegate.listingsDataSource(self, didSelectAd: ad, withCategoryName: categoryName)
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 32
        return CGSize(width: width, height: 200)
    }
}

// MARK: - Delegate Protocol
protocol ListingsDataSourceDelegate: AnyObject {
    func listingsDataSource(_ dataSource: ListingsDataSource, didSelectAd ad: CoreClassifiedAd, withCategoryName categoryName: String)
} 

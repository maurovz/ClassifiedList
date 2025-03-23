import UIKit
import ClassifiedCoreKit

class DefaultClassifiedListCoordinator: ClassifiedListCoordinator {
    private weak var navigationController: UINavigationController?
    private let serviceFactory: ServiceFactory
    
    init(navigationController: UINavigationController, serviceFactory: ServiceFactory) {
        self.navigationController = navigationController
        self.serviceFactory = serviceFactory
    }
    
    func showDetail(for ad: CoreClassifiedAd, categoryName: String) {
        print("Coordinator: Showing detail for ad: \(ad.title)")
        
        let detailVC = serviceFactory.createClassifiedDetailViewController(
            classifiedAd: ad,
            categoryName: categoryName
        )
        navigationController?.pushViewController(detailVC, animated: true)
        
        if navigationController == nil {
            print("Error: navigationController is nil in coordinator")
        }
    }
} 
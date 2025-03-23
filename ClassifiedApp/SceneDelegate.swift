import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    // Store a strong reference to the coordinator
    var coordinator: ClassifiedListCoordinator?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        print("Setting up navigation in SceneDelegate")
        
        // Create navigation controller first
        let navigationController = UINavigationController()
        
        // Use the factory method that takes a navigation controller
        let factory = ServiceFactory.shared
        let coordinator = factory.createClassifiedListCoordinator(navigationController: navigationController)
        
        // Store a strong reference to the coordinator
        self.coordinator = coordinator
        
        // Create the view controller with the coordinator directly
        let repository = factory.createClassifiedRepository()
        let viewModel = ClassifiedListViewModel(repository: repository)
        let imageLoader = factory.createImageLoader()
        
        let viewController = ClassifiedListViewController(
            viewModel: viewModel,
            imageLoader: imageLoader, 
            coordinator: coordinator
        )
        
        // Set the root view controller
        navigationController.viewControllers = [viewController]
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}

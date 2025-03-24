import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var coordinator: ClassifiedListCoordinator?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        
        let navigationController = UINavigationController()
        
        let factory = ServiceFactory.shared
        let coordinator = factory.createClassifiedListCoordinator(navigationController: navigationController)
        
        self.coordinator = coordinator
        
        let repository = factory.createClassifiedRepository()
        let viewModel = ClassifiedListViewModel(repository: repository)
        let imageLoader = factory.createImageLoader()
        
        let viewController = ClassifiedListViewController(
            viewModel: viewModel,
            imageLoader: imageLoader, 
            coordinator: coordinator
        )
        
        navigationController.viewControllers = [viewController]
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}

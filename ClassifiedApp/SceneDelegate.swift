import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        let factory = ServiceFactory.shared
        let repository = factory.createClassifiedRepository()
        let imageLoader = factory.createImageLoader()
        
        let viewModel = ClassifiedListViewModel(repository: repository)
        let viewController = ClassifiedListViewController(viewModel: viewModel, imageLoader: imageLoader)
        let navigationController = UINavigationController(rootViewController: viewController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}

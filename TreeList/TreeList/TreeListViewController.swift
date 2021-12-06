import UIKit

protocol TreeListViewControllerDelegate: AnyObject {}

protocol TreeListViewControllerProtocol {
    var delegate: TreeListViewControllerDelegate? { get set }
}

class TreeListViewController: UIViewController, TreeListViewControllerProtocol {
    weak var delegate: TreeListViewControllerDelegate?

    private lazy var sortButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setImage(UIImage(systemName: "arrow.up.arrow.down"), for: .normal)
        button.accessibilityIdentifier = "sortButton"
        button.accessibilityLabel = NSLocalizedString("Sort", comment: "")
        if #available(iOS 14.0, *) {
            button.showsMenuAsPrimaryAction = true
        } else {
            button.addTarget(self, action: #selector(onSort(_:)), for: .touchUpInside)
        }
        return button
    }()
    
    private lazy var searchViewConntroller: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        searchController.searchBar.showsCancelButton = false
        searchController.searchBar.accessibilityIdentifier = "searchBar"
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("Search", comment: "")
        return searchController
    }()
    
    private lazy var treeTableViewController: UIViewController & TreeTableViewControllerProtocol = {
        let controller = TreeTableViewController()
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.delegate = self
        return controller
    }()
    
    private lazy var addGuestButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.accessibilityIdentifier = "addGuestButton"
        button.accessibilityLabel = NSLocalizedString("addGuest", comment: "")
        button.addTarget(self, action: #selector(onAddGuest(_:)), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        treeTableViewController.reload(groups: [ParticipantListGroup(displayName: "TestGroup", items:  [ParticipantListItem(displayName: "Test1", id: "1", childParticipants: [ParticipantListItem(displayName: "Test1.1", id: "1.1"),ParticipantListItem(displayName: "Test1.2", id: "1.2"),ParticipantListItem(displayName: "Test1.3", id: "1.3")]), ParticipantListItem(displayName: "Test2", id: "2"), ParticipantListItem(displayName: "Test3", id: "3")])])
        
        addChildViewController(treeTableViewController)
        addConstraints()
        view.backgroundColor = .white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationItem.title = "Tree List Demo"
        navigationItem.searchController = searchViewConntroller
        navigationItem.hidesSearchBarWhenScrolling = false
        super.viewWillAppear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    @objc func onSort(_ sender: UIButton) {}
    
    @objc func onAddGuest(_ sender: UIButton) {}
    
//    @available(iOS 14.0, *)
//    private func createMenu(items: [PopoverTableViewItemProtocol], title: String) -> UIMenu {
//        let actions = createMenuActions(items: items)
//        let uiActions: [UIAction] = actions.map({ menuAction in
//            var handler: (() -> Void)?
//            if case .action(let action) = menuAction.actionType {
//                handler = action
//            }
//            return
//            sceneContext.contextMenuFactory.makeAction(title: menuAction.title, image: menuAction.image, state: menuAction.isSelected ? .on : .off, handler: { _ in handler?() })
//        })
//        return UIMenu(title: title, image: MomentumIcon(.arrowDownOpticalRegular, config: UIImage.SymbolConfiguration(pointSize: 14)).template, children: uiActions)
//    }
//
//    private func createMenuActions(items: [PopoverTableViewItemProtocol]) -> [MenuAction] {
//        return items.map({ item in
//            return MenuAction(title: item.title,
//                              isDestructive: false,
//                              actionType: .action({ [weak self] in self?.didSelectMenuOption(item) }),
//                              isSelected: item.isSelected)
//        })
//    }
    
    private func addConstraints() {
        var customConstraints: [NSLayoutConstraint] = []
        customConstraints.append(treeTableViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
        customConstraints.append(treeTableViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor))
        customConstraints.append(treeTableViewController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        customConstraints.append(treeTableViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor))
        NSLayoutConstraint.activate(customConstraints)
    }
}

extension TreeListViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
    }
}

extension TreeListViewController: TreeTableViewControllerDelegate {
    func treeTableViewControllerDidInvite(_ controller: UIViewController & TreeTableViewControllerProtocol) {}
    
    func treeTableViewControllerDidSendMessgae(_ controller: UIViewController & TreeTableViewControllerProtocol, id: String) {}
    
    func treeTableViewControllerDidSelectItem(_ controller: UIViewController & TreeTableViewControllerProtocol, ids: [String], parentId: String, sourceView: UIView) {}
    
    func treeTableViewControllerDidScroll(_ controller: UIViewController & TreeTableViewControllerProtocol) {
        searchViewConntroller.searchBar.endEditing(true)
    }
}

// Use Case
class ParticipantListGroup: GenericGroupProtocol {
    var displayName: String
    var items: [GenericItemProtocol]
    var itemsAsRows: [TreeTableRow]
    
    init(displayName: String, items: [GenericItemProtocol]) {
        self.displayName = displayName
        self.items = items
        itemsAsRows = items.map({ TreeTableRow(item: $0) })
    }
}

class ParticipantListItem: GenericItemProtocol, Comparable {
    var id: String
    var displayName: String
    var subName: String = ""
    var childItems: [GenericItemProtocol] = []
    
    init (displayName: String, id: String) {
        self.displayName = displayName
        self.id = id
    }
    
    init (displayName: String, id: String, childParticipants: [GenericItemProtocol]) {
        self.displayName = displayName
        self.id = id
        self.childItems = childParticipants
    }
    
    func compareSmaller(with: GenericItemProtocol) -> Bool {
        displayName < with.displayName
    }
    
    static func == (lhs: ParticipantListItem, rhs: ParticipantListItem) -> Bool {
        lhs.displayName == rhs.displayName
    }
    
    static func < (lhs: ParticipantListItem, rhs: ParticipantListItem) -> Bool {
        lhs.displayName < rhs.displayName
    }
}

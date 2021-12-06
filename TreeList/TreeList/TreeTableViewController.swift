import UIKit

enum TreeListUpdateType {
    case add, remove, change
}

protocol TreeTableViewControllerProtocol: AnyObject {
    var delegate: TreeTableViewControllerDelegate? { get set }
    func handleChange(items: [GenericItemProtocol], parent: String, changeType: TreeListUpdateType, groupMatcher: GroupMatcher)
    func reload(groups: [GenericGroupProtocol])
}

protocol TreeTableViewControllerDelegate: AnyObject {
    func treeTableViewControllerDidInvite(_ controller: UIViewController & TreeTableViewControllerProtocol)
    func treeTableViewControllerDidSendMessgae(_ controller: UIViewController & TreeTableViewControllerProtocol, id: String)
    func treeTableViewControllerDidSelectItem(_ controller: UIViewController & TreeTableViewControllerProtocol, ids: [String], parentId: String, sourceView: UIView)
    func treeTableViewControllerDidScroll(_ controller: UIViewController & TreeTableViewControllerProtocol)
}

class TreeTableViewController: UIViewController, TreeTableViewControllerProtocol {
    private struct Constants {
        static let invitePadding: CGFloat = 28
        static let gapForToast: CGFloat = 112
        static let bottomBarHeight: CGFloat = 48
    }

    weak var delegate: TreeTableViewControllerDelegate?

    private var cellHeights = [IndexPath: CGFloat]()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.accessibilityIdentifier = "rosterTableView"
        tableView.allowsSelection = true
        tableView.separatorStyle = .none
        tableView.estimatedSectionHeaderHeight = 1 // to enable auto layout for headers
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TreeCell.self, forCellReuseIdentifier: "1")
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        return tableView
    }()
    
    private lazy var treeDataSource: TreeListDataSource = {
        let dataSource = TreeListDataSource()
        dataSource.delegate = self
        return dataSource
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        addConstraints()
        
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    func handleChange(items: [GenericItemProtocol], parent: String, changeType: TreeListUpdateType, groupMatcher: GroupMatcher) {
        switch changeType {
        case .add: treeDataSource.insert(items: items, parent: parent, groupMatcher: groupMatcher)
        case .remove: treeDataSource.remove(items: items, parent: parent, groupMatcher: groupMatcher)
        case .change: treeDataSource.update(items: items, parent: parent, groupMatcher: groupMatcher)
        }
    }
    
    func reload(groups: [GenericGroupProtocol]) {
        treeDataSource.reload(groups: groups)
    }
    
    private func addConstraints() {
        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
}

extension TreeTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return treeDataSource.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return treeDataSource.numberOfItems(inSection: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TreeCell = tableView.dequeueReusableCell(withIdentifier: "1", for: indexPath) as! TreeCell
        guard let model = treeDataSource.item(atIndex: indexPath.row, inSection: indexPath.section) else { return TreeCell() }
//        cell.delegate = self
        cell.configure(model: model)
        cell.layoutIfNeeded()
        return cell
    }
}

extension TreeTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let headerText = treeDataSource.sectionTitle(inSection: section), !headerText.isEmpty else {
            return 0
        }
        let defaultHeight = treeDataSource.section(atIndex: section)?.expand ?? true ? 0 : UITableView.automaticDimension
        return treeDataSource.numberOfItems(inSection: section) > 0 ? UITableView.automaticDimension : defaultHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = SectionHeaderView()
        guard let theSection = treeDataSource.section(atIndex: section), !theSection.title.isEmpty else { return nil }
        headerView.delegate = self
        headerView.configure(model: theSection, sectionIndex: section)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? TreeCell, let model = treeDataSource.item(atIndex: indexPath.row, inSection: indexPath.section) else { return }
        var ids = [model.originalItem.id]
        for item in model.originalItem.childItems {
            ids.append(item.id)
        }
        delegate?.treeTableViewControllerDidSelectItem(self, ids: ids, parentId: model.parentId ?? "", sourceView: cell)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.treeTableViewControllerDidScroll(self)
    }
}

extension TreeTableViewController: TreeListDataSourceDelegate {
    func treeDataSourceDidChange(_ dataSource: TreeListDataSourceProtocol) {
        tableView.reloadData()
    }
    
    func treeDataSource(_ dataSource: TreeListDataSourceProtocol, didChangeSections sections: IndexSet) {
        for section in sections {
            treeDataSource.section(atIndex: section)?.expand = true
        }
        tableView.reloadSections(sections, with: .automatic)
    }
    
    func treeDataSource(_ dataSource: TreeListDataSourceProtocol, didRemove removed: [IndexPath], didAdd added: [IndexPath], didChange changed: [IndexPath]) {
        tableView.performBatchUpdates({
            tableView.deleteRows(at: removed, with: .automatic)
            tableView.insertRows(at: added, with: .automatic)
        }, completion: nil)
        
        //without animation updates
        tableView.performBatchUpdates({
            UIView.performWithoutAnimation {
                tableView.reloadRows(at: changed, with: .none)
            }
        }, completion: nil)
    }
    
    func treeDataSource(_ dataSource: TreeListDataSourceProtocol, from: [IndexPath], to: [IndexPath]) {
        guard from.count == to.count else {
            tableView.reloadData()
            return
        }
        
        //When move mutilple lines, if the direction is up, move top lines first, if the direction is down, move bottom lines first.
        var from: [IndexPath] = from.reversed()
        var to: [IndexPath] = to
        if from[0] < to[0] {
            from.sort(by: >)
            to.sort(by: >)
        }
        
        for index in 0 ..< from.count {
            tableView.moveRow(at: from[index], to: to[index])
        }
        tableView.reloadRows(at: from, with: .none)
        tableView.reloadRows(at: to, with: .none)
    }
}

extension TreeTableViewController: SectionHeaderViewDelegate {
    func sectionHeaderViewDidPressHeader(_ rosterHeaderView: UITableViewHeaderFooterView, index: Int) {
        tableView.reloadSections([index], with: .automatic)
    }
}

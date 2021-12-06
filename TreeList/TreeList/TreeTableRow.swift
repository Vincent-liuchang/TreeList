import UIKit

protocol GenericGroupProtocol: Any {
    var displayName: String { get }
    var items: [GenericItemProtocol] { get }
    var itemsAsRows: [TreeTableRow] { get }
}

protocol GenericItemProtocol: Any {
    var displayName: String { get }
    var subName: String { get }
    var id: String { get }
    var childItems: [GenericItemProtocol] { get }
    //Compare Functions
    func compareSmaller(with: GenericItemProtocol) -> Bool
}

class TreeTableSection {
    var title: String
    var group: GenericGroupProtocol
    var items: [TreeTableRow]
    var expand = true
    
    init(group: GenericGroupProtocol, items: [TreeTableRow] = []) {
        self.title = group.displayName
        self.group = group
        self.items = items
    }
    
    func item(atIndex index: Int) -> TreeTableRow {
        return items[index]
    }
}

class TreeTableRow: Equatable, Comparable {
    let parentId: String?
    var children: [TreeTableRow]
    let originalItem: GenericItemProtocol
    let rowIdentifier: String
    
    var isChild: Bool {
        guard let parentId = parentId else { return false }
        return !parentId.isEmpty
    }
    
    init(parentId: String? = nil, item: GenericItemProtocol) {
        self.parentId = parentId
        self.originalItem = item
        rowIdentifier = parentId ?? item.id
        children = item.childItems.map { TreeTableRow(parentId: item.id, item: $0) }
    }
    
    //Orderable functions
    static func == (lhs: TreeTableRow, rhs: TreeTableRow) -> Bool {
        lhs.originalItem.id == rhs.originalItem.id && lhs.parentId == rhs.parentId
    }
    
    static func < (lhs: TreeTableRow, rhs: TreeTableRow) -> Bool {
        //Parent Always on top of childs
        if lhs.parentId == rhs.originalItem.id { return false }
        if lhs.originalItem.id == rhs.parentId { return true }
        return lhs.originalItem.compareSmaller(with: rhs.originalItem)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(originalItem.id)
    }
    
    // update functions
    func addToChildList(_ childItems: GenericItemProtocol) -> TreeTableRow {
        let childRow = TreeTableRow(parentId: originalItem.id, item: childItems)
        if !children.contains(childRow) {
            children.append(childRow)
        }
        children.sort(by: <)
        return self
    }
    
    func removeFromChildList(_ childItems: GenericItemProtocol) -> TreeTableRow {
        let childRow = TreeTableRow(parentId: originalItem.id, item: childItems)
        children.removeAll { row in row == childRow }
        return self
    }
}

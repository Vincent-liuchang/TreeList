import UIKit
import os
typealias GroupMatcher = (GenericGroupProtocol) -> Bool

protocol TreeListDataSourceProtocol: AnyObject {
    var delegate: TreeListDataSourceDelegate? { get set }
}

protocol TreeListDataSourceDelegate: AnyObject {
    func treeDataSourceDidChange(_ dataSource: TreeListDataSourceProtocol)
    func treeDataSource(_ dataSource: TreeListDataSourceProtocol, didChangeSections sections: IndexSet)
    func treeDataSource(_ dataSource: TreeListDataSourceProtocol, didRemove removed: [IndexPath], didAdd added: [IndexPath], didChange changed: [IndexPath])
    func treeDataSource(_ dataSource: TreeListDataSourceProtocol, from: [IndexPath], to: [IndexPath])
}

class TreeListDataSource: TreeListDataSourceProtocol {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "TreeList")
    weak var delegate: TreeListDataSourceDelegate?
    private var sections: [TreeTableSection] = []
    
    func reload(groups: [GenericGroupProtocol]) {
        sections = makeSections(groups: groups)
        delegate?.treeDataSourceDidChange(self)
    }
    
    private func makeSections(groups: [GenericGroupProtocol]) -> [TreeTableSection] {
        var sections: [TreeTableSection] = []
        groups.forEach { group in
            let section = TreeTableSection(group: group, items: serializeitemTableRowTree(group.itemsAsRows))
            sections.append(section)
        }
        return sections
    }
    
    private func serializeitemTableRowTree(_ rows: [TreeTableRow]) -> [TreeTableRow] {
        var serialized = [TreeTableRow]()
        for row in rows.sorted(by: <) {
            serialized.append(row)
            serialized.append(contentsOf: serializeitemTableRowTree(row.children))
        }
        return serialized
    }
    
//    func updateHeader(displayName: String, controlButton: CHButton, indicators: [LegacyCollabIconType], groupMatcher: GroupMatcher) {
//        guard case let (sectionIndex?, section?) = findSection(groupMatcher: groupMatcher) else { return }
//        section.title = displayName
//        section.button = controlButton
//        section.indicators = indicators
//        delegate?.itemDataSource(self, didChangeSections: [sectionIndex])
//    }
    
    func insert(items: [GenericItemProtocol], parent: String, groupMatcher: GroupMatcher) {
        let updateItems = handleChange(items, parent, groupMatcher, insert: true) { item, parentId, section, sectionIndex  in
            self.insert(item, parentId, into: section, sectionIndex: sectionIndex)
        }
        // for fold and expand section
        guard case let (sectionIndex?, section?) = findSection(groupMatcher: groupMatcher) else { return }
        if section.expand {
//            print("return results for tableView(insert): \(updateItems)")
            delegate?.treeDataSource(self, didRemove: updateItems.0, didAdd: updateItems.1, didChange: updateItems.2)
        } else {
//            print("return results for tableView(insert): \(sectionIndex)")
            delegate?.treeDataSource(self, didChangeSections: [sectionIndex])
        }
    }
    
    func remove(items: [GenericItemProtocol], parent: String, groupMatcher: GroupMatcher) {
        let updateItems = handleChange(items, parent, groupMatcher, insert: false) { item, parentId, section, sectionIndex in
            self.remove(item, parentId, from: section, sectionIndex: sectionIndex)
        }
        // for fold and expand section
        guard case let (sectionIndex?, section?) = findSection(groupMatcher: groupMatcher) else { return }
        if section.expand {
//            print("return results for tableView(remove): \(updateItems)")
            delegate?.treeDataSource(self, didRemove: updateItems.0, didAdd: updateItems.1, didChange: updateItems.2)
        } else {
//            print("return results for tableView(remove): \(sectionIndex)")
            delegate?.treeDataSource(self, didChangeSections: [sectionIndex])
        }
    }

    func update(items: [GenericItemProtocol], parent: String, groupMatcher: GroupMatcher) {
//        print("changes received, ListLength: \(items.count) parentId is empty \(parent.isEmpty)")
        let updateItems = handleChangesForUpdate(items, parent, groupMatcher) { item, parentId, section in
            self.update(item, parentId: parentId, from: section)
        }
        // for fold and expand section
        guard case let (sectionIndex?, section?) = findSection(groupMatcher: groupMatcher) else { return }
        if section.expand {
//            print("return results for tableView(update): \(updateItems)")
            if updateItems.3 {
                delegate?.treeDataSource(self, from: updateItems.0, to: updateItems.1)
            } else {
                delegate?.treeDataSource(self, didRemove: updateItems.0, didAdd: updateItems.1, didChange: updateItems.2)
            }
        } else {
//            print("return results for tableView(update): \(sectionIndex)")
            delegate?.treeDataSource(self, didChangeSections: [sectionIndex])
        }
    }
    
    private func insert(_ item: GenericItemProtocol, _ parentId: String?, into section: TreeTableSection, sectionIndex: Int) -> [IndexPath] {
        var results = [IndexPath]()
        guard (nil, nil) == findRow(item.id, parentId: parentId, in: section) else {
            return results
        }
        if case let (parentIndex?, parentRow?) = findParentRow(parentId: parentId, in: section) {
            // update parentRow data
            let updatedParentRow = parentRow.addToChildList(item)
            section.items[parentIndex] = updatedParentRow
            // update section data
            let childRow = TreeTableRow(parentId: parentId, item: item)
            var childIndex = parentIndex + 1
            while childIndex > parentIndex, childIndex <= parentIndex + parentRow.children.count - 1, childIndex < section.items.count, childRow > section.items[childIndex], section.items[childIndex].parentId == parentId {
                childIndex += (1 + section.items[childIndex].children.count)
            }
//            print("inserting child item with parentId: \(parentId?.isEmpty) at index \(childIndex) cildCountForParent \(parentRow.children.count)")
            section.items.insert(childRow, at: childIndex)
//            print("total number for datasource after insert: \(section.items.count)")
            results.append(IndexPath(row: childIndex, section: sectionIndex))
            for childRow in childRow.children.sorted(by: <) {
                results.append(contentsOf: insert(childRow.originalItem, item.id, into: section, sectionIndex: sectionIndex))
            }
        } else {
            let newitemRow = TreeTableRow(parentId: parentId, item: item)
            var index = 0
            while index >= 0, index < section.items.count, newitemRow > section.items[index] {
                index += (1 + section.items[index].children.count)
            }
//            print("inserting root level item without parentId at index \(index)")
            section.items.insert(newitemRow, at: index)
//            print("now count: \(section.items.count)")
            results.append(IndexPath(row: index, section: sectionIndex))
            for childRow in newitemRow.children.sorted(by: <) {
                results.append(contentsOf: insert(childRow.originalItem, item.id, into: section, sectionIndex: sectionIndex))
            }
        }
        return results
    }
    
    private func remove(_ item: GenericItemProtocol, _ parentId: String?, from section: TreeTableSection, sectionIndex: Int) -> [IndexPath] {
        var results = [IndexPath]()
        if case let (parentIndex?, parentRow?) = findParentRow(parentId: parentId, in: section) {
            // update parentRow data
            let updatedParentRow = parentRow.removeFromChildList(item)
            section.items[parentIndex] = updatedParentRow
        }
        // update section data, remove using local data, from bottom to top
        guard case let (index?, row?) = findRow(item.id, parentId: parentId, in: section) else {
            return results
        }
        for childRow in row.children.sorted(by: >) {
            results.append(contentsOf: remove(childRow.originalItem, item.id, from: section, sectionIndex: sectionIndex))
        }
//        print("removing item with parentId: \(parentId?.isEmpty ?? true) at index \(index)")
        section.items.remove(at: index)
        results.append(IndexPath(row: index, section: sectionIndex))
        return results
    }
    
    private func update(_ item: GenericItemProtocol, parentId: String?, from section: TreeTableSection) {
        guard case let (index?, _) = findRow(item.id, parentId: parentId, in: section) else { return }
        let updated = TreeTableRow(parentId: parentId, item: item)
//        print("replacing \(row) with \(updated) at index \(index)")
        section.items[index] = updated
    }
    
    private func handleChange(_ items: [GenericItemProtocol], _ parentId: String, _ groupMatcher: GroupMatcher, insert: Bool, action: @escaping (GenericItemProtocol, String?, TreeTableSection, Int) -> [IndexPath]) -> ([IndexPath], [IndexPath], [IndexPath]) {
        var changeIndexPaths = [IndexPath]()
        guard case let (sectionIndex?, section?) = findSection(groupMatcher: groupMatcher) else { return ([], [], []) }
//        print("handling change for '\(sectionIndex)' section. Total Sections count: \(sections.count)")
        for item in items {
            changeIndexPaths.append(contentsOf: action(item, parentId, section, sectionIndex))
        }
        if insert {
            return ([], changeIndexPaths, [])
        } else {
            return (changeIndexPaths, [], [])
        }
    }
    
    // return value (removeList, insertList, updateList, isPositionChangeUpdate)
    private func handleChangesForUpdate(_ items: [GenericItemProtocol], _ parentId: String, _ groupMatcher: GroupMatcher, action: @escaping (GenericItemProtocol, String?, TreeTableSection) -> Void) -> ([IndexPath], [IndexPath], [IndexPath], Bool) {
        var updatedIndexPaths = [IndexPath]()
        guard case let (sectionIndex?, section?) = findSection(groupMatcher: groupMatcher) else { return ([], [], updatedIndexPaths, false) }
        //Find out if Should Update Position
        let oldIndexPath = findIndexPath(for: items, parent: parentId, section: section, sectionIndex: sectionIndex)
        let newIndexPath = findInsertPostions(for: items, parent: parentId, section: section, sectionIndex: sectionIndex)
        
        if oldIndexPath == newIndexPath {
            updatedIndexPaths.append(contentsOf: oldIndexPath)
//            print("handling postion Not change update, for old:\(oldIndexPath) new:\(newIndexPath)")
            for item in items {
                action(item, parentId, section)
            }
            return ([], [], updatedIndexPaths, false)
        } else {
//            print("handling postion might change update, for old:\(oldIndexPath) new:\(newIndexPath)")
            var removeList: [IndexPath] = []
            var insertList: [IndexPath] = []
            for item in items {
                removeList.append(contentsOf: self.remove(item, parentId, from: section, sectionIndex: sectionIndex))
                insertList.append(contentsOf: self.insert(item, parentId, into: section, sectionIndex: sectionIndex))
            }
            if removeList == insertList {
                return ([], [], oldIndexPath, false)
            } else {
                return (removeList, insertList, [], true)
            }
        }
    }
    
    private func findIndexPath(for itemChangeList: [GenericItemProtocol], parent parentId: String, section: TreeTableSection, sectionIndex: Int) -> [IndexPath] {
        var updatedIndexPaths = [IndexPath]()
        for item in itemChangeList {
            let currentItem = findRow(item.id, parentId: parentId, in: section)
            guard let row = currentItem.0 else { continue }
            updatedIndexPaths.append(IndexPath(row: row, section: sectionIndex))
        }
        return updatedIndexPaths
    }

    private func findSection(groupMatcher: GroupMatcher) -> (Int?, TreeTableSection?) {
        let section = sections.first(where: { groupMatcher($0.group) })
        let index = sections.firstIndex { $0 === section }
        return (index, section)
    }
    
    private func findParentRow(parentId: String?, in section: TreeTableSection) -> (Int?, TreeTableRow?) {
        guard let parentId = parentId, !parentId.isEmpty,
              let match = section.items.enumerated().first(where: { $0.1.originalItem.id == parentId }) else {
                return (nil, nil)
        }
        return match
    }
    
    private func findRow(_ id: String?, parentId: String? = nil, in section: TreeTableSection) -> (Int?, TreeTableRow?) {
        guard let id = id, !id.isEmpty,
              let row = section.items.first(where: { $0.originalItem.id == id && ($0.parentId == parentId || $0.parentId == nil && parentId == nil) }) else {
            return (nil, nil)
        }
        return (section.items.firstIndex(of: row), row)
    }
    
    private func findInsertPostions(for itemChangeList: [GenericItemProtocol], parent parentId: String, section: TreeTableSection, sectionIndex: Int) -> [IndexPath] {
        var insertIndexPaths = [IndexPath]()
        for item in itemChangeList {
            if case let (parentIndex?, parentRow?) = findParentRow(parentId: parentId, in: section) {
                let newitemRow = TreeTableRow(parentId: parentId, item: item)
                var index = parentIndex + 1
                while index > parentIndex, index < section.items.count, index < parentIndex + parentRow.children.count, newitemRow > section.items[index] {
                    index += (1 + section.items[index].children.count)
                }
                insertIndexPaths.append(IndexPath(row: index, section: sectionIndex))
//                print("insert postion found for item: \((sectionIndex, index)) with parent \((sectionIndex, parentIndex))")
            } else {
                let newitemRow = TreeTableRow(parentId: parentId, item: item)
                var index = 0
                while index >= 0, index < section.items.count, newitemRow > section.items[index] {
                    index += (1 + section.items[index].children.count)
                }
                insertIndexPaths.append(IndexPath(row: index, section: sectionIndex))
//                print("insert postion found for item: \((sectionIndex, index))")
            }
        }
        return insertIndexPaths
    }
}

extension TreeListDataSource {
    var numberOfSections: Int {
        return sections.count
    }
    
    func numberOfItems(inSection section: Int) -> Int {
        guard section < numberOfSections else { return 0 }
        return sections[section].expand ?  sections[section].items.count : 0
    }
    
    func item(atIndex index: Int, inSection section: Int) -> TreeTableRow? {
        guard section < numberOfSections, index < numberOfItems(inSection: section) else { return nil }
        return sections[section].item(atIndex: index)
    }
    
    func items(inSection section: Int) -> [TreeTableRow] {
        guard section < numberOfSections else { return [] }
        return sections[section].items
    }
    
    func sectionTitle(inSection section: Int) -> String? {
        guard section < numberOfSections else { return nil }
        return sections[section].title
    }
    
    func section(atIndex index: Int) -> TreeTableSection? {
        guard index < numberOfSections else { return nil }
        return sections[index]
    }
}

//
//  SectionHeaderView.swift
//  TreeList
//
//  Created by ChangLiu on 2021/12/5.
//

import UIKit

protocol SectionHeaderViewDelegate: AnyObject {
    func sectionHeaderViewDidPressHeader(_ rosterHeaderView: UITableViewHeaderFooterView, index: Int)
}

class SectionHeaderView: UITableViewHeaderFooterView {
    weak var delegate: SectionHeaderViewDelegate?
    private var model: TreeTableSection?
    private var index: Int?
    
    private let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "rosterHeaderTitleLabel"
        label.textAlignment = .left
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    init() {
        super.init(reuseIdentifier: nil)
        contentView.addSubview(titleLabel)
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onHeaderPressed(_:))))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addConstraints() {
        var customConstraints: [NSLayoutConstraint] = []
        customConstraints.append(titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor))
        customConstraints.append(titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5))
        customConstraints.append(titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5))
        customConstraints.append(titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5))
        NSLayoutConstraint.activate(customConstraints)
    }
    
    func configure(model: TreeTableSection, sectionIndex: Int) {
        self.model = model
        self.index = sectionIndex
        titleLabel.text = model.title
    }
    
    @objc private func onHeaderPressed(_ sender: UITapGestureRecognizer) {
        model?.expand.toggle()
        guard let index = index else { return }
        delegate?.sectionHeaderViewDidPressHeader(self, index: index)
    }
}

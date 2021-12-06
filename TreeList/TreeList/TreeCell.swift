import UIKit

class TreeCell: UITableViewCell {
    private struct Constants {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 14
        static let avatarHeight: CGFloat = 20
        static let indicatorSize: CGFloat = 16
        static let buttonSize: CGFloat = 40
        static let subscriptSize: CGFloat = 8
    }
    
    private struct ControlState {
        var isMuted = false
        var isHardMuted = false
        var isSharing = false
        var isHandRaised = false
        var showAudioButton = false
        var isNoAudioConnected = false
        var isActiveSpeaker = false
    }
    
    private var currentState = ControlState()
    
    private var model: TreeTableRow?
    
    private lazy var contentLeadingConstraint = contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0)
    
    private lazy var avatar: UIImageView = {
       let avatar = UIImageView(image: UIImage(named: "defaultAvatar"))
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.layer.cornerRadius = Constants.avatarHeight / 2
        avatar.layer.masksToBounds = true
        avatar.sizeToFit()
        return avatar
    }()
    
    private lazy var noItemsLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "noItemsLabel"
        label.text = NSLocalizedString("No results found", comment: "")
        label.isHidden = true
        return label
    }()
    
    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [avatar, labelStack])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 16
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: Constants.verticalPadding, leading: Constants.horizontalPadding, bottom: Constants.verticalPadding, trailing: Constants.horizontalPadding)
        return stack
    }()
    
    private lazy var labelStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameStack])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .leading
        stack.distribution = .equalSpacing
        stack.setContentCompressionResistancePriority(.required, for: .vertical)
        stack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return stack
    }()
    
    private lazy var nameStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, userSpecifierLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.accessibilityIdentifier = "participantCellLabelStack"
        stack.axis = .horizontal
        stack.alignment = .leading
        stack.distribution = .fill
        stack.spacing = 8
        stack.setContentHuggingPriority(.required, for: .horizontal)
        stack.setContentCompressionResistancePriority(.required, for: .horizontal)
        return stack
    }()
    
    // First Line
    private let nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "nameLabel"
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    private let userSpecifierLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "userSpecifierLabel"
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()
    
    //Second Line
    private let descriptionLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityIdentifier = "descriptionLabel"
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        contentView.addSubview(noItemsLabel)
        contentView.addSubview(contentStack)
        addConstraints()
    }
    
    required init?(coder _: NSCoder) {
        fatalError("This subclass does not support NSCoding.")
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    private func addConstraints() {
        var customConstraints: [NSLayoutConstraint] = []
        customConstraints += [
            noItemsLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            noItemsLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentLeadingConstraint,
            avatar.widthAnchor.constraint(equalToConstant: Constants.avatarHeight),
            avatar.heightAnchor.constraint(equalToConstant: Constants.avatarHeight)
        ]
        NSLayoutConstraint.activate(customConstraints)
    }
    
    func configure(model: TreeTableRow) {
        self.model = model
        
        guard !model.originalItem.id.isEmpty else {
            contentStack.isHidden = true
            noItemsLabel.isHidden = false
            return
        }
        contentStack.isHidden = false
        noItemsLabel.isHidden = true
        
        //labels
        nameLabel.text = model.originalItem.displayName
        
        contentLeadingConstraint.constant = (model.isChild) ? Constants.avatarHeight * CGFloat(model.originalItem.layer) : 0
        
        applyTheme()
    }
    
    private func applyTheme() {
        backgroundColor = .tertiarySystemBackground
    }
}

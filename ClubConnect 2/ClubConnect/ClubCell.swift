import UIKit

final class ClubCell: UITableViewCell {
    static let reuseIdentifier = "ClubCell"

    @IBOutlet private weak var clubIconImageView: UIImageView!
    @IBOutlet private weak var clubNameLabel: UILabel!
    @IBOutlet private weak var categoryLabel: UILabel!

    func configure(with club: Club) {
        clubNameLabel.text = club.name ?? "Unnamed Club"
        categoryLabel.text = club.category ?? "General"
        clubIconImageView.image = UIImage(systemName: club.iconName ?? "person.3.fill")
            ?? UIImage(systemName: "person.3.fill")
        clubIconImageView.tintColor = .systemTeal
        clubIconImageView.isAccessibilityElement = false
        isAccessibilityElement = true
        accessibilityLabel = "\(clubNameLabel.text ?? "Club"), \(categoryLabel.text ?? "General")"
        accessibilityTraits = .button
    }
}

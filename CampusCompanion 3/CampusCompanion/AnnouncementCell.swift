import UIKit

class AnnouncementCell: UITableViewCell {
    @IBOutlet weak var categoryIconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var priorityLabel: UILabel!

    func configure(with announcement: CampusAnnouncement) {
        titleLabel.text = announcement.title
        dateLabel.text = "\(announcement.category) • \(announcement.date)"
        priorityLabel.text = announcement.priority

        if announcement.priority == "Urgent" {
            categoryIconImageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
            categoryIconImageView.tintColor = .systemRed
            priorityLabel.textColor = .systemRed
        } else {
            categoryIconImageView.image = UIImage(systemName: "megaphone.fill")
            categoryIconImageView.tintColor = .systemBlue
            priorityLabel.textColor = .secondaryLabel
        }
    }
}

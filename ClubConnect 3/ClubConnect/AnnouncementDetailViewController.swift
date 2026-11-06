import UIKit

final class AnnouncementDetailViewController: UIViewController {
    @IBOutlet private weak var announcementTitleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var categoryLabel: UILabel!
    @IBOutlet private weak var sourceLabel: UILabel!

    var announcementTitle = "Announcement"
    var dateText = ""
    var category = "General"
    var isRemote = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Announcement"
        announcementTitleLabel.text = announcementTitle
        dateLabel.text = dateText
        categoryLabel.text = category
        sourceLabel.text = isRemote ? "From the campus announcements feed" : "Saved on this device"
    }
}

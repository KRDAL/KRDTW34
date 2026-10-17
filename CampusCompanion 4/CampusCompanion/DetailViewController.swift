import UIKit

class DetailViewController: UIViewController {
    @IBOutlet weak var messageLabel: UILabel!

    var studentName: String = ""
    var notificationsEnabled: Bool = false
    var selectedRole: String = ""
    var preferredEventDate: Date = Date()
    var numberOfGuests: Int = 1
    var announcement: CampusAnnouncement?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let announcement = announcement {
            title = announcement.category
            messageLabel.text = "\(announcement.title)\n\nCategory: \(announcement.category)\nDate: \(announcement.date)\nPriority: \(announcement.priority)\nPosted By: \(announcement.postedBy)"
        } else {
            title = "Campus Events"
            let notificationStatus = notificationsEnabled ? "on" : "off"
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            let dateText = formatter.string(from: preferredEventDate)
            messageLabel.text = "Welcome, \(studentName)! (\(selectedRole))\nNotifications: \(notificationStatus).\nEvent: \(dateText)\nGuests: \(numberOfGuests)"
        }
    }
}

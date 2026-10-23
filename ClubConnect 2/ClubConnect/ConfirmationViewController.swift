import UIKit

final class ConfirmationViewController: UIViewController {
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var clubDetailsStackView: UIStackView!
    @IBOutlet private weak var clubIconImageView: UIImageView!
    @IBOutlet private weak var clubNameLabel: UILabel!
    @IBOutlet private weak var categoryLabel: UILabel!

    var studentName = "Club Member"
    var notificationsEnabled = true
    var role = "Member"
    var club: Club?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Confirmation"
        let reminders = notificationsEnabled ? "ON" : "OFF"
        messageLabel.text = "Thanks, \(studentName)! You've signed up as a \(role).\n\nMeeting reminders: \(reminders)"

        // Both entry routes share this controller; MP1 still works without a club.
        if let club = club {
            clubDetailsStackView.isHidden = false
            clubNameLabel.text = club.name ?? "Unnamed Club"
            categoryLabel.text = club.category ?? "General"
            clubIconImageView.image = UIImage(systemName: club.iconName ?? "person.3.fill")
                ?? UIImage(systemName: "person.3.fill")
        } else {
            clubDetailsStackView.isHidden = true
        }
    }
}

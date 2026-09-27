import UIKit

final class ConfirmationViewController: UIViewController {

    @IBOutlet private weak var messageLabel: UILabel!

    // Safe defaults keep the confirmation screen valid even before data is passed.
    var name: String = "Club Member"
    var wantsReminders: Bool = false
    var role: String = "Member"

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Confirmation"

        let reminderText = wantsReminders ? "ON" : "OFF"
        messageLabel.text = "Thanks, \(name)! You've signed up as a \(role). Meeting reminders: \(reminderText)."
    }
}

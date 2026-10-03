import UIKit

final class WelcomeViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var reminderSwitch: UISwitch!
    @IBOutlet private weak var roleSegmentedControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = "Campus Club Connect"
        navigationItem.title = "Campus Club Connect"
    }

    @IBAction private func joinButtonTapped(_ sender: UIButton) {
        nameTextField.resignFirstResponder()
        performSegue(withIdentifier: "ShowConfirmationSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowConfirmationSegue",
              let destination = segue.destination as? ConfirmationViewController else {
            return
        }

        let enteredName = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        destination.name = enteredName.isEmpty ? "Club Member" : enteredName
        destination.wantsReminders = reminderSwitch.isOn
        destination.role = roleSegmentedControl.selectedSegmentIndex == 0 ? "Member" : "Officer"
    }
}

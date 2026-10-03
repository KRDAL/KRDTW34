import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var campusImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var notifySwitch: UISwitch!
    @IBOutlet weak var roleSegmentedControl: UISegmentedControl!
    @IBOutlet weak var eventDatePicker: UIDatePicker!
    @IBOutlet weak var guestStepper: UIStepper!
    @IBOutlet weak var guestCountLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Campus Companion"
        titleLabel.text = "Campus Companion"
        campusImageView.image = UIImage(systemName: "graduationcap.fill")
        campusImageView.tintColor = .systemGreen
        guestStepper.minimumValue = 1
        guestStepper.maximumValue = 10
        guestStepper.stepValue = 1
        if guestStepper.value < 1 { guestStepper.value = 1 }
        updateGuestCount()
    }

    @IBAction func getStartedTapped(_ sender: UIButton) {
        subtitleLabel.text = "Let's get started!"
    }

    @IBAction func guestStepperChanged(_ sender: UIStepper) {
        updateGuestCount()
    }

    private func updateGuestCount() {
        guestCountLabel.text = "Guests: \(Int(guestStepper.value))"
    }

    @IBAction func exploreButtonTapped(_ sender: UIButton) {
        nameTextField.resignFirstResponder()
        performSegue(withIdentifier: "ShowDetailSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowDetailSegue",
              let destination = segue.destination as? DetailViewController else { return }

        let enteredName = nameTextField.text ?? ""
        destination.studentName = enteredName.isEmpty ? "Student" : enteredName
        destination.notificationsEnabled = notifySwitch.isOn
        destination.selectedRole = roleSegmentedControl.selectedSegmentIndex == 0 ? "Student" : "Faculty"
        destination.preferredEventDate = eventDatePicker.date
        destination.numberOfGuests = max(1, Int(guestStepper.value))
    }
}

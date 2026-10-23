import UIKit

final class WelcomeViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var remindersSwitch: UISwitch!
    @IBOutlet private weak var roleSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var joinButton: UIButton!
    @IBOutlet private weak var browseButton: UIButton!

    private enum DefaultsKey {
        static let studentName = "studentName"
        static let notificationsEnabled = "notificationsEnabled"
        static let selectedRoleIndex = "selectedRoleIndex"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "Campus Club Connect"
        title = "Welcome"
        nameTextField.delegate = self
        scrollView.keyboardDismissMode = .interactive
        configureButton(joinButton, filled: true)
        configureButton(browseButton, filled: false)
        restorePreferences()

        // Keep the form reachable on smaller phones while the keyboard is open.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureButton(_ button: UIButton?, filled: Bool) {
        guard let button = button else { return }
        var configuration = filled ? UIButton.Configuration.filled() : UIButton.Configuration.tinted()
        configuration.title = button.title(for: .normal)
        configuration.cornerStyle = .medium
        configuration.baseBackgroundColor = .systemTeal
        configuration.baseForegroundColor = filled ? .white : .label
        button.configuration = configuration
    }

    private func restorePreferences() {
        let defaults = UserDefaults.standard
        // Registered defaults fill missing keys without overwriting saved choices.
        defaults.register(defaults: [DefaultsKey.studentName: "",
                                     DefaultsKey.notificationsEnabled: true,
                                     DefaultsKey.selectedRoleIndex: 0])
        nameTextField.text = defaults.string(forKey: DefaultsKey.studentName) ?? ""
        remindersSwitch.isOn = defaults.bool(forKey: DefaultsKey.notificationsEnabled)
        let savedIndex = defaults.integer(forKey: DefaultsKey.selectedRoleIndex)
        roleSegmentedControl.selectedSegmentIndex = (0...1).contains(savedIndex) ? savedIndex : 0
    }

    @IBAction private func joinClubTapped(_ sender: UIButton) {
        nameTextField.resignFirstResponder()
        // Save before navigation so the next launch can restore this exact form.
        let defaults = UserDefaults.standard
        defaults.set(nameTextField.text ?? "", forKey: DefaultsKey.studentName)
        defaults.set(remindersSwitch.isOn, forKey: DefaultsKey.notificationsEnabled)
        defaults.set(roleSegmentedControl.selectedSegmentIndex, forKey: DefaultsKey.selectedRoleIndex)
        performSegue(withIdentifier: "ShowConfirmationSegue", sender: sender)
    }

    @IBAction private func browseClubsTapped(_ sender: UIButton) {
        nameTextField.resignFirstResponder()
        let defaults = UserDefaults.standard
        defaults.set(nameTextField.text ?? "", forKey: DefaultsKey.studentName)
        defaults.set(remindersSwitch.isOn, forKey: DefaultsKey.notificationsEnabled)
        defaults.set(roleSegmentedControl.selectedSegmentIndex, forKey: DefaultsKey.selectedRoleIndex)
        performSegue(withIdentifier: "ShowClubListSegue", sender: sender)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowClubListSegue" {
            guard let destination = segue.destination as? ClubListViewController else { return }
            let enteredName = (nameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            destination.studentName = enteredName.isEmpty ? "Club Member" : enteredName
            destination.notificationsEnabled = remindersSwitch.isOn
            destination.role = roleSegmentedControl.selectedSegmentIndex == 1 ? "Officer" : "Member"
            return
        }

        guard segue.identifier == "ShowConfirmationSegue",
              let destination = segue.destination as? ConfirmationViewController else { return }
        // UITextField.text is Optional; whitespace-only input also uses the fallback.
        let enteredName = (nameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        destination.studentName = enteredName.isEmpty ? "Club Member" : enteredName
        destination.notificationsEnabled = remindersSwitch.isOn
        destination.role = roleSegmentedControl.selectedSegmentIndex == 1 ? "Officer" : "Member"
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let window = view.window else { return }
        let frameInWindow = window.convert(value.cgRectValue, from: nil)
        let frameInView = view.convert(frameInWindow, from: window)
        let overlap = max(0, view.bounds.maxY - frameInView.minY - view.safeAreaInsets.bottom)
        scrollView.contentInset.bottom = overlap
        scrollView.verticalScrollIndicatorInsets.bottom = overlap
        if nameTextField.isFirstResponder {
            scrollView.scrollRectToVisible(nameTextField.convert(nameTextField.bounds, to: scrollView)
                .insetBy(dx: 0, dy: -16), animated: true)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
}

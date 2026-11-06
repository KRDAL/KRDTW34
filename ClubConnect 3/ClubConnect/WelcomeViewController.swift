import UIKit
import PhotosUI

final class WelcomeViewController: UIViewController, UITextFieldDelegate, PHPickerViewControllerDelegate {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var remindersSwitch: UISwitch!
    @IBOutlet private weak var roleSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var joinButton: UIButton!
    @IBOutlet private weak var browseButton: UIButton!
    @IBOutlet private weak var announcementsButton: UIButton!
    @IBOutlet private weak var profileImageView: UIImageView!
    @IBOutlet private weak var choosePhotoButton: UIButton!
    @IBOutlet private weak var campusMapButton: UIButton!

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
        configureButton(announcementsButton, filled: false)
        configureButton(choosePhotoButton, filled: false)
        configureButton(campusMapButton, filled: false)
        profileImageView.layer.cornerRadius = 16
        profileImageView.clipsToBounds = true
        if let savedPhoto = ProfilePhotoStore.load() {
            profileImageView.contentMode = .scaleAspectFill
            profileImageView.image = savedPhoto
        }
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

    @IBAction private func announcementsTapped(_ sender: UIButton) {
        nameTextField.resignFirstResponder()
        let defaults = UserDefaults.standard
        defaults.set(nameTextField.text ?? "", forKey: DefaultsKey.studentName)
        defaults.set(remindersSwitch.isOn, forKey: DefaultsKey.notificationsEnabled)
        defaults.set(roleSegmentedControl.selectedSegmentIndex, forKey: DefaultsKey.selectedRoleIndex)
        performSegue(withIdentifier: "ShowAnnouncementsSegue", sender: sender)
    }

    @IBAction private func campusMapTapped(_ sender: UIButton) {
        nameTextField.resignFirstResponder()
        let defaults = UserDefaults.standard
        defaults.set(nameTextField.text ?? "", forKey: DefaultsKey.studentName)
        defaults.set(remindersSwitch.isOn, forKey: DefaultsKey.notificationsEnabled)
        defaults.set(roleSegmentedControl.selectedSegmentIndex, forKey: DefaultsKey.selectedRoleIndex)
        performSegue(withIdentifier: "ShowCampusMapSegue", sender: sender)
    }

    @IBAction private func choosePhotoTapped(_ sender: UIButton) {
        nameTextField.resignFirstResponder()
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider else { return }
        guard provider.canLoadObject(ofClass: UIImage.self) else {
            showPhotoError("The selected item could not be opened as an image.")
            return
        }
        choosePhotoButton.isEnabled = false
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            do {
                if let error = error { throw error }
                guard let image = object as? UIImage else {
                    throw NSError(domain: "ClubConnect.Photo", code: 3,
                        userInfo: [NSLocalizedDescriptionKey: "The photo could not be loaded."])
                }
                // Save the file before showing success; ItemProvider completes off-main.
                let savedURL = try ProfilePhotoStore.save(image)
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.choosePhotoButton.isEnabled = true
                    self.profileImageView.contentMode = .scaleAspectFill
                    self.profileImageView.image = UIImage(contentsOfFile: savedURL.path) ?? image
                }
            } catch {
                DispatchQueue.main.async {
                    self?.choosePhotoButton.isEnabled = true
                    self?.showPhotoError("The photo was not saved. \(error.localizedDescription)")
                }
            }
        }
    }

    private func showPhotoError(_ message: String) {
        let alert = UIAlertController(title: "Profile Photo", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if let current = presentedViewController {
            current.dismiss(animated: true) { [weak self] in self?.present(alert, animated: true) }
        } else {
            present(alert, animated: true)
        }
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

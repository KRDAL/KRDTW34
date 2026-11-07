import UIKit
import PhotosUI

private enum ProfilePhoto {
    static let fileName = "profilePhoto.jpg"
    static let placeholderSymbol = "person.crop.circle"
}

private enum DefaultsKey {
    static let studentName = "studentName"
    static let notificationsEnabled = "notificationsEnabled"
    static let selectedRoleIndex = "selectedRoleIndex"
}

class ViewController: UIViewController, PHPickerViewControllerDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var campusImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var notifySwitch: UISwitch!
    @IBOutlet weak var roleSegmentedControl: UISegmentedControl!
    @IBOutlet weak var eventDatePicker: UIDatePicker!
    @IBOutlet weak var guestStepper: UIStepper!
    @IBOutlet weak var guestCountLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var removePhotoButton: UIButton!

    private var profilePhotoURL: URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(ProfilePhoto.fileName)
    }

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
        nameTextField.text = UserDefaults.standard.string(forKey: DefaultsKey.studentName) ?? ""
        notifySwitch.isOn = UserDefaults.standard.bool(forKey: DefaultsKey.notificationsEnabled)
        roleSegmentedControl.selectedSegmentIndex = UserDefaults.standard.integer(forKey: DefaultsKey.selectedRoleIndex)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(resetPreferencesTapped))
        configureProfileImageView()
        loadProfileImageFromDisk()
    }

    private func configureProfileImageView() {
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 50
        profileImageView.tintColor = .systemGray3
        removePhotoButton.setTitleColor(.systemRed, for: .normal)
        removePhotoButton.setTitleColor(.systemGray, for: .disabled)
    }

    @IBAction func changePhotoTapped(_ sender: UIButton) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            if let error = error {
                print("Could not load selected photo: \(error.localizedDescription)")
                return
            }
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.profileImageView.image = image
                self.saveProfileImageToDisk(image)
            }
        }
    }

    func saveProfileImageToDisk(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8),
              let fileURL = profilePhotoURL
        else { return }
        do {
            try data.write(to: fileURL)
        } catch {
            print("Could not save profile photo: \(error.localizedDescription)")
        }
        updateRemovePhotoButtonState()
    }

    func loadProfileImageFromDisk() {
        if let fileURL = profilePhotoURL,
           let image = UIImage(contentsOfFile: fileURL.path) {
            profileImageView.image = image
        } else {
            profileImageView.image = UIImage(systemName: ProfilePhoto.placeholderSymbol)
        }
        updateRemovePhotoButtonState()
    }

    @IBAction func removePhotoTapped(_ sender: UIButton) {
        guard let fileURL = profilePhotoURL else { return }
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Could not remove profile photo: \(error.localizedDescription)")
            return
        }
        profileImageView.image = UIImage(systemName: ProfilePhoto.placeholderSymbol)
        updateRemovePhotoButtonState()
    }

    private func updateRemovePhotoButtonState() {
        guard let fileURL = profilePhotoURL else {
            removePhotoButton.isEnabled = false
            return
        }
        removePhotoButton.isEnabled = FileManager.default.fileExists(atPath: fileURL.path)
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

    @objc private func resetPreferencesTapped() {
        UserDefaults.standard.removeObject(forKey: DefaultsKey.studentName)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.notificationsEnabled)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.selectedRoleIndex)
        nameTextField.text = ""
        notifySwitch.isOn = false
        roleSegmentedControl.selectedSegmentIndex = 0
    }

    @IBAction func exploreButtonTapped(_ sender: UIButton) {
        nameTextField.resignFirstResponder()
        let enteredName = nameTextField.text ?? ""
        UserDefaults.standard.set(enteredName, forKey: DefaultsKey.studentName)
        UserDefaults.standard.set(notifySwitch.isOn, forKey: DefaultsKey.notificationsEnabled)
        UserDefaults.standard.set(roleSegmentedControl.selectedSegmentIndex, forKey: DefaultsKey.selectedRoleIndex)
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

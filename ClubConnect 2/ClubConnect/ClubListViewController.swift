import UIKit
import CoreData

final class ClubListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet private weak var tableView: UITableView!

    var studentName = "Club Member"
    var notificationsEnabled = true
    var role = "Member"

    private var context: NSManagedObjectContext?
    private var clubs: [Club] = []
    private var selectedClub: Club?
    private var pendingError: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Clubs"
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        tableView.tableFooterView = UIView()

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            pendingError = "The app could not access its local database."
            navigationItem.rightBarButtonItem?.isEnabled = false
            return
        }
        if let error = appDelegate.persistentStoreError {
            pendingError = "The local database could not be opened. \(error.localizedDescription)"
            navigationItem.rightBarButtonItem?.isEnabled = false
            return
        }
        context = appDelegate.persistentContainer.viewContext
        loadClubs()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let message = pendingError {
            pendingError = nil
            showError(message)
        }
    }

    private func fetchClubs(in context: NSManagedObjectContext) throws -> [Club] {
        let request: NSFetchRequest<Club> = Club.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true,
                                                    selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        return try context.fetch(request)
    }

    private func loadClubs() {
        guard let context = context else { return }
        do {
            clubs = try fetchClubs(in: context)
            // Seeding an empty store prevents duplicate defaults on subsequent launches.
            if clubs.isEmpty {
                let seeds = [
                    ("Robotics Club", "STEM", "gearshape.2.fill"),
                    ("Photography Club", "Arts", "camera.fill"),
                    ("Debate Society", "Academic", "bubble.left.and.bubble.right.fill"),
                    ("Hiking Club", "Outdoors", "leaf.fill"),
                    ("Chess Club", "Games", "crown.fill")
                ]
                for (name, category, iconName) in seeds {
                    let club = Club(context: context)
                    club.name = name
                    club.category = category
                    club.iconName = iconName
                }
                try context.save()
                clubs = try fetchClubs(in: context)
            }
            tableView.reloadData()
        } catch {
            context.rollback()
            pendingError = "Unable to load the club directory. \(error.localizedDescription)"
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        clubs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ClubCell.reuseIdentifier, for: indexPath)
        if let clubCell = cell as? ClubCell {
            clubCell.configure(with: clubs[indexPath.row])
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedClub = clubs[indexPath.row]
        performSegue(withIdentifier: "ShowClubDetailSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowClubDetailSegue",
              let destination = segue.destination as? ConfirmationViewController,
              let selectedClub = selectedClub else { return }
        // Forward the welcome form along with the selected Core Data record.
        destination.studentName = studentName
        destination.notificationsEnabled = notificationsEnabled
        destination.role = role
        destination.club = selectedClub
    }

    @IBAction private func addClubTapped(_ sender: UIBarButtonItem) {
        guard context != nil else { return }
        let alert = UIAlertController(title: "Add Club", message: "Enter a club name and category.",
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Club name"
            textField.autocapitalizationType = .words
        }
        alert.addTextField { textField in
            textField.placeholder = "Category"
            textField.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self, weak alert] _ in
            let name = (alert?.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let category = (alert?.textFields?.last?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, !category.isEmpty else {
                self?.showError("Please enter both a club name and a category.")
                return
            }
            self?.insertClub(name: name, category: category)
        })
        present(alert, animated: true)
    }

    private func insertClub(name: String, category: String) {
        guard let context = context else { return }
        let club = Club(context: context)
        club.name = name
        club.category = category
        club.iconName = "person.3.fill"
        do {
            try context.save()
        } catch {
            // Discard the failed insert so an unsaved row cannot look persistent.
            context.rollback()
            showError("The club was not saved. \(error.localizedDescription)")
            return
        }
        do {
            clubs = try fetchClubs(in: context)
            tableView.reloadData()
        } catch {
            showError("The club was saved, but the list could not refresh. Reopen the directory.")
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "ClubConnect", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        // An Add action dismisses its alert before a validation error can be shown.
        if let presented = presentedViewController {
            presented.dismiss(animated: true) { [weak self] in
                self?.present(alert, animated: true)
            }
        } else {
            present(alert, animated: true)
        }
    }
}

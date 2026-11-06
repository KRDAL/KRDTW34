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
    private let service = ClubService()
    private var syncTask: URLSessionDataTask?
    private var isSyncing = false
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Clubs"
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        tableView.tableFooterView = UIView()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            disableDatabase("The local database is unavailable.")
            return
        }
        if let error = appDelegate.persistentStoreError {
            disableDatabase(error.localizedDescription)
            return
        }
        context = appDelegate.persistentContainer.viewContext
        do { try reloadSavedClubs() }
        catch { pendingError = "Saved clubs could not be loaded. \(error.localizedDescription)" }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let message = pendingError {
            pendingError = nil
            showError(message)
            return
        }
        guard !ClubFeedConfiguration.urlString.isEmpty else {
            navigationItem.prompt = "Set Club Source to enable online sync"
            return
        }
        syncClubs()
    }

    deinit { syncTask?.cancel() }

    private func disableDatabase(_ message: String) {
        pendingError = message
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = false }
        refreshControl.isEnabled = false
    }

    private func fetchClubs(in context: NSManagedObjectContext) throws -> [Club] {
        let request: NSFetchRequest<Club> = Club.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true,
            selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        return try context.fetch(request)
    }

    private func reloadSavedClubs() throws {
        guard let context = context else { return }
        clubs = try fetchClubs(in: context)
        tableView.reloadData()
        if clubs.isEmpty {
            let empty = UILabel()
            empty.numberOfLines = 0
            empty.textAlignment = .center
            empty.textColor = .secondaryLabel
            empty.text = "No clubs saved.\nSet Club Source, then tap Refresh."
            tableView.backgroundView = empty
        } else { tableView.backgroundView = nil }
    }

    @IBAction private func refreshClubsTapped(_ sender: UIBarButtonItem) {
        if ClubFeedConfiguration.urlString.isEmpty { configureFeedTapped(sender) }
        else { syncClubs() }
    }

    @objc private func pullToRefresh(_ sender: UIRefreshControl) {
        guard !ClubFeedConfiguration.urlString.isEmpty else {
            sender.endRefreshing()
            showError("Tap Club Source and enter the raw HTTPS URL of your published clubs.json.")
            return
        }
        syncClubs()
    }

    @IBAction private func configureFeedTapped(_ sender: UIBarButtonItem) {
        guard !isSyncing else { return }
        let alert = UIAlertController(title: "Club Source",
            message: "Paste the raw HTTPS URL of your published clubs.json. Each successful sync replaces the local club directory.", preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder = "Raw HTTPS JSON URL"
            $0.text = ClubFeedConfiguration.urlString
            $0.keyboardType = .URL
            $0.autocapitalizationType = .none
            $0.autocorrectionType = .no
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save & Sync", style: .default) { [weak self, weak alert] _ in
            guard ClubFeedConfiguration.save(alert?.textFields?.first?.text ?? "") else {
                self?.showError("Please enter a valid HTTPS URL without a username or password.")
                return
            }
            if let current = self?.presentedViewController {
                current.dismiss(animated: true) { self?.syncClubs() }
            } else { self?.syncClubs() }
        })
        present(alert, animated: true)
    }

    private func setSyncing(_ active: Bool) {
        isSyncing = active
        tableView.allowsSelection = !active
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = !active }
        if active { navigationItem.prompt = "Syncing clubs…" }
        else { refreshControl.endRefreshing() }
    }

    private func syncClubs() {
        guard context != nil, !isSyncing else { return }
        setSyncing(true)
        syncTask = service.fetchClubs(from: ClubFeedConfiguration.urlString) { [weak self] result in
            // UIKit and viewContext stay on main even when URLSession finishes elsewhere.
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.syncTask = nil
                self.setSyncing(false)
                switch result {
                case .failure(let error):
                    self.navigationItem.prompt = "Sync failed — showing saved clubs"
                    self.reportSyncError(error.localizedDescription)
                case .success(let records):
                    guard let context = self.context else { return }
                    do {
                        self.selectedClub = nil
                        // MP3 replaces every Club, including locally added records.
                        let existing: [Club] = try context.fetch(Club.fetchRequest())
                        for club in existing { context.delete(club) }
                        for record in records {
                            let club = Club(context: context)
                            club.name = record.name
                            club.category = record.category
                            club.iconName = record.iconName
                        }
                        try context.save()
                    } catch {
                        context.rollback()
                        self.navigationItem.prompt = "Sync could not be saved"
                        self.reportSyncError("Previous saved clubs were kept. \(error.localizedDescription)")
                        return
                    }
                    do {
                        try self.reloadSavedClubs()
                        self.navigationItem.prompt = "Synced \(records.count) clubs"
                    } catch {
                        self.reportSyncError("Clubs were saved. Reopen the directory to reload the list.")
                    }
                }
            }
        }
    }

    private func reportSyncError(_ message: String) {
        NSLog("Club sync failed: %@", message)
        if navigationController?.topViewController === self, presentedViewController == nil {
            showError(message)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { clubs.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ClubCell.reuseIdentifier, for: indexPath)
        (cell as? ClubCell)?.configure(with: clubs[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedClub = clubs[indexPath.row]
        performSegue(withIdentifier: "ShowClubDetailSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowClubDetailSegue",
              let destination = segue.destination as? ConfirmationViewController else { return }
        destination.studentName = studentName
        destination.notificationsEnabled = notificationsEnabled
        destination.role = role
        destination.club = selectedClub
    }

    @IBAction private func addClubTapped(_ sender: UIBarButtonItem) {
        guard let context = context, !isSyncing else { return }
        let alert = UIAlertController(title: "Add Club",
            message: "Enter a name and category. The next successful online sync replaces all local clubs.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Club name"; $0.autocapitalizationType = .words }
        alert.addTextField { $0.placeholder = "Category"; $0.autocapitalizationType = .words }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self, weak alert] _ in
            let name = (alert?.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let category = (alert?.textFields?.last?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, !category.isEmpty else {
                self?.showError("Please enter both a name and a category.")
                return
            }
            let club = Club(context: context)
            club.name = name
            club.category = category
            club.iconName = "person.3.fill"
            do { try context.save() }
            catch {
                context.rollback()
                self?.showError("The club was not saved. \(error.localizedDescription)")
                return
            }
            do { try self?.reloadSavedClubs() }
            catch { self?.showError("The club was saved. Reopen the list to reload it.") }
        })
        present(alert, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "ClubConnect", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if let current = presentedViewController {
            current.dismiss(animated: true) { [weak self] in self?.present(alert, animated: true) }
        } else { present(alert, animated: true) }
    }
}

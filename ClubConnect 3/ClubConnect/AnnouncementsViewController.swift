import UIKit
import CoreData

final class AnnouncementsViewController: UITableViewController {
    private enum RemoteEndpoint {
        static let announcements = URL(string:
            "https://raw.githubusercontent.com/vohn-dev/campus-companion-api/refs/heads/main/announcements.json")
    }

    private var announcements: [CampusAnnouncement] = []
    private var selectedAnnouncement: CampusAnnouncement?
    private var context: NSManagedObjectContext?
    private var refreshTask: URLSessionDataTask?
    private var hasRequestedRemoteData = false
    private var startupError: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Announcements"
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.tableFooterView = UIView()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            disableStorage(with: "The local database is unavailable.")
            return
        }
        if let error = appDelegate.persistentStoreError {
            disableStorage(with: error.localizedDescription)
            return
        }
        context = appDelegate.persistentContainer.viewContext
        do {
            try reloadSavedAnnouncements()
            navigationItem.prompt = "Showing saved announcements"
        } catch {
            startupError = "Saved announcements could not be loaded. \(error.localizedDescription)"
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let message = startupError {
            startupError = nil
            showMessage(message)
            return
        }
        if !hasRequestedRemoteData {
            hasRequestedRemoteData = true
            fetchRemoteAnnouncements()
        }
    }

    deinit {
        refreshTask?.cancel()
    }

    @IBAction private func refreshTapped(_ sender: UIBarButtonItem) {
        fetchRemoteAnnouncements()
    }

    @objc private func pullToRefresh(_ sender: UIRefreshControl) {
        fetchRemoteAnnouncements()
    }

    private func disableStorage(with message: String) {
        startupError = message
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = false }
        refreshControl?.isEnabled = false
        updateEmptyState(message: "The local database could not be opened.")
    }

    private func reloadSavedAnnouncements() throws {
        guard let context = context else { return }
        let request: NSFetchRequest<CampusAnnouncement> = CampusAnnouncement.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true,
            selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        announcements = try context.fetch(request)
        tableView.reloadData()
        updateEmptyState(message: "No saved announcements.\nTap Refresh to load the online feed, or + to add your own.")
    }

    private func updateEmptyState(message: String) {
        guard announcements.isEmpty else {
            tableView.backgroundView = nil
            return
        }
        let label = UILabel()
        label.text = message
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        let container = UIView()
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24)
        ])
        tableView.backgroundView = container
    }

    private func fetchRemoteAnnouncements() {
        guard context != nil else {
            refreshControl?.endRefreshing()
            return
        }
        guard refreshTask == nil else { return }
        guard let url = RemoteEndpoint.announcements else {
            refreshControl?.endRefreshing()
            showMessage("The announcements URL is invalid.")
            return
        }
        navigationItem.prompt = "Refreshing announcements…"
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        refreshTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            let result: Result<[RemoteAnnouncement], Error>
            do {
                if let error = error { throw error }
                guard let http = response as? HTTPURLResponse else {
                    throw Self.responseError("The server did not return an HTTP response.")
                }
                guard (200...299).contains(http.statusCode) else {
                    throw Self.responseError("The announcements server returned HTTP \(http.statusCode).")
                }
                guard let data = data else {
                    throw Self.responseError("The announcements response was empty.")
                }
                let records = try JSONDecoder().decode([RemoteAnnouncement].self, from: data).map { $0.normalized }
                guard records.allSatisfy({ $0.isValid }) else {
                    throw Self.responseError("Every announcement must contain a title, date and category.")
                }
                result = .success(records)
            } catch {
                result = .failure(error)
            }

            // URLSession finishes on a background queue. UIKit and viewContext stay on main.
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.refreshTask = nil
                self.refreshControl?.endRefreshing()
                switch result {
                case .success(let records):
                    do {
                        try self.saveRemoteAnnouncements(records)
                    } catch {
                        self.context?.rollback()
                        self.reportRefreshFailure("The new feed could not be saved. \(error.localizedDescription)")
                        return
                    }
                    do {
                        try self.reloadSavedAnnouncements()
                        self.navigationItem.prompt = "Announcements updated"
                    } catch {
                        self.reportRefreshFailure("The feed was saved, but the list could not be loaded. Reopen Announcements.")
                    }
                case .failure(let error):
                    self.reportRefreshFailure(error.localizedDescription)
                }
            }
        }
        refreshTask?.resume()
    }

    private static func responseError(_ message: String) -> NSError {
        NSError(domain: "ClubConnect.Announcements", code: 1,
                userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func saveRemoteAnnouncements(_ records: [RemoteAnnouncement]) throws {
        guard let context = context else { throw Self.responseError("The database is unavailable.") }
        let request: NSFetchRequest<CampusAnnouncement> = CampusAnnouncement.fetchRequest()
        request.predicate = NSPredicate(format: "isRemote == YES")
        let previous = try context.fetch(request)
        var existingByKey: [String: CampusAnnouncement] = [:]
        for item in previous {
            if let key = item.remoteKey, existingByKey[key] == nil {
                existingByKey[key] = item
            } else {
                context.delete(item)
            }
        }
        var receivedKeys = Set<String>()
        for record in records {
            let key = try record.cacheKey()
            guard receivedKeys.insert(key).inserted else { continue }
            let item = existingByKey[key] ?? CampusAnnouncement(context: context)
            item.title = record.title
            item.date = record.date
            item.category = record.category
            item.isRemote = true
            item.remoteKey = key
        }
        // Refresh replaces the remote snapshot; locally added announcements are preserved.
        for item in previous where !item.isDeleted && !receivedKeys.contains(item.remoteKey ?? "") {
            context.delete(item)
        }
        if context.hasChanges { try context.save() }
    }

    private func reportRefreshFailure(_ message: String) {
        navigationItem.prompt = announcements.isEmpty ? "Refresh failed — try again" : "Refresh failed — showing saved data"
        updateEmptyState(message: "The online feed could not be loaded.\nCheck your connection and tap Refresh to retry.")
        // Do not interrupt an Add dialog or present an alert over the detail screen.
        if viewIfLoaded?.window != nil, navigationController?.topViewController === self,
           presentedViewController == nil {
            showMessage("\(message)\n\nAny previously saved announcements remain available.")
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        announcements.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AnnouncementCell", for: indexPath)
        let announcement = announcements[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = announcement.title ?? "Untitled announcement"
        content.secondaryText = "\(announcement.date ?? "") • \(announcement.category ?? "General")"
        content.image = UIImage(systemName: "megaphone.fill")
        content.imageProperties.tintColor = .systemTeal
        content.textProperties.numberOfLines = 0
        content.secondaryTextProperties.numberOfLines = 0
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedAnnouncement = announcements[indexPath.row]
        performSegue(withIdentifier: "ShowAnnouncementDetailSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowAnnouncementDetailSegue",
              let destination = segue.destination as? AnnouncementDetailViewController,
              let selected = selectedAnnouncement else { return }
        // Pass values so a later refresh cannot invalidate a displayed Core Data object.
        destination.announcementTitle = selected.title ?? "Untitled announcement"
        destination.dateText = selected.date ?? ""
        destination.category = selected.category ?? "General"
        destination.isRemote = selected.isRemote
    }

    @IBAction private func addAnnouncementTapped(_ sender: UIBarButtonItem) {
        guard let context = context else { return }
        let alert = UIAlertController(title: "Add Announcement", message: "Enter a title and category. This entry is saved on your device.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Title"; $0.autocapitalizationType = .sentences }
        alert.addTextField { $0.placeholder = "Category"; $0.autocapitalizationType = .words }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self, weak alert] _ in
            guard let self = self else { return }
            let title = (alert?.textFields?.first?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let category = (alert?.textFields?.last?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty, !category.isEmpty else {
                self.showMessage("Please enter both a title and a category.")
                return
            }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "MMMM d, yyyy"
            let item = CampusAnnouncement(context: context)
            item.title = title
            item.category = category
            item.date = formatter.string(from: Date())
            item.isRemote = false
            do {
                try context.save()
            } catch {
                context.rollback()
                self.showMessage("The announcement was not saved. \(error.localizedDescription)")
                return
            }
            do {
                try self.reloadSavedAnnouncements()
            } catch {
                self.showMessage("The announcement was saved. Reopen this screen to reload the list.")
            }
        })
        present(alert, animated: true)
    }

    private func showMessage(_ message: String) {
        let alert = UIAlertController(title: "Announcements", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if let current = presentedViewController {
            current.dismiss(animated: true) { [weak self] in self?.present(alert, animated: true) }
        } else {
            present(alert, animated: true)
        }
    }
}

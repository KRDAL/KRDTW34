import UIKit
import CoreData

private enum RemoteEndpoint {
    static let announcements =
        URL(string: "https://raw.githubusercontent.com/vohn-dev/" +
            "campus-companion-api/refs/heads/main/announcements.json")!
}

class AnnouncementsViewController: UITableViewController {
    private var announcements: [CampusAnnouncement] = []
    private var selectedAnnouncement: CampusAnnouncement?

    private var context: NSManagedObjectContext {
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Campus Announcements"
        tableView.rowHeight = 84
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addAnnouncementTapped))
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTapped(_:)))
        navigationItem.rightBarButtonItems = [addButton, refreshButton]
        seedInitialAnnouncementsIfNeeded()
        loadAnnouncements()
    }

    @objc private func refreshTapped(_ sender: UIBarButtonItem) {
        fetchAnnouncementsFromServer()
    }

    private func fetchAnnouncementsFromServer() {
        let task = URLSession.shared.dataTask(
            with: RemoteEndpoint.announcements
        ) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("Network error: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Unexpected server response.")
                return
            }

            guard let data = data else { return }
            print("Reached network handler with \(data.count) bytes.")
            if let rawJSON = String(data: data, encoding: .utf8) {
                print(rawJSON)
            }

            do {
                let decoder = JSONDecoder()
                let decodedAnnouncements = try decoder.decode([AnnouncementDTO].self, from: data)
                DispatchQueue.main.async {
                    self.replaceAnnouncements(with: decodedAnnouncements)
                    self.showNetworkConfirmationAlert(byteCount: data.count)
                }
            } catch {
                print("Decoding error: \(error)")
            }
        }
        task.resume()
    }

    private func replaceAnnouncements(with dtos: [AnnouncementDTO]) {
        let deleteRequest: NSFetchRequest<CampusAnnouncement> = CampusAnnouncement.fetchRequest()
        let existing = (try? context.fetch(deleteRequest)) ?? []
        for item in existing { context.delete(item) }
        for dto in dtos {
            let announcement = CampusAnnouncement(context: context)
            announcement.title = dto.title
            announcement.date = dto.date
            announcement.category = dto.category
            announcement.location = dto.location ?? "TBA"
            announcement.priority = dto.priority ?? "Normal"
            announcement.postedBy = dto.category
        }
        try? context.save()
        loadAnnouncements()
        tableView.reloadData()
    }

    private func showNetworkConfirmationAlert(byteCount: Int) {
        let alert = UIAlertController(
            title: "Server Reached",
            message: "Received \(byteCount) bytes from the " +
                "announcements endpoint.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func seedInitialAnnouncementsIfNeeded() {
        let request: NSFetchRequest<CampusAnnouncement> = CampusAnnouncement.fetchRequest()
        let existingCount = (try? context.count(for: request)) ?? 0
        guard existingCount == 0 else { return }
        let seeds = [
            ("Enrollment Period Extended", "August 3, 2026", "Registrar", "Urgent", "Registrar", "Registrar Office"),
            ("Library Hours Extended for Finals", "August 5, 2026", "Library", "Normal", "University Library", "Main Library"),
            ("Career Fair 2026", "August 7, 2026", "Career Center", "Normal", "Career Center", "Gymnasium"),
            ("Student Council Elections", "August 10, 2026", "Student Affairs", "Urgent", "Student Affairs", "SC Office"),
            ("Campus Wi-Fi Maintenance Notice", "August 12, 2026", "IT Services", "Urgent", "IT Services", "All Buildings"),
            ("Intramural Sports Sign-Up", "August 14, 2026", "Athletics", "Normal", "Athletics Office", "Covered Court")
        ]
        for seed in seeds {
            let item = CampusAnnouncement(context: context)
            item.title = seed.0
            item.date = seed.1
            item.category = seed.2
            item.priority = seed.3
            item.postedBy = seed.4
            item.location = seed.5
        }
        try? context.save()
    }

    private func loadAnnouncements() {
        let request: NSFetchRequest<CampusAnnouncement> = CampusAnnouncement.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        announcements = (try? context.fetch(request)) ?? []
        tableView.reloadData()
    }

    @objc private func addAnnouncementTapped() {
        let alert = UIAlertController(title: "New Announcement", message: "Enter a title and category.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Title" }
        alert.addTextField { $0.placeholder = "Category" }
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let titleText = alert?.textFields?[0].text, !titleText.isEmpty,
                  let categoryText = alert?.textFields?[1].text, !categoryText.isEmpty else { return }
            let item = CampusAnnouncement(context: self.context)
            item.title = titleText
            item.date = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
            item.category = categoryText
            item.priority = "Normal"
            item.postedBy = categoryText
            item.location = "TBA"
            try? self.context.save()
            self.loadAnnouncements()
        }
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        announcements.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AnnouncementCell", for: indexPath) as? AnnouncementCell else {
            return UITableViewCell()
        }
        cell.configure(with: announcements[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedAnnouncement = announcements[indexPath.row]
        performSegue(withIdentifier: "ShowAnnouncementDetailSegue", sender: self)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let item = announcements[indexPath.row]
        context.delete(item)
        try? context.save()
        announcements.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowAnnouncementDetailSegue",
              let destination = segue.destination as? DetailViewController,
              let announcement = selectedAnnouncement else { return }
        destination.announcement = announcement
    }
}

# Run and screenshot checklist

These steps are **not yet executed**. Capture genuine screenshots from your Mac after checking the app. Use the same Simulator for persistence tests; another Simulator has its own data.

| Step | Action | Expected result / evidence |
| --- | --- | --- |
| 1 | Open the project, select an installed iPhone Simulator and press Command-R | App builds and Welcome appears |
| 2 | Enter `KRD`, turn reminders ON, select Officer | Welcome shows all three values; capture `MP1_Welcome.png` |
| 3 | Tap Join the Club | Keyboard closes; Confirmation includes KRD, Officer and ON; capture `MP1_Confirmation.png` |
| 4 | Tap Back; empty the name; turn reminders OFF and select Member; join | Confirmation uses Club Member, Member and OFF; no crash |
| 5 | Repeat step 4 with spaces in the name field | Same safe fallback; no crash |
| 6 | Run on a small phone such as iPhone SE (3rd generation), then a large phone such as iPhone 15 Pro Max, or equivalent installed sizes | No overlap or horizontal clipping. The form scrolls on smaller phones. Capture both device sizes for MP1. |
| 7 | Return to the primary Simulator, enter KRD / ON / Officer and tap Browse Clubs | Directory opens with five clubs, each with an icon, name and category; capture `MP2_Club_List.png` |
| 8 | Tap Robotics Club | Row deselects; Confirmation shows the MP1 summary plus Robotics Club / STEM; capture `MP2_Club_Detail.png` |
| 9 | Use the Back buttons | Returns first to Clubs, then Welcome |
| 10 | Terminate the app and relaunch it without uninstalling it | KRD / ON / Officer remain; capture `MP2_Preferences_After_Relaunch.png` |
| 11 | Browse Clubs, tap +, enter `Coding Circle` and `Technology`, then Add | New row appears alphabetically |
| 12 | Terminate and relaunch; Browse Clubs again | Coding Circle still appears and starter clubs are not duplicated; capture `MP2_Added_Club_After_Relaunch.png` |
| 13 | Try adding an empty name or category | A helpful alert appears; no blank record is inserted |
| 14 | Tap Cancel in Add Club | No record is inserted |
| 15 | Tap Coding Circle | Its details appear with the current registration summary |

To terminate and relaunch: stop the running app in Xcode, then run it again, or swipe it away in the Simulator app switcher and reopen its icon. Do not uninstall or erase content. Press Return/Done on the keyboard if you want to dismiss it before taking a Welcome screenshot.

Save screenshots using the Simulator's screenshot command (commonly Command-S), or the macOS screenshot controls. The exact Simulator menus can vary. Put the resulting images alongside the zipped project when submitting, or follow your LMS's upload arrangement.

Submission needs the project ZIP including its Git history, the screenshots for both modules, and the two short reflections. A build log does not replace screenshot evidence or the two-size layout check.

### Description
    A script to approve BUCS
    The script accepts BUCS IDs as an argument. Each ID should be on new line
    It can be used in combination with "External application button" extension for Chrome/Firefox/Opera
    The extension allows to add a browser context menu item that sends selected text with IDs as an argument to this script.

### Usage example
    apply_batch.rb --reporter "Doe, John" ["b9256f4d-fd3e-48a6-adf3-b1bd008fe395"]

# Approve batch workflow
    [8] [main] calls [process_batch] on each Id
        [7] [process_batch] calls [get_batch] on Id to check current status for the batch
            [5] [get_batch] returns {batch_status}, {batch_start_date} to [process_batch]
        [7] [process_batch] calls [approve_or_apply_batch] on Id
            [4] [approve_or_apply_batch] approves batch and returns to [process_batch]
        [7] [process_batch] calls [get_batch] on Id to check new status for the batch
            [5] [get_batch] returns {new_batch_status} to [process_batch]
        [7] [process_batch] calls [messenger] on id to print batch status message
            [6] [messenger] prints status message and returns to [process_batch]

# History
    Version 1.0 - initial release
    Version 1.1 - added multiple batch Id handling
    Version 1.2 - code refactoring
    Version 1.3 - code refactoring
    Version 1.4 - code refactoring

---
The button below opens this repo in VS Code online:  
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=764631534&skip_quickstart=true)
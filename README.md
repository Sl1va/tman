Tool to utilize workflow in embedded development

Status: Active development


Config repo:
File `repos` contain list of repos that might be possibly used at work. The file
structure is shown below. Values are set in CSV.

```
repo_name,default_branch,repo_path

Example:
myutil,master,
```

repo_name - name of the repo
default_branch - branch to branch from and merge back to.
repo_path - if repo's nested specify its path here, otherwise leave it emtpy,
            default will be used.



Basic structure:
Tman structure:
Main:
    1. TaskID
    2. TaskUnit
    3. Config
    4. Git
    5. Struct
Aux:
    1. Log
    2. Debug


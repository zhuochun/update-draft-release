# Update Draft Release

Add your latest commit message to your GitHub repository's draft release.

## Setup

Install this gem by clone this repo. Run `bundle install & rake install` in it.

Create `~/.netrc` file with your GitHub login/password:

```
machine api.github.com
  login your_login_id
  password your_password_or_token
```

## Usage

```
$ update-draft-release your/repo

INFO: Logged in as: zhuochun
INFO: Repository used: your/repo
INFO: Prepare to insert line: New commit e4d5c0bf29055187d13e5e83c909
##################################################
Draft
==================================================
Old commit 11124f700882108e69ecdcf04074

New commit e4d5c0bf29055187d13e5e83c909
##################################################
Ok? (Y/N): y
INFO: Updating to URL: https://www.github.com/your/repo/draft
INFO: Release 'Draft' updated!
```

### Options

- `--at-top-level`: Insert into top level.
- `--at-the-end`: Insert at the end.
- `--in-secton_name`: Insert into the section with heading 'Section Name'. E.g. `--in-gamma`.
- `--create-section`: Create a new section if not exists, used with `--in-secton_name`.
- `--open-url`: Open the release URL after update succeed.
- `--can-can`: Skip the final confirmation.
- `--i-am-kiasu`: Make sure the final confirmation is not skipped.

## More

Run `gem uninstall update-draft-release` to uninstall.

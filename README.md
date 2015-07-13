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
#
# I, [2015-06-26T23:40:00.954754 #15147]  INFO -- : Logged in as: zhuochun
# I, [2015-06-26T23:40:00.954814 #15147]  INFO -- : Repository used: your/repo
# I, [2015-06-26T23:40:02.282133 #15147]  INFO -- : Prepare to insert line: bla bla ddf3e5aa3505e4d5c0bf29055187d13e5e83c909
# …
#
```

## Options

`--in-top-level`: Insert into top level.

`--in-xxx`: Insert into the section named 'xxx'. E.g. `in-gamma`.

`--at-the-end`: Insert at the end.

`--create-heading`: Create a new heading if the section specified by `--in-xxx` is not found.

`--skip-confirmation`: Skip the confirmation. :trollface:

`--open-url`: Open the url of the release.

## More

Run `gem uninstall update-draft-release` to uninstall.

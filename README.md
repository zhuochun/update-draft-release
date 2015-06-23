# Update Draft Release

Add your latest commit message to your GitHub repository's draft release.

## Setup

Clone repo, run `rake install` in it to install gem.

Create `~/.netrc` file with your GitHub login/password:

```
machine api.github.com
  login your_login_id
  password your_password_or_token
```

## Usage

```
$ update_draft_release your/repo
#
# I, [2015-06-26T23:40:00.954754 #15147]  INFO -- : Logged in as: zhuochun
# I, [2015-06-26T23:40:00.954814 #15147]  INFO -- : Repository used: your/repo
# I, [2015-06-26T23:40:02.282133 #15147]  INFO -- : Prepare to insert line: bla bla ddf3e5aa3505e4d5c0bf29055187d13e5e83c909
# …
#
```

## More

Run `gem uninstall update_draft_release` to uninstall.
